import '../data/models/enums.dart';

class HealthConstants {
  static const int calorieFloorMale = 1500;
  static const int calorieFloorFemale = 1200;
  static const int calorieFloorOther = 1300;

  // Max pacing for weight change as fraction of bodyweight per week.
  static const double maxWeightChangeFraction = 0.0075; // 0.75%/wk

  // 1 kg of fat ≈ 7700 kcal.
  static const double kcalPerKgBodyMass = 7700;

  // Daily upper limit for sodium per FDA. Shown as a "stay under" track.
  static const int sodiumDailyLimitMg = 2300;
}

class ComputedTargets {
  final double bmr;
  final double tdee;
  final int calorieTarget;
  // Rest-day target (lower because no gym/cardio burn). Equal to
  // calorieTarget when the user has no rest days configured.
  final int restDayCalorieTarget;
  final int proteinG;
  final int carbG;
  final int fatG;
  final int fiberG;
  final int waterMl;
  final double bmi;
  final bool usedKatchMcArdle;
  final bool warnConsultProfessional;

  const ComputedTargets({
    required this.bmr,
    required this.tdee,
    required this.calorieTarget,
    required this.restDayCalorieTarget,
    required this.proteinG,
    required this.carbG,
    required this.fatG,
    required this.fiberG,
    required this.waterMl,
    required this.bmi,
    required this.usedKatchMcArdle,
    required this.warnConsultProfessional,
  });
}

/// Average calorie burn for a moderate-intensity cardio session
/// (~45 min running / cycling). Used when only session count is known.
const double _kcalPerCardioSession = 350;

/// km-based burn rates. Tuned for an average 70 kg adult at moderate
/// pace. Scales with bodyweight inside the math below.
const double _kcalPerKmWalkingPer70kg = 50;
const double _kcalPerKmRunningPer70kg = 70;

/// Extra calorie cost per minute of heavy resistance training, beyond
/// the baseline session burn.
const double _kcalPerGymMinutePer70kg = 6.5;

class HealthMath {
  /// Mifflin-St Jeor BMR — solid default when body-fat % is unknown.
  static double bmr({
    required Gender gender,
    required int age,
    required double weightKg,
    required double heightCm,
  }) {
    final base = 10 * weightKg + 6.25 * heightCm - 5 * age;
    switch (gender) {
      case Gender.male:
        return base + 5;
      case Gender.female:
        return base - 161;
      case Gender.other:
        return base - 78;
    }
  }

  /// Katch-McArdle BMR — uses lean body mass directly, so it stays
  /// accurate for lean / very muscular users (and avoids the
  /// Mifflin overestimate for obese users).
  ///   BMR = 370 + 21.6 × LBM(kg);  LBM = weight × (1 - BF/100)
  static double bmrKatchMcArdle(double weightKg, double bodyFatPct) {
    final lbm = weightKg * (1 - bodyFatPct.clamp(0, 70) / 100.0);
    return 370 + 21.6 * lbm;
  }

  /// Chooses Katch-McArdle when [bodyFatPct] looks reasonable (3-60%);
  /// otherwise falls back to Mifflin.
  static double bestBmr({
    required Gender gender,
    required int age,
    required double weightKg,
    required double heightCm,
    double? bodyFatPct,
  }) {
    if (bodyFatPct != null && bodyFatPct >= 3 && bodyFatPct <= 60) {
      return bmrKatchMcArdle(weightKg, bodyFatPct);
    }
    return bmr(
        gender: gender, age: age, weightKg: weightKg, heightCm: heightCm);
  }

  static double activityFactor(ActivityLevel a) {
    switch (a) {
      case ActivityLevel.sedentary:
        return 1.2;
      case ActivityLevel.light:
        return 1.375;
      case ActivityLevel.moderate:
        return 1.55;
      case ActivityLevel.active:
        return 1.725;
      case ActivityLevel.veryActive:
        return 1.9;
    }
  }

  static int calorieFloor(Gender g) {
    switch (g) {
      case Gender.male:
        return HealthConstants.calorieFloorMale;
      case Gender.female:
        return HealthConstants.calorieFloorFemale;
      case Gender.other:
        return HealthConstants.calorieFloorOther;
    }
  }

  static double bmi({required double weightKg, required double heightCm}) {
    final m = heightCm / 100.0;
    return weightKg / (m * m);
  }

