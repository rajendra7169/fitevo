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

  static ComputedTargets compute({
    required Gender gender,
    required int age,
    required double weightKg,
    required double heightCm,
    required ActivityLevel activity,
    required FitnessGoal goal,
  }) {
    final b = bmr(
        gender: gender, age: age, weightKg: weightKg, heightCm: heightCm);
    final t = b * activityFactor(activity);

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
        raw = t.round();
        break;
      case FitnessGoal.generalFitness:
        raw = t.round();
        break;
    }

    final floor = calorieFloor(gender);
    final calorieTarget = raw < floor ? floor : raw;

    final proteinPerKg = switch (goal) {
      FitnessGoal.buildMuscle => 2.0,
      FitnessGoal.loseFat => 2.2,
      FitnessGoal.recomp => 1.9,
      FitnessGoal.generalFitness => 1.6,
    };
    final proteinG = (proteinPerKg * weightKg).round();

    final fatG = (0.9 * weightKg).round();

    final proteinKcal = proteinG * 4;
    final fatKcal = fatG * 9;
    final remainingKcal = calorieTarget - proteinKcal - fatKcal;
    final carbG = (remainingKcal / 4).clamp(0, 1000).round();

    final fiberG = (14 * (calorieTarget / 1000.0)).round();

    final waterMl = (33 * weightKg).round();

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
