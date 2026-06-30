import '../../data/models/body_measurement.dart';
import '../../data/models/daily_log.dart';
import '../../data/models/food_entry.dart';
import '../../data/models/profile.dart';
import '../../data/models/workout_session.dart';
import '../../data/repositories/nutrition_repo.dart';
import '../../home/todays_activity_card.dart' show TodaysActivityMath;
import '../../services/progress/weight_trend.dart';

/// One detected "event" worth nudging the user about. The AI gets these
/// as a structured list and is asked to pick the single most important
/// one — never more than one nudge surfaces at a time, otherwise the
/// home screen turns into a notification dump.
class NudgeTrigger {
  /// Short tag (kept stable) — used as part of the cache fingerprint so
  /// the same trigger on the same day doesn't generate a new AI call
  /// on every rebuild.
  final String kind;

  /// Plain-English fact for the AI to pick from. Phrased so it could
  /// be quoted directly, e.g. "Skipped 2 planned workouts this week".
  final String fact;

  /// Optional supporting numbers for the AI to weave in.
  final Map<String, String> details;

  /// Priority — higher beats lower when multiple events fire. PRs and
  /// streak drops always outrank gentle nudges so the user sees the
  /// most-actionable thing first.
  final int priority;

  const NudgeTrigger({
    required this.kind,
    required this.fact,
    required this.priority,
    this.details = const {},
  });
}