  /// Menstrual-cycle phase adjustments. Conservative — these match the
  /// scientific consensus on luteal-phase metabolic uplift (BMR ~3-5%
  /// higher, hunger up, fluid retention).
  static ({int kcalDelta, int waterMlDelta}) cycleAdjustments(
      CyclePhase phase) {
    switch (phase) {
      case CyclePhase.luteal:
        return (kcalDelta: 100, waterMlDelta: 300);
      case CyclePhase.menstrual:
        return (kcalDelta: 0, waterMlDelta: 250);
      case CyclePhase.ovulation:
      case CyclePhase.follicular:
      case CyclePhase.unknown:
        return (kcalDelta: 0, waterMlDelta: 0);
    }
  }

  /// Per-keyword adjustments derived from the user's body-focus chips.
  /// Adds (or subtracts) on top of the goal-based calorie target and
  /// nudges protein. Conservative on purpose — these are gentle nudges,
  /// not aggressive overrides.
  static (int kcalDelta, int proteinDeltaG) bodyFocusAdjustments(
      String notes) {
    final lower = notes.toLowerCase();
    var kcal = 0;
    var protein = 0;
    if (lower.contains('belly fat')) kcal -= 200;
    if (lower.contains('skinny fat')) {
      kcal -= 100;
      protein += 10;
    }
    if (lower.contains('skinny arms')) protein += 10;
    if (lower.contains('skinny legs')) protein += 5;
    if (lower.contains('upper body heavy')) kcal -= 100;
    if (lower.contains('lower body heavy')) kcal -= 100;
    if (lower.contains('overall lean')) {
      kcal += 100;
      protein += 5;
    }
    // 'athletic' = no change (maintenance)
    return (kcal, protein);
  }

  /// Extra water (ml/day) recommended for the supplements the user
  /// reports taking. Creatine especially raises intracellular water
  /// needs; protein helps with kidney load on high-protein diets.
  static int supplementWaterBumpMl({
    required int creatineGramsPerDay,
    required int proteinScoopsPerDay,
  }) {
    // Roughly +100 ml per gram of creatine (capped sensibly), plus
    // +250 ml per scoop of protein.
    final fromCreatine = (creatineGramsPerDay.clamp(0, 20)) * 100;
    final fromProtein = (proteinScoopsPerDay.clamp(0, 6)) * 250;
    return fromCreatine + fromProtein;
  }

  /// Months of training experience based on `gymStartDate`. Returns null
  /// when unknown. Used to detect the newbie-gains window so we don't
  /// over-cut a beginner who still has easy muscle growth available.
  static int? trainingMonths(DateTime? gymStartDate, {DateTime? now}) {
    if (gymStartDate == null) return null;
    final t = now ?? DateTime.now();
    final months =
        (t.year - gymStartDate.year) * 12 + (t.month - gymStartDate.month);
    return months < 0 ? 0 : months;
  }

  /// Whether the given flag set should trigger a "see a professional"
  /// warning card. These conditions can't safely be auto-tuned with
  /// generic formulas — surface a banner and let the user decide.
  static bool requiresProfessionalGuidance(List<HealthFlag> flags) {
    return flags.contains(HealthFlag.pregnant) ||
        flags.contains(HealthFlag.breastfeeding) ||
        flags.contains(HealthFlag.eatingDisorderHistory) ||
        flags.contains(HealthFlag.t1Diabetes);
  }

  /// Per-flag tuning. Returns (kcal multiplier, kcal delta, protein
  /// delta, carb cap%) so we can stack effects without mutating the
  /// goal-driven base. Conservative across the board.
  static ({
    double tdeeMultiplier,
    int kcalDelta,
    int proteinDeltaG,
    double? carbsMaxFractionOfKcal,
  }) flagAdjustments(List<HealthFlag> flags) {
    double mul = 1.0;
    int kcal = 0;
    int protein = 0;
    double? carbsMaxFraction;
    for (final f in flags) {
      switch (f) {
        case HealthFlag.hypothyroid:
          mul *= 0.93; // hormone-suppressed metabolism, ~7% lower
        case HealthFlag.pcos:
          mul *= 0.95; // insulin resistance often lowers maintenance
          carbsMaxFraction = 0.40; // shift to higher protein/fat
        case HealthFlag.t2Diabetes:
          carbsMaxFraction = 0.35; // carb-conscious split
          protein += 10;
        case HealthFlag.recoveringFromInjury:
          kcal += 100; // no cuts; modest surplus to rebuild
          protein += 15;
        case HealthFlag.pregnant:
          kcal += 300; // 2nd / 3rd trimester baseline; user should
          protein += 25; // verify with their OB-GYN
        case HealthFlag.breastfeeding:
          kcal += 450;
          protein += 25;
        case HealthFlag.eatingDisorderHistory:
          // No automatic adjustment — surface a warning instead.
          break;
        case HealthFlag.t1Diabetes:
          // Carb counting is medical; don't auto-tune. Warning instead.
          break;
      }
    }
    return (
      tdeeMultiplier: mul,
      kcalDelta: kcal,
      proteinDeltaG: protein,
      carbsMaxFractionOfKcal: carbsMaxFraction,
    );
  }

