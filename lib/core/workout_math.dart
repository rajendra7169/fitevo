import '../data/models/workout_session.dart';

/// Best-ever record for a single exercise.
class ExercisePr {
  final String exerciseName;
  final double weightKg;
  final int reps;
  final DateTime achievedAt;

  /// Estimated 1RM via the Epley formula: w * (1 + reps/30).
  double get estimated1RM => weightKg * (1 + reps / 30.0);

  const ExercisePr({
    required this.exerciseName,
    required this.weightKg,
    required this.reps,
    required this.achievedAt,
  });
}

/// A plateau finding for one exercise: top weight × reps hasn't changed
/// in [weeksStale] consecutive weeks.
class PlateauSignal {
  final String exerciseName;
  final double topWeightKg;
  final int topReps;
  final int weeksStale;
  const PlateauSignal({
    required this.exerciseName,
    required this.topWeightKg,
    required this.topReps,
    required this.weeksStale,
  });
}

/// Volume tally — total tonnage (sets × reps × weight) per exercise or
/// per top-level grouping. Set-count is also useful as a coarse metric.
class VolumeTally {
  final String key; // exercise name or muscle group label
  final int sets;
  final double tonnageKg;
  const VolumeTally({
    required this.key,
    required this.sets,
    required this.tonnageKg,
  });
}

class WorkoutMath {
  /// Estimated 1RM via Epley. Returns 0 if reps or weight is non-positive.
  static double epley1RM(double weightKg, int reps) {
    if (weightKg <= 0 || reps <= 0) return 0;
    return weightKg * (1 + reps / 30.0);
  }

  /// Best ever set per exercise across the given sessions, ranked by
  /// estimated 1RM (so 80kg × 5 beats 100kg × 1 for a hypertrophy lift).
  /// Excludes warmup sets.
  static Map<String, ExercisePr> personalRecords(
      List<WorkoutSession> sessions) {
    final best = <String, ExercisePr>{};
    for (final s in sessions) {
      for (final set in s.sets) {
        if (set.isWarmup || set.weightKg <= 0 || set.reps <= 0) continue;
        final candidate1RM = epley1RM(set.weightKg, set.reps);
        final existing = best[set.exerciseName];
        if (existing == null || candidate1RM > existing.estimated1RM) {
          best[set.exerciseName] = ExercisePr(
            exerciseName: set.exerciseName,
            weightKg: set.weightKg,
            reps: set.reps,
            achievedAt: set.completedAt,
          );
        }
      }
    }
    return best;
  }

  /// Exercises whose top working set (by estimated 1RM) hasn't improved
  /// in [staleWeeks] consecutive weeks. Only flags exercises trained at
  /// least once per week in the window — sporadic lifts don't plateau,
  /// they just go uncovered.
  static List<PlateauSignal> plateaus(
    List<WorkoutSession> sessions, {
    int staleWeeks = 3,
    DateTime? now,
  }) {
    final t = now ?? DateTime.now();
    final cutoff = t.subtract(Duration(days: staleWeeks * 7));

    // Bucket sessions into weeks (ISO week start = Monday).
    DateTime weekStart(DateTime d) {
      final monday = d.subtract(Duration(days: d.weekday - 1));
      return DateTime(monday.year, monday.month, monday.day);
    }

    // For each exercise, gather (week, best1RM, topSet) entries.
    final perExerciseWeeks =
        <String, Map<DateTime, (double, double, int)>>{};
    for (final s in sessions) {
      if (s.startedAt.isBefore(cutoff)) continue;
      final wk = weekStart(s.startedAt);
      for (final set in s.sets) {
        if (set.isWarmup || set.weightKg <= 0 || set.reps <= 0) continue;
        final est = epley1RM(set.weightKg, set.reps);
        final map = perExerciseWeeks.putIfAbsent(set.exerciseName, () => {});
        final prev = map[wk];
        if (prev == null || est > prev.$1) {
          map[wk] = (est, set.weightKg, set.reps);
        }
      }
    }

    final results = <PlateauSignal>[];
    perExerciseWeeks.forEach((name, weekMap) {
      if (weekMap.length < staleWeeks) return;
      final sortedWeeks = weekMap.keys.toList()..sort();
      final values = sortedWeeks.map((w) => weekMap[w]!).toList();
      // No improvement = max 1RM in any later week never exceeds the first.
      final firstEst = values.first.$1;
      final improved = values.skip(1).any((v) => v.$1 > firstEst + 0.5);
      if (!improved) {
        final last = values.last;
        results.add(PlateauSignal(
          exerciseName: name,
          topWeightKg: last.$2,
          topReps: last.$3,
          weeksStale: sortedWeeks.length,
        ));
      }
    });
    return results;
  }

