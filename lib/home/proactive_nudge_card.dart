import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/body_measurement.dart';
import '../data/models/daily_log.dart';
import '../data/models/food_entry.dart';
import '../data/models/workout_session.dart';
import '../services/ai/ai_service.dart';
import '../services/coach/proactive_nudge.dart';
import '../services/progress/streak_calc.dart';
import '../state/providers.dart';
import '../theme.dart';

/// "Coach noticed…" card. Surfaces ONE AI-written observation when
/// something notable just happened — PR, skipped workouts, big over
/// streak, weight trend misalignment, dropped streak. Caches the AI
/// reply by trigger fingerprint so it doesn't burn a fresh call on
/// every rebuild — re-evaluates when the underlying state changes.
class ProactiveNudgeCard extends ConsumerStatefulWidget {
  const ProactiveNudgeCard({super.key});

  @override
  ConsumerState<ProactiveNudgeCard> createState() =>
      _ProactiveNudgeCardState();
}

class _ProactiveNudgeCardState extends ConsumerState<ProactiveNudgeCard> {
  String? _nudge;
  bool _loading = false;
  String? _activeFingerprint;
  String? _lastErrorFingerprint;

  static const _prefsTextKey = 'home.proactiveNudge.text';
  static const _prefsFpKey = 'home.proactiveNudge.fingerprint';

  Future<void> _evaluate() async {
    if (_loading) return;
    final profile = ref.read(profileStreamProvider).valueOrNull;
    if (profile == null) return;
    final foods =
        ref.read(allFoodEntriesProvider).valueOrNull ?? const <FoodEntry>[];
    final logs =
        ref.read(allDailyLogsProvider).valueOrNull ?? const <DailyLog>[];
    final sessions = ref.read(allSessionsProvider).valueOrNull ??
        const <WorkoutSession>[];
    final measurements = ref.read(measurementsProvider).valueOrNull ??
        const <BodyMeasurement>[];

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

    final trend = ref.read(weightTrendProvider);
    final streak = StreakCalc.currentStreak(
      foodEntries: foods,
      sessions: sessions,
      today: now,
    );

    final triggers = ProactiveNudge.detect(
      profile: profile,
      last7Foods: last7Foods,
      last7Logs: last7Logs,
      last7Sessions: last7Sessions,
      measurements: measurements,
      weightTrend: trend,
      currentStreakDays: streak,
    );

    if (triggers.isEmpty) {
      if (mounted) setState(() => _nudge = null);
      return;
    }

    final fp = ProactiveNudge.fingerprint(triggers, now);
    if (fp == _activeFingerprint && _nudge != null) return;

    // Check disk cache for the same fingerprint to avoid re-asking
    // the AI on every cold start when nothing has actually changed.
    final prefs = await SharedPreferences.getInstance();
    final cachedFp = prefs.getString(_prefsFpKey);
    final cachedText = prefs.getString(_prefsTextKey);
    if (cachedFp == fp && cachedText != null && cachedText.isNotEmpty) {
      if (mounted) {
        setState(() {
          _nudge = cachedText;
          _activeFingerprint = fp;
        });
      }
      return;
    }
    if (_lastErrorFingerprint == fp) return; // back off on repeated errors

    setState(() => _loading = true);
    try {
      final ctx = ProactiveNudge.buildContext(
        profile: profile,
        triggers: triggers,
        trend: trend,
      );
      final ai = ref.read(aiServiceProvider);
      final text = await ai.coachChat(
        userContext: ctx,
        history: const <CoachMessage>[],
        latestUserMessage: ProactiveNudge.userInstruction,
      );
      final trimmed = text.trim();
      await prefs.setString(_prefsFpKey, fp);
      await prefs.setString(_prefsTextKey, trimmed);
      if (mounted) {
        setState(() {
          _nudge = trimmed;
          _activeFingerprint = fp;
        });
      }
    } catch (_) {
      // Silent fail — card just doesn't render. Track fingerprint so
      // we don't hammer the AI on every rebuild after a failure.
      _lastErrorFingerprint = fp;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _dismiss() {
    setState(() => _nudge = null);
  }

  @override
  Widget build(BuildContext context) {
    // Re-evaluate whenever the underlying data changes. ref.listen would
    // be cleaner but the watch + post-frame pattern is fine here since
    // _evaluate dedupes by fingerprint.
    ref.watch(allFoodEntriesProvider);
    ref.watch(allDailyLogsProvider);
    ref.watch(allSessionsProvider);
    ref.watch(measurementsProvider);
    ref.watch(weightTrendProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) => _evaluate());

    final text = _nudge;
    if (text == null && !_loading) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(Icons.auto_awesome_rounded,
                size: 16, color: AppColors.accent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('COACH NOTICED',
                        style: AppText.label.copyWith(
                            color: AppColors.accent,
                            fontSize: 10,
                            letterSpacing: 0.8)),
                    const Spacer(),
                  ],
                ),
                const SizedBox(height: 4),
                if (_loading && text == null)
                  Row(
                    children: [
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.accent),
                      ),
                      const SizedBox(width: 8),
                      Text('Reading your week…',
                          style: AppText.body.copyWith(fontSize: 13)),
                    ],
                  )
                else
                  Text(
                    text ?? '',
                    style: AppText.body.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: 13.5,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ).animate().fadeIn(duration: 280.ms),
              ],
            ),
          ),
          if (text != null)
            IconButton(
              onPressed: _dismiss,
              icon: Icon(Icons.close_rounded,
                  size: 16, color: AppColors.textTertiary),
              tooltip: 'Dismiss',
            ),
        ],
      ),
    );
  }
}

// Suppress unused import for jsonEncode/Decode if we add cache versioning later.
// ignore: unused_element
String _unused() => jsonEncode({});
