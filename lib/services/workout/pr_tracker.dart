import '../../data/models/workout_session.dart';

class PrEntry {
  final int exerciseId;
  final String exerciseName;
  final double weightKg;
  final int reps;
  final double estimated1RM;
  final DateTime achievedAt;

  const PrEntry({
    required this.exerciseId,
    required this.exerciseName,
    required this.weightKg,
    required this.reps,
    required this.estimated1RM,
    required this.achievedAt,
  });
}

class PrTracker {
  /// Estimated 1-rep max via Epley formula. Returns 0 for invalid input.
  static double estimated1RM(double weightKg, int reps) {
    if (reps <= 0 || weightKg <= 0) return 0;
    if (reps == 1) return weightKg;
    return weightKg * (1 + reps / 30);
  }

  static double estimatedFromSet(SetEntry s) =>
      estimated1RM(s.weightKg, s.reps);

  /// Best estimated 1RM achieved across all the given sessions for the
  /// exercise. Skips a specific session id (the one currently in progress).
  static double bestForExercise(
    List<WorkoutSession> sessions,
    int exerciseId, {
    int? excludeSessionId,
  }) {
    double best = 0;
    for (final s in sessions) {
      if (s.id == excludeSessionId) continue;
      for (final set in s.sets) {
        if (set.exerciseId != exerciseId) continue;
        final e = estimatedFromSet(set);
        if (e > best) best = e;
      }
    }
    return best;
  }

  /// Returns one PrEntry per exercise the user has ever logged (the best
  /// effort for that exercise). Sorted by achievement date desc.
  static List<PrEntry> personalRecords(List<WorkoutSession> sessions) {
    final byExercise = <int, PrEntry>{};
    for (final s in sessions) {
      for (final set in s.sets) {
        final e = estimatedFromSet(set);
        if (e <= 0) continue;
        final existing = byExercise[set.exerciseId];
        if (existing == null || e > existing.estimated1RM) {
          byExercise[set.exerciseId] = PrEntry(
            exerciseId: set.exerciseId,
            exerciseName: set.exerciseName,
            weightKg: set.weightKg,
            reps: set.reps,
            estimated1RM: e,
            achievedAt: set.completedAt,
          );
        }
      }
    }
    final list = byExercise.values.toList();
    list.sort((a, b) => b.achievedAt.compareTo(a.achievedAt));
    return list;
  }
}
