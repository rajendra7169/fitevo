import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/ai/ai_service.dart';
import '../services/coach/target_retune_advisor.dart';
import '../state/providers.dart';
import '../theme.dart';

/// Surface a calorie-target re-tune advisory once the user's weigh-in
/// trend has been off-goal for ≥14 days. AI writes the explanation,
/// Accept button writes a new `calorieOverride` to the profile.
class TargetRetuneCard extends ConsumerStatefulWidget {
  const TargetRetuneCard({super.key});

  @override
  ConsumerState<TargetRetuneCard> createState() =>
      _TargetRetuneCardState();
}

class _TargetRetuneCardState extends ConsumerState<TargetRetuneCard> {
  String? _advisoryText;
  bool _loading = false;
  bool _applying = false;
  String? _activeFingerprint;
  String? _errorFingerprint;

  static const _prefsTextKey = 'home.targetRetune.text';
  static const _prefsFpKey = 'home.targetRetune.fingerprint';
  static const _prefsDismissedFpKey = 'home.targetRetune.dismissedFp';

  Future<void> _evaluate() async {
    if (_loading) return;
    final profile = ref.read(profileStreamProvider).valueOrNull;
    final trend = ref.read(weightTrendProvider);
    if (profile == null) return;
    final check =
        TargetRetuneAdvisor.evaluate(profile: profile, trend: trend);
    if (!check.shouldShow) {
      if (_advisoryText != null) {
        setState(() => _advisoryText = null);
      }
      return;
    }
    if (check.fingerprint == _activeFingerprint && _advisoryText != null) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString(_prefsDismissedFpKey) == check.fingerprint) {
      // User dismissed this exact suggestion already — respect it
      // until the underlying data shifts enough to change the fp.
      return;
    }
    final cachedFp = prefs.getString(_prefsFpKey);
    final cachedText = prefs.getString(_prefsTextKey);
    if (cachedFp == check.fingerprint &&
        cachedText != null &&
        cachedText.isNotEmpty) {
      setState(() {
        _advisoryText = cachedText;
        _activeFingerprint = check.fingerprint;
      });
      return;
    }
    if (_errorFingerprint == check.fingerprint) return;

    setState(() => _loading = true);
    try {
      final ctx = TargetRetuneAdvisor.buildContext(
        profile: profile,
        check: check,
        trend: trend,
      );
      final ai = ref.read(aiServiceProvider);
      final reply = await ai.coachChat(
        userContext: ctx,
        history: const <CoachMessage>[],
        latestUserMessage: TargetRetuneAdvisor.userInstruction,
      );
      final trimmed = reply.trim();
      await prefs.setString(_prefsFpKey, check.fingerprint);
      await prefs.setString(_prefsTextKey, trimmed);
      if (mounted) {
        setState(() {
          _advisoryText = trimmed;
          _activeFingerprint = check.fingerprint;
        });
      }
    } catch (_) {
      _errorFingerprint = check.fingerprint;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _accept() async {
    if (_applying) return;
    final profile = ref.read(profileStreamProvider).valueOrNull;
    final trend = ref.read(weightTrendProvider);
    if (profile == null) return;
    final check =
        TargetRetuneAdvisor.evaluate(profile: profile, trend: trend);
    if (!check.shouldShow || check.suggestedKcalDelta == null) return;
    setState(() => _applying = true);
    try {
      final repo = ref.read(profileRepoProvider);
      final fresh = await repo.getCurrent();
      if (fresh == null) return;
      final base = fresh.calorieOverride ?? fresh.calorieTarget;
      final next =
          (base + check.suggestedKcalDelta!).clamp(1200, 6000);
      fresh.calorieOverride = next;
      await repo.save(fresh);
      // Clear cache so a fresh trajectory generates a fresh advisory
      // next time it's warranted.
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefsTextKey);
      await prefs.remove(_prefsFpKey);
      if (!mounted) return;
      setState(() {
        _advisoryText = null;
        _activeFingerprint = null;
      });
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(
          backgroundColor: AppColors.surfaceHigh,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          content: Text(
              'Calorie target updated to $next kcal/day.',
              style: AppText.body.copyWith(color: AppColors.textPrimary)),
        ));
    } finally {
      if (mounted) setState(() => _applying = false);
    }
  }

  Future<void> _dismiss() async {
    final fp = _activeFingerprint;
    if (fp == null) {
      setState(() => _advisoryText = null);
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsDismissedFpKey, fp);
    if (mounted) {
      setState(() => _advisoryText = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(profileStreamProvider);
    ref.watch(measurementsProvider);
    ref.watch(weightTrendProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) => _evaluate());

    final text = _advisoryText;
    if (text == null && !_loading) return const SizedBox.shrink();
    final profile = ref.watch(profileStreamProvider).valueOrNull;
    final trend = ref.watch(weightTrendProvider);
    final check = profile == null
        ? null
        : TargetRetuneAdvisor.evaluate(profile: profile, trend: trend);
    final delta = check?.suggestedKcalDelta;
    final newTarget = (profile != null && delta != null)
        ? (profile.effectiveCalorieTarget + delta).clamp(1200, 6000)
        : null;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.10),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tune_rounded,
                  size: 14, color: AppColors.accent),
              const SizedBox(width: 6),
              Text('CALORIE TARGET — RE-TUNE SUGGESTED',
                  style: AppText.label.copyWith(
                      fontSize: 10,
                      color: AppColors.accent,
                      letterSpacing: 0.8)),
              const Spacer(),
              IconButton(
                onPressed: _dismiss,
                icon: Icon(Icons.close_rounded,
                    size: 16, color: AppColors.textTertiary),
                tooltip: 'Dismiss',
              ),
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
                Text('Reading your 2-week trend…',
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
          if (newTarget != null && text != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceHigh,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Text('New target',
                            style: AppText.meta
                                .copyWith(fontSize: 11)),
                        const Spacer(),
                        Text(
                          '$newTarget kcal',
                          style: AppText.sectionTitle
                              .copyWith(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _applying ? null : _accept,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 11),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _applying
                        ? SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.onAccent),
                          )
                        : Text('Accept',
                            style: TextStyle(
                              color: AppColors.onAccent,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2,
                            )),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
