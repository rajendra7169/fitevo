import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/adaptive_targeting.dart';
import '../data/models/body_measurement.dart';
import '../state/providers.dart';
import '../theme.dart';

/// Compact dashboard card that surfaces the adaptive-targeting engine's
/// weekly nudge. Only renders something visible when there's an actual
/// suggestion or when the user needs to log more weight to enable it.
class AdaptiveNudgeCard extends ConsumerStatefulWidget {
  const AdaptiveNudgeCard({super.key});

  @override
  ConsumerState<AdaptiveNudgeCard> createState() =>
      _AdaptiveNudgeCardState();
}

class _AdaptiveNudgeCardState extends ConsumerState<AdaptiveNudgeCard> {
  bool _applying = false;

  Future<void> _applyNudge(int kcalDelta) async {
    if (_applying) return;
    setState(() => _applying = true);
    try {
      final repo = ref.read(profileRepoProvider);
      final profile = await repo.getCurrent();
      if (profile == null) return;
      final base = profile.calorieOverride ?? profile.calorieTarget;
      final next = (base + kcalDelta).clamp(1200, 6000);
      profile.calorieOverride = next;
      await repo.save(profile);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(
          backgroundColor: AppColors.surfaceHigh,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          content: Text(
              'Calorie target ${kcalDelta > 0 ? "+" : ""}$kcalDelta → $next kcal.',
              style: AppText.body.copyWith(color: AppColors.textPrimary)),
        ));
    } finally {
      if (mounted) setState(() => _applying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileStreamProvider).valueOrNull;
    final measurements =
        ref.watch(measurementsProvider).valueOrNull ?? const <BodyMeasurement>[];
    if (profile == null) return const SizedBox.shrink();
    final s =
        AdaptiveTargeting.suggest(profile: profile, measurements: measurements);

    final isAction = !s.isHold && s.kcalDelta != 0;
    final isWarmup = s.isHold && s.sampleSize < 4;
    final tone = isAction
        ? AppColors.accent
        : (isWarmup ? AppColors.accent : AppColors.textTertiary);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: isAction
            ? AppColors.accent.withValues(alpha: 0.07)
            : (isWarmup
                ? AppColors.accent.withValues(alpha: 0.05)
                : AppColors.surface),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: isAction || isWarmup
                ? AppColors.accent.withValues(alpha: 0.35)
                : AppColors.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                  isWarmup
                      ? Icons.auto_graph_rounded
                      : Icons.trending_flat_rounded,
                  size: 16,
                  color: tone),
              const SizedBox(width: 8),
              Text('ADAPTIVE TARGET',
                  style: AppText.label
                      .copyWith(color: tone, letterSpacing: 1.2)),
              const Spacer(),
              if (s.sampleSize >= 2)
                Text(
                  '${s.weightDeltaPerWeek >= 0 ? "+" : ""}${s.weightDeltaPerWeek.toStringAsFixed(2)} kg/wk',
                  style: AppText.meta.copyWith(
                      fontSize: 11, color: AppColors.textTertiary),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (isWarmup)
            Text(
              'After 2 weeks of weigh-ins, this target stops being a guess. Log weight now — the coach takes over from here.',
              style: AppText.body.copyWith(
                fontSize: 13,
                height: 1.4,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            )
          else
            Text(s.reason,
                style: AppText.body.copyWith(fontSize: 13, height: 1.4)),
          if (isAction) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _applying ? null : () => _applyNudge(s.kcalDelta),
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_applying)
                      const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.black),
                      )
                    else
                      const Icon(Icons.check_rounded,
                          size: 14, color: Colors.black),
                    const SizedBox(width: 6),
                    Text(
                      _applying
                          ? 'Applying…'
                          : 'Apply ${s.kcalDelta > 0 ? "+" : ""}${s.kcalDelta} kcal',
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        letterSpacing: 0.2,
                      ),
                    ),
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
