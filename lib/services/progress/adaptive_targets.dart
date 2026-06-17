import '../../core/health_math.dart';
import '../../data/models/profile.dart';
import '../../data/repositories/measurement_repo.dart';
import '../../data/repositories/profile_repo.dart';

class AdaptiveTargets {
  AdaptiveTargets({
    required this.profileRepo,
    required this.measurementRepo,
  });

  final ProfileRepo profileRepo;
  final MeasurementRepo measurementRepo;

  /// Recompute calorie/macro/water targets from the latest rolling-average
  /// weight. Skips fields the user has explicitly overridden.
  Future<Profile?> recomputeFromWeightTrend() async {
    final profile = await profileRepo.getCurrent();
    if (profile == null) return null;
    final avg = await measurementRepo.rollingAverageWeight(windowDays: 7);
    if (avg == null || avg <= 0) return null;
    // Don't churn for tiny fluctuations.
    if ((avg - profile.weightKg).abs() < 0.4) return profile;

    final targets = HealthMath.compute(
      gender: profile.gender,
      age: profile.age,
      weightKg: avg,
      heightCm: profile.heightCm,
      activity: profile.activityLevel,
      goal: profile.goal,
    );

    profile
      ..weightKg = avg
      ..bmr = targets.bmr
      ..tdee = targets.tdee
      ..bmi = targets.bmi
      ..calorieTarget = targets.calorieTarget
      ..proteinTargetG = targets.proteinG
      ..carbTargetG = targets.carbG
      ..fatTargetG = targets.fatG
      ..fiberTargetG = targets.fiberG
      ..waterTargetMl = targets.waterMl;
    await profileRepo.save(profile);
    return profile;
  }
}