/// Computes the list of things worth nudging about, given the user's
/// recent state. Pure function — no async, no UI, returns a list the
/// caller can hand to the AI.
class ProactiveNudge {
  /// Build the trigger list. Empty result means "nothing notable; don't
  /// nudge". Caller should not call AI when this is empty.
  static List<NudgeTrigger> detect({
    required Profile profile,
    required List<FoodEntry> last7Foods,
    required List<DailyLog> last7Logs,
    required List<WorkoutSession> last7Sessions,
    required List<BodyMeasurement> measurements,
    required WeightTrend weightTrend,
    required int currentStreakDays,
    DateTime? now,
  }) {
    final today = DateTime(
      (now ?? DateTime.now()).year,
      (now ?? DateTime.now()).month,
      (now ?? DateTime.now()).day,
    );
    final triggers = <NudgeTrigger>[];
    final foodsByDay = <String, List<FoodEntry>>{};
    for (final f in last7Foods) {
      (foodsByDay[f.dateKey] ??= []).add(f);
    }
    final logsByDay = <String, DailyLog>{
      for (final l in last7Logs) l.dateKey: l,
    };
    final sessionsByDay = <String, List<WorkoutSession>>{};
    for (final s in last7Sessions) {
      (sessionsByDay[s.dateKey] ??= []).add(s);
    }

    // -- Workout adherence ---------------------------------------------------
    final plannedPerWeek = profile.trainingDaysPerWeek;
    final completedThisWeek =
        last7Sessions.where((s) => s.completedAt != null).length;
    final skipped =
        (plannedPerWeek - completedThisWeek).clamp(0, plannedPerWeek);
    if (skipped >= 2) {
      triggers.add(NudgeTrigger(
        kind: 'skipped_workouts',
        fact: 'Skipped $skipped planned workouts in the last 7 days '
            '($completedThisWeek done vs $plannedPerWeek planned).',
        priority: 70,
        details: {'skipped': '$skipped', 'planned': '$plannedPerWeek'},
      ));
    } else if (skipped == 1 && plannedPerWeek <= 4) {
      triggers.add(NudgeTrigger(
        kind: 'skipped_workouts',
        fact: 'Skipped 1 planned workout this week.',
        priority: 30,
      ));
    }

    // -- Calorie misses against activity-adjusted target ---------------------
    int overDays = 0, hugelyOverDays = 0, underDays = 0;
    int proteinMisses = 0;
    for (var i = 1; i <= 6; i++) {
      final day = today.subtract(Duration(days: i));
      final key = DailyLog.keyFor(day);
      final foods = foodsByDay[key] ?? const <FoodEntry>[];
      if (foods.isEmpty) continue;
      final log = logsByDay[key];
      final totals = NutritionRepo.sumEntries(foods);
      final calT = TodaysActivityMath.effectiveTodayCalorieTarget(
          profile: profile, log: log);
      final mac = TodaysActivityMath.effectiveTodayMacros(
          profile: profile, log: log);
      if (calT > 0) {
        final pct = (totals.calories - calT) / calT;
        if (pct > 0.20) hugelyOverDays++;
        if (pct > 0.10) overDays++;
        if (pct < -0.15) underDays++;
      }
      if (mac.proteinG > 0 && totals.proteinG < mac.proteinG * 0.7) {
        proteinMisses++;
      }
    }
    if (hugelyOverDays >= 2) {
      triggers.add(NudgeTrigger(
        kind: 'kcal_huge_over',
        fact: '$hugelyOverDays days were >20% over the calorie target in '
            'the last 6 days.',
        priority: 80,
      ));
    } else if (overDays >= 3) {
      triggers.add(NudgeTrigger(
        kind: 'kcal_over_streak',
        fact: '$overDays of the last 6 days were over the calorie target '
            'by more than 10%.',
        priority: 55,
      ));
    }
    if (underDays >= 3 && profile.goal.name == 'buildMuscle') {
      triggers.add(NudgeTrigger(
        kind: 'kcal_under_build',
        fact: 'Goal is build muscle but $underDays of the last 6 days '
            'were >15% UNDER the calorie target.',
        priority: 65,
      ));
    }
    if (proteinMisses >= 3) {
      triggers.add(NudgeTrigger(
        kind: 'protein_low',
        fact: '$proteinMisses days were below 70% of protein target in '
            'the last 6 days.',
        priority: 50,
      ));
    }

    // -- Weight trend vs goal ------------------------------------------------
    if (weightTrend.verdict.isNotEmpty &&
        weightTrend.kgPerWeek != null &&
        weightTrend.sampleCount >= 3) {
      // The WeightTrend verdict is already opinionated. Wrap it as a
      // trigger so the AI can quote it directly.
      final kpw = weightTrend.kgPerWeek!;
      final misalign = (profile.goal.name == 'buildMuscle' && kpw <= 0) ||
          (profile.goal.name == 'loseFat' && kpw >= 0);
      triggers.add(NudgeTrigger(
        kind: 'weight_trend',
        fact: weightTrend.verdict,
        priority: misalign ? 75 : 35,
        details: {
          'kg_per_week': kpw.toStringAsFixed(2),
          'latest_kg': (weightTrend.latestKg ?? 0).toStringAsFixed(1),
        },
      ));
    }

    // -- PR detected this week ---------------------------------------------
    final prsThisWeek = _countPrsThisWeek(last7Sessions, today);
    if (prsThisWeek > 0) {
      triggers.add(NudgeTrigger(
        kind: 'pr_hit',
        fact: 'Hit $prsThisWeek personal record${prsThisWeek == 1 ? '' : 's'} '
            'in the last 7 days.',
        priority: 60,
      ));
    }

    // -- Streak signals -----------------------------------------------------
    if (currentStreakDays >= 14) {
      triggers.add(NudgeTrigger(
        kind: 'streak_long',
        fact: '$currentStreakDays-day logging streak active.',
        priority: 25,
      ));
    } else if (currentStreakDays == 0 && _userWasActiveRecently(last7Foods)) {
      triggers.add(NudgeTrigger(
        kind: 'streak_dropped',
        fact: 'Logging streak just broke — nothing logged today, but '
            'previous days were on track.',
        priority: 65,
      ));
    }

    // -- No weight logged in 14 days ---------------------------------------
    if (measurements.isNotEmpty) {
      final newest = measurements
          .map((m) => m.date)
          .reduce((a, b) => a.isAfter(b) ? a : b);
      final daysSince = today.difference(newest).inDays;
      if (daysSince >= 14) {
        triggers.add(NudgeTrigger(
          kind: 'weighin_stale',
          fact: 'No weigh-in for $daysSince days — adaptive engine is '
              'flying blind.',
          priority: 45,
        ));
      }
    } else if (currentStreakDays >= 7) {
      triggers.add(NudgeTrigger(
        kind: 'weighin_never',
        fact: 'User has $currentStreakDays days of food logs but zero '
            'weigh-ins logged.',
        priority: 40,
      ));
    }

    // Sort newest priority first; AI picks the top one.
    triggers.sort((a, b) => b.priority.compareTo(a.priority));
    return triggers;
  }

