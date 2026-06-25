import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/workout_math.dart';
import '../data/models/food_entry.dart';
import '../data/models/profile.dart';
import '../data/models/workout_session.dart';
import '../state/providers.dart';
import '../theme.dart';

/// Card on the dashboard that summarises the last 7 days and offers an
/// on-demand AI coach recap. The math half (PRs, plateaus, adherence) is
/// deterministic and always visible. The narrative half is opt-in.
class WeeklyRecapCard extends ConsumerStatefulWidget {
  const WeeklyRecapCard({super.key});

  @override
  ConsumerState<WeeklyRecapCard> createState() => _WeeklyRecapCardState();
}

class _WeeklyRecapCardState extends ConsumerState<WeeklyRecapCard> {
  static const _prefsKey = 'weeklyRecap.lastText';
  static const _prefsTsKey = 'weeklyRecap.lastFetchedAt';

  bool _loading = false;
  String? _text;
  DateTime? _fetchedAt;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCache();
  }

  Future<void> _loadCache() async {
    final prefs = await SharedPreferences.getInstance();
    final t = prefs.getString(_prefsKey);
    final ts = prefs.getInt(_prefsTsKey);
    if (!mounted) return;
    setState(() {
      _text = t;
      if (ts != null) {
        _fetchedAt = DateTime.fromMillisecondsSinceEpoch(ts);
      }
    });
  }

  Future<void> _saveCache(String text) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, text);
    await prefs.setInt(
        _prefsTsKey, DateTime.now().millisecondsSinceEpoch);
  }

  bool get _isStale {
    if (_fetchedAt == null) return true;
    return DateTime.now().difference(_fetchedAt!).inDays >= 7;
  }

  String _buildSummary(
    Profile profile,
    List<WorkoutSession> sessions,
    List<FoodEntry> entries,
  ) {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final weekSessions = sessions
        .where((s) =>
            s.startedAt.isAfter(weekAgo) && s.completedAt != null)
        .toList();
    final weekEntries =
        entries.where((e) => e.timestamp.isAfter(weekAgo)).toList();

    // Macro adherence — % of days inside ±15% of calorie target.
    final daysHit = <String>{};
    final daysTracked = <String>{};
    final perDay = <String, int>{};
    for (final e in weekEntries) {
      daysTracked.add(e.dateKey);
      perDay[e.dateKey] = (perDay[e.dateKey] ?? 0) + e.calories;
    }
    final target = profile.effectiveCalorieTarget;
    for (final entry in perDay.entries) {
      final ratio = entry.value / target;
      if (ratio >= 0.85 && ratio <= 1.15) daysHit.add(entry.key);
    }

    // Workouts done.
    final workoutDays = weekSessions
        .map((s) => s.dateKey)
        .toSet()
        .length;

    // Volume + PRs in window.
    final volume = WorkoutMath.volumeByExercise(
      weekSessions,
      since: weekAgo,
    );
    final prs = WorkoutMath.personalRecords(weekSessions);
    final plateaus = WorkoutMath.plateaus(sessions, staleWeeks: 3, now: now);

    final lines = <String>[
      'Goal: ${profile.goal.name}',
      if (profile.country.isNotEmpty) 'Country: ${profile.country}',
      'Diet: ${profile.dietPreference.name}',
      'Body focus: ${profile.bodyFocusNotes.isEmpty ? "none" : profile.bodyFocusNotes}',
      'Daily calorie target: $target kcal (protein ${profile.effectiveProteinTarget}g)',
      '',
      'Last 7 days:',
      '- Workouts completed: $workoutDays / 7 days',
      '- Days logged food: ${daysTracked.length} / 7',
      '- Days inside ±15% of calorie target: ${daysHit.length} / ${daysTracked.length}',
    ];
    if (volume.isNotEmpty) {
      final top = volume.take(3).map((v) =>
          '${v.key} (${v.sets} sets, ${v.tonnageKg.round()} kg total)').join(', ');
      lines.add('- Top volume lifts: $top');
    }
    if (prs.isNotEmpty) {
      final recent = prs.values
          .where((p) => p.achievedAt.isAfter(weekAgo))
          .toList()
        ..sort((a, b) => b.estimated1RM.compareTo(a.estimated1RM));
      if (recent.isNotEmpty) {
        final pr = recent.first;
        lines.add(
            '- Best new PR: ${pr.exerciseName} ${pr.weightKg.toStringAsFixed(1)}kg x ${pr.reps}');
      }
    }
    if (plateaus.isNotEmpty) {
      final p = plateaus.first;
      lines.add(
          '- Plateau (${p.weeksStale} weeks): ${p.exerciseName} stuck at ${p.topWeightKg.toStringAsFixed(1)}kg x ${p.topReps}');
    }
    return lines.join('\n');
  }

  Future<void> _fetch() async {
    if (_loading) return;
    final profile = ref.read(profileStreamProvider).valueOrNull;
    final sessions =
        ref.read(allSessionsProvider).valueOrNull ?? const <WorkoutSession>[];
    final entries =
        ref.read(allFoodEntriesProvider).valueOrNull?.whereType<FoodEntry>().toList() ?? const <FoodEntry>[];
    if (profile == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final summary = _buildSummary(profile, sessions, entries);
      final ai = ref.read(aiServiceProvider);
      final text = await ai.weeklyReview(contextSummary: summary);
      await _saveCache(text);
      if (!mounted) return;
      setState(() {
        _text = text;
        _fetchedAt = DateTime.now();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  String _ageLabel() {
    if (_fetchedAt == null) return 'never';
    final age = DateTime.now().difference(_fetchedAt!);
    if (age.inMinutes < 60) return '${age.inMinutes} min ago';
    if (age.inHours < 24) return '${age.inHours} h ago';
    return '${age.inDays} d ago';
  }

  @override
  Widget build(BuildContext context) {
    final hasText = _text != null && _text!.isNotEmpty;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: hasText
            ? AppColors.accent.withValues(alpha: 0.07)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: hasText
                ? AppColors.accent.withValues(alpha: 0.4)
                : AppColors.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.insights_rounded,
                  size: 16,
                  color: hasText ? AppColors.accent : AppColors.textSecondary),
              const SizedBox(width: 8),
              Text('WEEKLY RECAP',
                  style: AppText.label.copyWith(
                      color:
                          hasText ? AppColors.accent : AppColors.textSecondary,
                      letterSpacing: 1.2)),
              const Spacer(),
              if (hasText)
                Text(_ageLabel(),
                    style: AppText.meta
                        .copyWith(fontSize: 11, color: AppColors.textTertiary)),
            ],
          ),
          const SizedBox(height: 10),
          if (hasText) ...[
            Text(_text!,
                style: AppText.body.copyWith(fontSize: 13.5, height: 1.45)),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _loading ? null : _fetch,
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  Icon(
                      _loading
                          ? Icons.hourglass_top_rounded
                          : Icons.refresh_rounded,
                      size: 14,
                      color: AppColors.accent),
                  const SizedBox(width: 6),
                  Text(
                    _loading
                        ? 'Refreshing…'
                        : (_isStale ? 'Refresh — it\'s been a week' : 'Refresh recap'),
                    style: AppText.label.copyWith(
                        color: AppColors.accent,
                        fontSize: 11.5,
                        letterSpacing: 0.6),
                  ),
                ],
              ),
            ),
          ] else ...[
            Text(
              _error != null
                  ? 'Couldn\'t reach the coach. Tap to retry.'
                  : 'Get a 3–5 sentence look back at your week — wins, plateaus, and one tweak.',
              style: AppText.body.copyWith(fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _loading ? null : _fetch,
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_loading)
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.onAccent),
                      )
                    else
                      Icon(Icons.auto_awesome_rounded,
                          size: 14, color: AppColors.onAccent),
                    const SizedBox(width: 8),
                    Text(_loading ? 'Asking…' : 'Get this week\'s recap',
                        style: TextStyle(
                          color: AppColors.onAccent,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          letterSpacing: 0.3,
                        )),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
