import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/daily_log.dart';
import '../data/models/profile.dart';
import '../state/providers.dart';
import '../theme.dart';

/// Compact dashboard card that prompts the user to log today's actual
/// walking / running so the day's calorie target reflects the real burn.
class TodaysActivityCard extends ConsumerWidget {
  final Profile profile;
  const TodaysActivityCard({super.key, required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final log = ref.watch(todayLogProvider).valueOrNull;
    final wKm = log?.walkingKmToday ?? 0;
    final rKm = log?.runningKmToday ?? 0;
    final hasLog = wKm > 0 || rKm > 0;
    final kcalBonus = TodaysActivityMath.bonusKcal(
      profile: profile,
      walkingKmToday: wKm,
      runningKmToday: rKm,
      otherCardioMinutes: log?.otherCardioMinutes ?? 0,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: hasLog
            ? AppColors.accent.withValues(alpha: 0.07)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: hasLog
                ? AppColors.accent.withValues(alpha: 0.35)
                : AppColors.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                  hasLog
                      ? Icons.directions_run_rounded
                      : Icons.add_road_rounded,
                  size: 18,
                  color: AppColors.accent),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  hasLog
                      ? 'Today\'s activity'
                      : 'Running or walking today? Let us know.',
                  style: AppText.body.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5),
                ),
              ),
              GestureDetector(
                onTap: () => _openSheet(context, ref, log),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(hasLog ? 'Update' : 'Log',
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        letterSpacing: 0.2,
                      )),
                ),
              ),
            ],
          ),
          if (hasLog) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 14,
              runSpacing: 4,
              children: [
                if (wKm > 0)
                  Text('🚶 ${wKm.toStringAsFixed(1)} km walking',
                      style: AppText.body.copyWith(fontSize: 12.5)),
                if (rKm > 0)
                  Text('🏃 ${rKm.toStringAsFixed(1)} km running',
                      style: AppText.body.copyWith(fontSize: 12.5)),
                Text('+$kcalBonus kcal today',
                    style: AppText.body.copyWith(
                        fontSize: 12.5,
                        color: AppColors.accent,
                        fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 8),
            Text(_tipFor(rKm + wKm * 0.4),
                style:
                    AppText.meta.copyWith(fontSize: 11.5, height: 1.35)),
          ],
        ],
      ),
    );
  }

  Future<void> _openSheet(
      BuildContext context, WidgetRef ref, DailyLog? log) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.bg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => _ActivityLogSheet(initial: log),
    );
  }

  static String _tipFor(double effortKm) {
    if (effortKm <= 0) return '';
    if (effortKm < 3) {
      return 'Tip: an extra 250 ml of water and a small carb snack will help recovery.';
    }
    if (effortKm < 6) {
      return 'Tip: +500 ml water today and a protein-rich meal within ~2 hours.';
    }
    return 'Tip: +750 ml water + electrolytes. Carbs within 60 min speeds recovery and protein synthesis.';
  }
}

class _ActivityLogSheet extends ConsumerStatefulWidget {
  final DailyLog? initial;
  const _ActivityLogSheet({required this.initial});

  @override
  ConsumerState<_ActivityLogSheet> createState() => _ActivityLogSheetState();
}