  static bool _userWasActiveRecently(List<FoodEntry> foods) {
    if (foods.isEmpty) return false;
    final since =
        DateTime.now().subtract(const Duration(days: 4));
    return foods.any((f) => f.timestamp.isAfter(since));
  }

  static int _countPrsThisWeek(
      List<WorkoutSession> sessions, DateTime today) {
    // A "this week" PR is a set whose e1RM strictly exceeds every
    // earlier set for the same exercise. We compare each set in the
    // last 7 days against any earlier matching set in the list — the
    // caller passes only the last 7 days, so we widen by checking
    // each set inside this window against the running best so far.
    final cutoff = today.subtract(const Duration(days: 7));
    final ordered = List<WorkoutSession>.from(sessions)
      ..sort((a, b) => a.startedAt.compareTo(b.startedAt));
    final best = <String, double>{};
    int prs = 0;
    for (final s in ordered) {
      for (final set in s.sets) {
        if (set.isWarmup || set.weightKg <= 0 || set.reps <= 0) continue;
        final e1rm = set.weightKg * (1 + set.reps / 30.0);
        final prev = best[set.exerciseName] ?? 0;
        if (e1rm > prev + 0.5) {
          if (!s.startedAt.isBefore(cutoff)) prs++;
          best[set.exerciseName] = e1rm;
        }
      }
    }
    return prs;
  }

  /// Stable fingerprint of the top trigger — used so re-renders on the
  /// same day with the same data hit cache instead of burning AI calls.
  static String fingerprint(List<NudgeTrigger> triggers, DateTime day) {
    if (triggers.isEmpty) return 'none-${day.toIso8601String().substring(0, 10)}';
    final top = triggers.first;
    final kvs = top.details.entries
        .map((e) => '${e.key}=${e.value}')
        .toList()
      ..sort();
    return '${day.toIso8601String().substring(0, 10)}-${top.kind}-${kvs.join(',')}';
  }

  /// AI prompt for the nudge. Returns the user-context block to hand
  /// to coachChat. The system prompt's strict-coach tone handles the
  /// voice; this just gives it the facts + a directive.
  static String buildContext({
    required Profile profile,
    required List<NudgeTrigger> triggers,
    required WeightTrend trend,
  }) {
    final factLines = triggers
        .take(4)
        .map((t) => '- ${t.fact} [tag: ${t.kind}, priority ${t.priority}]')
        .toList();
    return [
      'Name: ${profile.displayName.isEmpty ? "user" : profile.displayName}',
      'Goal: ${profile.goal.name}',
      'Diet: ${profile.dietPreference.name}',
      if (trend.toContextLines().isNotEmpty) trend.toContextLines(),
      'Detected events (pick the SINGLE most actionable one — never list '
          'more than one, never enumerate):',
      ...factLines,
    ].join('\n');
  }

  /// User message that goes alongside [buildContext]. Pure instruction
  /// — the system prompt already has tone rules.
  static const String userInstruction =
      'Write one short coach observation (max 2 sentences) about the '
      'highest-priority detected event. Quote the actual number from '
      'the fact line. Follow with at most one specific next action. '
      'No greeting, no sign-off, no markdown.';
}