  /// Adjustment for training experience. Newbies (< 6 months) get a
  /// smaller deficit + small protein bonus so the muscle-building window
  /// is preserved. Returns (kcal delta, protein delta).
  static (int kcalDelta, int proteinDeltaG) experienceAdjustments(
      int? trainingMonthsValue, FitnessGoal goal) {
    if (trainingMonthsValue == null) return (0, 0);
    // Only soften the math for goals that *cut*. Building/general should
    // already be in a surplus or maintenance — no need to add more.
    final cuts =
        goal == FitnessGoal.loseFat || goal == FitnessGoal.recomp;
    if (trainingMonthsValue < 6) {
      return (cuts ? 100 : 0, 5);
    }
    return (0, 0);
  }

  static ComputedTargets compute({
    required Gender gender,
    required int age,
    required double weightKg,
    required double heightCm,
    required ActivityLevel activity,
    required FitnessGoal goal,
    int cardioSessionsPerWeek = 0,
    double walkingKmPerDay = 0,
    double runningKmPerWeek = 0,
    int gymMinutesPerSession = 60,
    int strengthDaysPerWeek = 0,
    String bodyFocusNotes = '',
    int creatineGramsPerDay = 0,
    int proteinScoopsPerDay = 0,
    DateTime? gymStartDate,
    double? bodyFatPct,
    List<HealthFlag> healthFlags = const [],
    List<int> restDays = const [],
    CyclePhase cyclePhase = CyclePhase.unknown,
  }) {
    final usedKM = bodyFatPct != null && bodyFatPct >= 3 && bodyFatPct <= 60;
    final b = bestBmr(
      gender: gender,
      age: age,
      weightKg: weightKg,
      heightCm: heightCm,
      bodyFatPct: bodyFatPct,
    );

    // If the user gave us explicit exercise volume (km or strength days),
    // the labelled activity factor already bakes that in — adding the
    // km/gym burns on top would double-count. Cap the baseline at "Light"
    // (lifestyle-only NEAT) when explicit volume is present, then layer
    // the precise burns. If they gave us nothing precise, trust the label.
    final hasExplicitVolume = walkingKmPerDay > 0 ||
        runningKmPerWeek > 0 ||
        strengthDaysPerWeek > 0 ||
        cardioSessionsPerWeek > 0;
    final factor = hasExplicitVolume
        ? activityFactor(activity).clamp(1.2, 1.375)
        : activityFactor(activity);
    final baseTdee = b * factor;

    // Scale km-based burns by bodyweight so heavier users burn more.
    final wScale = weightKg / 70.0;

    final walkingDaily =
        walkingKmPerDay.clamp(0, 30) * _kcalPerKmWalkingPer70kg * wScale;
    final runningDaily = (runningKmPerWeek.clamp(0, 100) *
            _kcalPerKmRunningPer70kg *
            wScale) /
        7.0;

    // If user provided km, prefer it. Otherwise fall back to legacy
    // session-count cardio.
    final cardioDailyBump = (runningKmPerWeek > 0)
        ? runningDaily
        : (cardioSessionsPerWeek.clamp(0, 14) * _kcalPerCardioSession) / 7.0;

    // Strength-training burn. When base is capped (NEAT only), count the
    // full session length so we capture the actual lifting cost. When the
    // labelled factor is in play, only count minutes beyond a 60-min
    // baseline — the label already covers a "typical" session.
    final gymMinCounted = hasExplicitVolume
        ? gymMinutesPerSession.clamp(0, 150)
        : (gymMinutesPerSession - 60).clamp(0, 90);
    final gymDailyBump =
        (strengthDaysPerWeek.clamp(0, 7) * gymMinCounted * _kcalPerGymMinutePer70kg *
                wScale) /
            7.0;

    // Apply health-flag TDEE multiplier (hypothyroid / PCOS lower it).
    final flagAdj = flagAdjustments(healthFlags);
    final t = (baseTdee + walkingDaily + cardioDailyBump + gymDailyBump) *
        flagAdj.tdeeMultiplier;

    final maxDailyDelta =
        (weightKg * HealthConstants.maxWeightChangeFraction *
                HealthConstants.kcalPerKgBodyMass) /
            7.0;

    int raw;
    switch (goal) {
      case FitnessGoal.loseFat:
        raw = (t - 500).round();
        final minAllowed = (t - maxDailyDelta).round();
        if (raw < minAllowed) raw = minAllowed;
        break;
      case FitnessGoal.buildMuscle:
        raw = (t + 300).round();
        final maxAllowed = (t + maxDailyDelta).round();
        if (raw > maxAllowed) raw = maxAllowed;
        break;
      case FitnessGoal.recomp:
        raw = (t - 150).round(); // slight deficit for body composition
        break;
      case FitnessGoal.generalFitness:
        raw = t.round();
        break;
    }

    // Apply body-focus deltas on top of the goal-based number.
    final (focusKcalDelta, focusProteinDelta) =
        bodyFocusAdjustments(bodyFocusNotes);
    raw += focusKcalDelta;

    // Newbie-gains protection: soften deficits in the first 6 months.
    final (expKcalDelta, expProteinDelta) =
        experienceAdjustments(trainingMonths(gymStartDate), goal);
    raw += expKcalDelta;

    // Flag-driven flat kcal delta (recovery, pregnancy, breastfeeding).
    raw += flagAdj.kcalDelta;

    // Cycle-phase delta (luteal +100 kcal etc.).
    final cycleAdj = cycleAdjustments(cyclePhase);
    raw += cycleAdj.kcalDelta;

    final floor = calorieFloor(gender);
    final calorieTarget = raw < floor ? floor : raw;

    // Rest-day target: same protein/fat, but strip the day's worth of
    // gym + cardio burn so the user can eat at maintenance on off days.
    final restDayCardioStripped =
        (walkingDaily * 0.5 + gymDailyBump + cardioDailyBump).round();
    final restDayCalorieTarget =
        (calorieTarget - restDayCardioStripped).clamp(floor, 99999);

    final proteinPerKg = switch (goal) {
      FitnessGoal.buildMuscle => 2.0,
      FitnessGoal.loseFat => 2.2,
      FitnessGoal.recomp => 2.0,
      FitnessGoal.generalFitness => 1.6,
    };
    final proteinG = (proteinPerKg * weightKg).round() +
        focusProteinDelta +
        expProteinDelta +
        flagAdj.proteinDeltaG;

    final fatG = (0.9 * weightKg).round();

    final proteinKcal = proteinG * 4;
    final fatKcal = fatG * 9;
    final remainingKcal = calorieTarget - proteinKcal - fatKcal;
    var carbG = (remainingKcal / 4).clamp(0, 1000).round();
    // Carb cap for PCOS / T2 diabetes: never exceed the cap fraction of
    // total calories. Extra kcal go to fat to keep totals consistent.
    if (flagAdj.carbsMaxFractionOfKcal != null) {
      final maxCarbG =
          ((calorieTarget * flagAdj.carbsMaxFractionOfKcal!) / 4).round();
      if (carbG > maxCarbG) carbG = maxCarbG;
    }

    final fiberG = (14 * (calorieTarget / 1000.0)).round();

    final baseWaterMl = (33 * weightKg).round();
    final waterMl = baseWaterMl +
        supplementWaterBumpMl(
          creatineGramsPerDay: creatineGramsPerDay,
          proteinScoopsPerDay: proteinScoopsPerDay,
        ) +
        cycleAdj.waterMlDelta;

    return ComputedTargets(
      bmr: b,
      tdee: t,
      calorieTarget: calorieTarget,
      restDayCalorieTarget:
          restDays.isEmpty ? calorieTarget : restDayCalorieTarget,
      proteinG: proteinG,
      carbG: carbG,
      fatG: fatG,
      fiberG: fiberG,
      waterMl: waterMl,
      usedKatchMcArdle: usedKM,
      warnConsultProfessional: requiresProfessionalGuidance(healthFlags),
      bmi: bmi(weightKg: weightKg, heightCm: heightCm),
    );
  }

  // BMI context label — neutral, no judgment (per SPEC §5).
  static String bmiContext(double bmi) {
    if (bmi < 18.5) return 'Lower range';
    if (bmi < 25) return 'Typical range';
    if (bmi < 30) return 'Higher range';
    return 'Significantly higher range';
  }
}
