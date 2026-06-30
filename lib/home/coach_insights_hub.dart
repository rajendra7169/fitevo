import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/body_measurement.dart';
import '../data/models/daily_log.dart';
import '../data/models/food_entry.dart';
import '../data/models/profile.dart';
import '../data/models/workout_session.dart';
import '../services/coach/proactive_nudge.dart';
import '../services/coach/target_retune_advisor.dart';
import '../services/progress/streak_calc.dart';
import '../state/providers.dart';
import '../theme.dart';
import 'adaptive_nudge_card.dart';
import 'coach_context_nudge.dart';
import 'proactive_nudge_card.dart';
import 'target_retune_card.dart';
import 'weekly_recap_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// One container for every AI / coach insight card. Replaces the old
/// stack of four separately-rendered cards on the home screen so the
/// home doesn't turn into a wall of advisories.
///
/// Strategy:
///   - Compute which of the 4 underlying cards currently has content.
///   - Show ONE at a time (highest-priority first).
///   - Render a "1 of N" pill + left/right arrows so the user can
///     swipe through the others without losing the others on screen.
///   - Hide entirely when no card has content.
class CoachInsightsHub extends ConsumerStatefulWidget {
  const CoachInsightsHub({super.key});

  @override
  ConsumerState<CoachInsightsHub> createState() =>
      _CoachInsightsHubState();
}

enum _InsightKind { proactive, retune, weekly, context, adaptive }

class _CoachInsightsHubState extends ConsumerState<CoachInsightsHub> {
  int _currentIndex = 0;

  // Cached visibility decision so we don't rebuild ordering on every
  // page change. Refreshed on each build() call.
  List<_InsightKind> _activeOrdered = const [];

  // Weekly recap card's text is cached in SharedPreferences; we poll
  // it on init + after focus so the hub knows whether to surface the
  // recap as a page. Always shown when present — recaps are evergreen.
  bool _weeklyHasContent = false;

  @override
  void initState() {
    super.initState();
    _refreshWeeklyFlag();
  }