class _ActivityLogSheetState extends ConsumerState<_ActivityLogSheet> {
  late final TextEditingController _walking;
  late final TextEditingController _running;
  late final TextEditingController _otherMin;
  late final TextEditingController _sleepHrs;
  late final TextEditingController _note;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _walking = TextEditingController(
      text: (widget.initial?.walkingKmToday ?? 0) > 0
          ? widget.initial!.walkingKmToday.toStringAsFixed(1)
          : '',
    );
    _running = TextEditingController(
      text: (widget.initial?.runningKmToday ?? 0) > 0
          ? widget.initial!.runningKmToday.toStringAsFixed(1)
          : '',
    );
    _otherMin = TextEditingController(
      text: (widget.initial?.otherCardioMinutes ?? 0) > 0
          ? '${widget.initial!.otherCardioMinutes}'
          : '',
    );
    final sleepMin = widget.initial?.sleepMinutes;
    _sleepHrs = TextEditingController(
      text: (sleepMin != null && sleepMin > 0)
          ? (sleepMin / 60).toStringAsFixed(1)
          : '',
    );
    _note = TextEditingController(text: widget.initial?.activityNote ?? '');
  }

  @override
  void dispose() {
    _walking.dispose();
    _running.dispose();
    _otherMin.dispose();
    _sleepHrs.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final repo = ref.read(nutritionRepoProvider);
      final sleepHrs = double.tryParse(_sleepHrs.text.trim()) ?? 0;
      await repo.upsertDailyLog(
        ref.read(todayProvider),
        walkingKmToday: double.tryParse(_walking.text.trim()) ?? 0,
        runningKmToday: double.tryParse(_running.text.trim()) ?? 0,
        otherCardioMinutes: int.tryParse(_otherMin.text.trim()) ?? 0,
        sleepMinutes: sleepHrs > 0 ? (sleepHrs * 60).round() : null,
        activityNote: _note.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 18, 20, 20 + pad),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: AppColors.surfaceHigh,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Text('Log today\'s activity', style: AppText.sectionTitle),
          const SizedBox(height: 6),
          Text(
              'These numbers bump today\'s calorie ring up — only for today. Tomorrow resets.',
              style: AppText.body.copyWith(fontSize: 12.5)),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _SheetField(
                  label: 'WALKING (KM)',
                  controller: _walking,
                  hint: 'e.g. 4',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SheetField(
                  label: 'RUNNING (KM)',
                  controller: _running,
                  hint: 'e.g. 5',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _SheetField(
                  label: 'OTHER CARDIO (MIN)',
                  controller: _otherMin,
                  hint: 'cycling, swim, HIIT…',
                  digits: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SheetField(
                  label: 'SLEEP LAST NIGHT (HRS)',
                  controller: _sleepHrs,
                  hint: 'e.g. 7.5',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _SheetField(
            label: 'NOTE',
            controller: _note,
            hint: 'felt strong / easy pace / sore knee…',
            digits: false,
          ),
          const SizedBox(height: 18),
          GestureDetector(
            onTap: _saving ? null : _save,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 50,
              decoration: BoxDecoration(
                color: _saving
                    ? AppColors.accent.withValues(alpha: 0.5)
                    : AppColors.accent,
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.black),
                    )
                  : const Text(
                      'Save & bump my calories',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final bool digits;
  const _SheetField({
    required this.label,
    required this.controller,
    required this.hint,
    this.digits = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.label.copyWith(fontSize: 10)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.stroke),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: TextField(
            controller: controller,
            cursorColor: AppColors.accent,
            keyboardType: digits
                ? const TextInputType.numberWithOptions(decimal: true)
                : TextInputType.text,
            style: AppText.body
                .copyWith(color: AppColors.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              border: InputBorder.none,
              isCollapsed: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              hintText: hint,
              hintStyle: AppText.body
                  .copyWith(color: AppColors.textTertiary, fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }
}

/// Math helpers for today's activity → calorie bonus.
class TodaysActivityMath {
  /// Average baseline burn already baked into the user's daily target.
  /// We only credit today for activity *beyond* that average, since the
  /// weekly target already assumes the average.
  static int bonusKcal({
    required Profile profile,
    required double walkingKmToday,
    required double runningKmToday,
    required int otherCardioMinutes,
  }) {
    final wScale = profile.weightKg / 70.0;
    // Above-average walking earns extra kcal.
    final extraWalk = (walkingKmToday - profile.walkingKmPerDay)
        .clamp(0, 30) * 50 * wScale;
    final avgRunPerDay = profile.runningKmPerWeek / 7.0;
    final extraRun =
        (runningKmToday - avgRunPerDay).clamp(0, 50) * 70 * wScale;
    // Generic cardio at ~9 kcal/min for a moderate session.
    final extraOther = otherCardioMinutes.clamp(0, 240) * 9.0 * wScale;
    return (extraWalk + extraRun + extraOther).round();
  }

  /// Effective today's calorie target = profile-derived target +
  /// today's bonus + sleep-debt softener. Used by the calorie ring.
  static int effectiveTodayCalorieTarget({
    required Profile profile,
    required DailyLog? log,
  }) {
    final base = profile.effectiveCalorieTarget;
    if (log == null) return base;
    final bonus = bonusKcal(
      profile: profile,
      walkingKmToday: log.walkingKmToday,
      runningKmToday: log.runningKmToday,
      otherCardioMinutes: log.otherCardioMinutes,
    );
    return base + bonus + sleepDebtSoftener(log.sleepMinutes);
  }

  /// When the user logs < 7h sleep, deficits hurt recovery harder. Add
  /// 50 kcal back for every 30-min shortfall below 7h, capped at 150.
  /// Returns 0 when sleep is null or >= 7h.
  static int sleepDebtSoftener(int? sleepMinutes) {
    if (sleepMinutes == null || sleepMinutes <= 0) return 0;
    final shortfall = (7 * 60) - sleepMinutes;
    if (shortfall <= 0) return 0;
    final units = (shortfall / 30).ceil();
    return (units * 50).clamp(0, 150);
  }

  /// Split today's bonus kcal across macros: carbs take 70% (running
  /// uses glycogen), protein 20% (recovery), fat 10%. Returns the
  /// per-macro grams *added* to the base profile target.
  static ({int proteinG, int carbG, int fatG}) bonusMacros({
    required Profile profile,
    required DailyLog? log,
  }) {
    if (log == null) return (proteinG: 0, carbG: 0, fatG: 0);
    final bonus = bonusKcal(
      profile: profile,
      walkingKmToday: log.walkingKmToday,
      runningKmToday: log.runningKmToday,
      otherCardioMinutes: log.otherCardioMinutes,
    );
    if (bonus <= 0) return (proteinG: 0, carbG: 0, fatG: 0);
    return (
      proteinG: (bonus * 0.20 / 4).round(),
      carbG: (bonus * 0.70 / 4).round(),
      fatG: (bonus * 0.10 / 9).round(),
    );
  }

  /// Convenience: effective macro targets for today.
  static ({int proteinG, int carbG, int fatG}) effectiveTodayMacros({
    required Profile profile,
    required DailyLog? log,
  }) {
    final extra = bonusMacros(profile: profile, log: log);
    return (
      proteinG: profile.effectiveProteinTarget + extra.proteinG,
      carbG: profile.effectiveCarbTarget + extra.carbG,
      fatG: profile.effectiveFatTarget + extra.fatG,
    );
  }
}