  /// Working-set count + tonnage per exercise across the window.
  /// Excludes warmups.
  static List<VolumeTally> volumeByExercise(
    List<WorkoutSession> sessions, {
    DateTime? since,
  }) {
    final cutoff = since;
    final byExercise = <String, (int, double)>{};
    for (final s in sessions) {
      if (cutoff != null && s.startedAt.isBefore(cutoff)) continue;
      for (final set in s.sets) {
        if (set.isWarmup || set.weightKg <= 0 || set.reps <= 0) continue;
        final prev = byExercise[set.exerciseName] ?? (0, 0.0);
        byExercise[set.exerciseName] =
            (prev.$1 + 1, prev.$2 + set.weightKg * set.reps);
      }
    }
    return byExercise.entries
        .map((e) => VolumeTally(
            key: e.key, sets: e.value.$1, tonnageKg: e.value.$2))
        .toList()
      ..sort((a, b) => b.tonnageKg.compareTo(a.tonnageKg));
  }

  /// Sets-per-muscle-group counter based on a name→group mapping that the
  /// caller supplies (since the exercise library owns muscle groups).
  /// Helpful for "arms are getting <12 sets/wk — add curls" hints.
  static Map<String, int> setsByMuscleGroup(
    List<WorkoutSession> sessions, {
    required Map<String, String> exerciseToGroup,
    DateTime? since,
  }) {
    final cutoff = since;
    final out = <String, int>{};
    for (final s in sessions) {
      if (cutoff != null && s.startedAt.isBefore(cutoff)) continue;
      for (final set in s.sets) {
        if (set.isWarmup || set.weightKg <= 0 || set.reps <= 0) continue;
        final group = exerciseToGroup[set.exerciseName];
        if (group == null) continue;
        out[group] = (out[group] ?? 0) + 1;
      }
    }
    return out;
  }

  /// True if the latest session for [exerciseName] beats every prior
  /// session in the input list (by estimated 1RM). Useful for "🎉 PR!"
  /// banners right after a workout finishes.
  static bool isNewPR(List<WorkoutSession> allSessions, String exerciseName) {
    WorkoutSession? latest;
    for (final s in allSessions) {
      if (latest == null || s.startedAt.isAfter(latest.startedAt)) {
        if (s.sets.any((set) => set.exerciseName == exerciseName)) {
          latest = s;
        }
      }
    }
    if (latest == null) return false;

    double latestBest = 0;
    for (final set in latest.sets) {
      if (set.exerciseName != exerciseName || set.isWarmup) continue;
      final e = epley1RM(set.weightKg, set.reps);
      if (e > latestBest) latestBest = e;
    }
    if (latestBest <= 0) return false;

    double priorBest = 0;
    for (final s in allSessions) {
      if (identical(s, latest)) continue;
      for (final set in s.sets) {
        if (set.exerciseName != exerciseName || set.isWarmup) continue;
        final e = epley1RM(set.weightKg, set.reps);
        if (e > priorBest) priorBest = e;
      }
    }
    return latestBest > priorBest + 0.5;
  }
}