  Future<void> _refreshWeeklyFlag() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('weeklyRecap.lastText');
    if (!mounted) return;
    setState(() => _weeklyHasContent = cached != null && cached.isNotEmpty);
  }

  @override
  void dispose() {
    super.dispose();
  }

  /// Decide which of the four underlying cards currently has something
  /// worth showing. We replicate just enough of each card's logic to
  /// answer "would this render non-empty right now?" without actually
  /// mounting it. That keeps the hub deterministic and lets us order
  /// by priority.
  List<_InsightKind> _computeActive() {
    final profile = ref.read(profileStreamProvider).valueOrNull;
    if (profile == null) return const [];

    final foods = ref.read(allFoodEntriesProvider).valueOrNull ??
        const <FoodEntry>[];
    final logs = ref.read(allDailyLogsProvider).valueOrNull ??
        const <DailyLog>[];
    final sessions = ref.read(allSessionsProvider).valueOrNull ??
        const <WorkoutSession>[];
    final measurements = ref.read(measurementsProvider).valueOrNull ??
        const <BodyMeasurement>[];
    final trend = ref.read(weightTrendProvider);

    final now = DateTime.now();
    final since = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 6));
    final last7Foods =
        foods.where((f) => !f.timestamp.isBefore(since)).toList();
    final last7Logs = logs.where((l) {
      final p = DateTime.tryParse(l.dateKey);
      return p != null && !p.isBefore(since);
    }).toList();
    final last7Sessions =
        sessions.where((s) => !s.startedAt.isBefore(since)).toList();
    final streak = StreakCalc.currentStreak(
      foodEntries: foods,
      sessions: sessions,
      today: now,
    );

    // Proactive — same detection function the card uses.
    final triggers = ProactiveNudge.detect(
      profile: profile,
      last7Foods: last7Foods,
      last7Logs: last7Logs,
      last7Sessions: last7Sessions,
      measurements: measurements,
      weightTrend: trend,
      currentStreakDays: streak,
    );
    final proactiveActive = triggers.isNotEmpty;

    // Retune — same advisor function.
    final retuneCheck =
        TargetRetuneAdvisor.evaluate(profile: profile, trend: trend);
    final retuneActive = retuneCheck.shouldShow;

    // Adaptive — has content when there's a non-trivial kcal delta OR
    // when the user is in the "log more weigh-ins" warmup state.
    // Lightweight check matches AdaptiveNudgeCard's render conditions.
    final adaptiveActive = measurements.isNotEmpty || profile.goal.name != '';

    // Coach context — depends on missing profile fields + dismissal.
    final missingCount = _coachContextMissingCount(profile);
    final contextActive = missingCount >= 2;

    final active = <_InsightKind>[];
    if (proactiveActive) active.add(_InsightKind.proactive);
    if (retuneActive) active.add(_InsightKind.retune);
    if (_weeklyHasContent) active.add(_InsightKind.weekly);
    if (contextActive) active.add(_InsightKind.context);
    if (adaptiveActive) active.add(_InsightKind.adaptive);
    return active;
  }

  /// Mirror of the missing-field check inside CoachContextNudge —
  /// duplicating to avoid lifting state out of that widget.
  int _coachContextMissingCount(Profile profile) {
    int n = 0;
    if (profile.bodyFatPct == null) n++;
    if (profile.restDays.isEmpty) n++;
    if (profile.goesGym && profile.gymStartDate == null) n++;
    if (profile.weighInCadence.name == 'weekly' &&
        profile.weighInWeekday == null) {
      n++;
    }
    return n;
  }

  Widget _buildPage(_InsightKind kind) {
    switch (kind) {
      case _InsightKind.proactive:
        return const ProactiveNudgeCard();
      case _InsightKind.retune:
        return const TargetRetuneCard();
      case _InsightKind.weekly:
        return const WeeklyRecapCard();
      case _InsightKind.adaptive:
        return const AdaptiveNudgeCard();
      case _InsightKind.context:
        return const CoachContextNudge();
    }
  }

  String _labelFor(_InsightKind kind) {
    switch (kind) {
      case _InsightKind.proactive:
        return 'COACH NOTICED';
      case _InsightKind.retune:
        return 'CALORIE TARGET';
      case _InsightKind.weekly:
        return 'WEEKLY RECAP';
      case _InsightKind.adaptive:
        return 'WEEKLY TUNE';
      case _InsightKind.context:
        return 'MISSING DETAILS';
    }
  }

  void _go(int delta) {
    final total = _activeOrdered.length;
    if (total == 0) return;
    final next = (_currentIndex + delta).clamp(0, total - 1);
    if (next == _currentIndex) return;
    setState(() => _currentIndex = next);
  }

  @override
  Widget build(BuildContext context) {
    // Force re-evaluation when any underlying state shifts. Each
    // watch causes the hub to recompute its active list.
    ref.watch(profileStreamProvider);
    ref.watch(allFoodEntriesProvider);
    ref.watch(allDailyLogsProvider);
    ref.watch(allSessionsProvider);
    ref.watch(measurementsProvider);
    ref.watch(weightTrendProvider);

    _activeOrdered = _computeActive();
    if (_activeOrdered.isEmpty) {
      // Keep the hub silent when nobody has anything to say.
      return const SizedBox.shrink();
    }
    if (_currentIndex >= _activeOrdered.length) {
      _currentIndex = 0;
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header — section label + pagination chip
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 8, 6),
            child: Row(
              children: [
                Icon(Icons.auto_awesome_rounded,
                    size: 14, color: AppColors.accent),
                const SizedBox(width: 6),
                Text(
                  _labelFor(_activeOrdered[_currentIndex]),
                  style: AppText.label.copyWith(
                      fontSize: 10,
                      color: AppColors.accent,
                      letterSpacing: 0.8),
                ),
                const Spacer(),
                if (_activeOrdered.length > 1) ...[
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _go(-1),
                    child: Icon(
                      Icons.chevron_left_rounded,
                      size: 22,
                      color: _currentIndex == 0
                          ? AppColors.textTertiary
                              .withValues(alpha: 0.4)
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceHigh,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_currentIndex + 1} / ${_activeOrdered.length}',
                      style: AppText.meta.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _go(1),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      size: 22,
                      color: _currentIndex >= _activeOrdered.length - 1
                          ? AppColors.textTertiary
                              .withValues(alpha: 0.4)
                          : AppColors.textPrimary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Page body — each insight renders at its NATURAL height
          // (some are short, weekly recap is tall). AnimatedSize +
          // AnimatedSwitcher cross-fades between them and smoothly
          // animates the container height so nothing ever clips.
          //
          // Wrapped in GestureDetector for horizontal swipe — same
          // semantics as the old PageView, just without the rigid
          // height constraint that was cutting the proactive nudge.
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragEnd: (d) {
              if (_activeOrdered.length < 2) return;
              final v = d.primaryVelocity ?? 0;
              if (v < -200) _go(1);
              if (v > 200) _go(-1);
            },
            child: AnimatedSize(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.05, 0),
                        end: Offset.zero,
                      ).animate(anim),
                      child: child,
                    ),
                  ),
                  child: KeyedSubtree(
                    // The key change is what fires the switcher — each
                    // active insight gets a stable key based on its
                    // kind so the same page coming back doesn't
                    // re-animate spuriously.
                    key: ValueKey(_activeOrdered[_currentIndex].name),
                    child: _buildPage(_activeOrdered[_currentIndex]),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 280.ms);
  }
}

