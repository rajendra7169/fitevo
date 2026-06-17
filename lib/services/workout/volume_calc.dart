import '../../data/models/enums.dart';
import '../../data/models/exercise.dart';
import '../../data/models/workout_session.dart';

class VolumeCalc {
  /// Returns sets-per-muscle-group across the supplied sessions.
  /// `exerciseLookup` maps exerciseId → muscle groups (so the caller
  /// fetches Exercise records once and we don't hit the DB per set).
  static Map<MuscleGroup, int> setsByMuscleGroup({
    required List<WorkoutSession> sessions,
    required Map<int, List<MuscleGroup>> exerciseMuscleGroups,
  }) {
    final result = <MuscleGroup, int>{};
    for (final s in sessions) {
      for (final set in s.sets) {
        final groups = exerciseMuscleGroups[set.exerciseId];
        if (groups == null || groups.isEmpty) continue;
        for (final g in groups) {
          // Ignore "cardio" / "fullBody" tags for muscle-volume display.
          if (g == MuscleGroup.cardio || g == MuscleGroup.fullBody) continue;
          result[g] = (result[g] ?? 0) + 1;
        }
      }
    }
    return result;
  }

  static Future<Map<int, List<MuscleGroup>>> buildLookup(
    List<Exercise> exercises,
  ) async {
    return {for (final e in exercises) e.id: e.muscleGroups};
  }

  /// MET-based estimate of calories burned across a session.
  /// Defaults to MET 5.0 for general strength training.
  static int sessionCalories({
    required double bodyWeightKg,
    required Duration duration,
    double met = 5.0,
  }) {
    final mins = duration.inMinutes.toDouble();
    if (mins <= 0 || bodyWeightKg <= 0) return 0;
    final kcalPerMin = met * bodyWeightKg * 3.5 / 200.0;
    return (kcalPerMin * mins).round();
  }
}
