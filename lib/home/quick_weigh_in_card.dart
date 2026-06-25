import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/body_measurement.dart';
import '../state/providers.dart';
import '../theme.dart';

/// One-tap weight log on the dashboard. The point isn't a beautiful form
/// — it's removing every excuse not to log, so the adaptive engine has
/// data within a week of install.
class QuickWeighInCard extends ConsumerStatefulWidget {
  const QuickWeighInCard({super.key});

  @override
  ConsumerState<QuickWeighInCard> createState() => _QuickWeighInCardState();
}

class _QuickWeighInCardState extends ConsumerState<QuickWeighInCard> {
  bool _saving = false;
  DateTime? _lastLoggedAt;

  bool _isToday(DateTime d) {
    final n = DateTime.now();
    return d.year == n.year && d.month == n.month && d.day == n.day;
  }

  Future<void> _openSheet(double? lastWeight) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.bg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (_) => _WeighInSheet(initial: lastWeight, onSaved: (kg) async {
        setState(() {
          _saving = true;
        });
        final repo = ref.read(measurementRepoProvider);
        final m = BodyMeasurement()
          ..date = DateTime.now()
          ..weightKg = kg;
        await repo.save(m);
        if (!mounted) return;
        setState(() {
          _saving = false;
          _lastLoggedAt = DateTime.now();
        });
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(SnackBar(
            backgroundColor: AppColors.surfaceHigh,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            content: Text('${kg.toStringAsFixed(1)} kg logged.',
                style:
                    AppText.body.copyWith(color: AppColors.textPrimary)),
          ));
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ms = ref.watch(measurementsProvider).valueOrNull ??
        const <BodyMeasurement>[];
    BodyMeasurement? latest;
    for (final m in ms) {
      if (latest == null || m.date.isAfter(latest.date)) latest = m;
    }
    final loggedToday =
        latest != null && _isToday(latest.date) || (_lastLoggedAt != null);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: loggedToday
            ? AppColors.accent.withValues(alpha: 0.05)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: loggedToday
                ? AppColors.accent.withValues(alpha: 0.35)
                : AppColors.stroke),
      ),
      child: Row(
        children: [
          Icon(Icons.monitor_weight_rounded,
              size: 18,
              color: loggedToday ? AppColors.accent : AppColors.textPrimary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loggedToday
                      ? 'Weighed in today'
                      : 'Quick weigh-in',
                  style: AppText.body.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  loggedToday && latest != null
                      ? 'Latest: ${latest.weightKg.toStringAsFixed(1)} kg'
                      : 'Adaptive coach needs your weight to tune.',
                  style: AppText.meta.copyWith(fontSize: 11.5),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _saving ? null : () => _openSheet(latest?.weightKg),
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: loggedToday
                    ? AppColors.surfaceHigh
                    : AppColors.accent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                loggedToday ? 'Update' : 'Log',
                style: TextStyle(
                  color: loggedToday ? AppColors.textPrimary : AppColors.onAccent,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeighInSheet extends StatefulWidget {
  final double? initial;
  final Future<void> Function(double kg) onSaved;
  const _WeighInSheet({required this.initial, required this.onSaved});

  @override
  State<_WeighInSheet> createState() => _WeighInSheetState();
}

class _WeighInSheetState extends State<_WeighInSheet> {
  late final TextEditingController _ctl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _ctl = TextEditingController(
      text: widget.initial == null
          ? ''
          : widget.initial!.toStringAsFixed(1),
    );
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    final kg = double.tryParse(_ctl.text.trim());
    if (kg == null || kg < 20 || kg > 400) return;
    setState(() => _saving = true);
    try {
      await widget.onSaved(kg);
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
          Text('Today\'s weight', style: AppText.sectionTitle),
          const SizedBox(height: 6),
          Text(
              'Same time daily for the cleanest trend — morning, after bathroom.',
              style: AppText.body.copyWith(fontSize: 12.5)),
          const SizedBox(height: 18),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.stroke),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctl,
                    autofocus: true,
                    cursorColor: AppColors.accent,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    style: AppText.bigNumber.copyWith(fontSize: 28),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      isCollapsed: true,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 16),
                      hintText: '0.0',
                      hintStyle: AppText.bigNumber.copyWith(
                          color: AppColors.textTertiary, fontSize: 28),
                    ),
                  ),
                ),
                Text('kg',
                    style: AppText.meta.copyWith(
                        fontSize: 14, color: AppColors.textTertiary)),
              ],
            ),
          ),
          const SizedBox(height: 16),
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
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.onAccent),
                    )
                  : Text('Save',
                      style: TextStyle(
                        color: AppColors.onAccent,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      )),
            ),
          ),
        ],
      ),
    );
  }
}
