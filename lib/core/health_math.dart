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
  final int proteinG;
  final int carbG;
  final int fatG;
  final int fiberG;
  final int waterMl;
  final double bmi;

  const ComputedTargets({
    required this.bmr,
    required this.tdee,
    required this.calorieTarget,
    required this.proteinG,
    required this.carbG,
    required this.fatG,
    required this.fiberG,
    required this.waterMl,
    required this.bmi,
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
  }) {
    final b = bmr(
        gender: gender, age: age, weightKg: weightKg, heightCm: heightCm);

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

    final t = baseTdee + walkingDaily + cardioDailyBump + gymDailyBump;

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

    final floor = calorieFloor(gender);
    final calorieTarget = raw < floor ? floor : raw;

    final proteinPerKg = switch (goal) {
      FitnessGoal.buildMuscle => 2.0,
      FitnessGoal.loseFat => 2.2,
      FitnessGoal.recomp => 2.0,
      FitnessGoal.generalFitness => 1.6,
    };
    final proteinG = (proteinPerKg * weightKg).round() + focusProteinDelta;

    final fatG = (0.9 * weightKg).round();

    final proteinKcal = proteinG * 4;
    final fatKcal = fatG * 9;
    final remainingKcal = calorieTarget - proteinKcal - fatKcal;
    final carbG = (remainingKcal / 4).clamp(0, 1000).round();

    final fiberG = (14 * (calorieTarget / 1000.0)).round();

    final baseWaterMl = (33 * weightKg).round();
    final waterMl = baseWaterMl +
        supplementWaterBumpMl(
          creatineGramsPerDay: creatineGramsPerDay,
          proteinScoopsPerDay: proteinScoopsPerDay,
        );

    return ComputedTargets(
      bmr: b,
      tdee: t,
      calorieTarget: calorieTarget,
      proteinG: proteinG,
      carbG: carbG,
      fatG: fatG,
      fiberG: fiberG,
      waterMl: waterMl,
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
