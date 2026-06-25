import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/models/food_entry.dart';
import '../../state/providers.dart';
import '../../theme.dart';

class MealActionsSheet extends ConsumerStatefulWidget {
  final FoodEntry entry;
  const MealActionsSheet({super.key, required this.entry});

  static Future<void> show(BuildContext context, FoodEntry entry) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (_) => MealActionsSheet(entry: entry),
    );
  }

  @override
  ConsumerState<MealActionsSheet> createState() => _MealActionsSheetState();
}

class _MealActionsSheetState extends ConsumerState<MealActionsSheet> {
  double _scale = 1.0;
  bool _busy = false;
  late bool _favorite;

  static const _scales = [0.5, 1.0, 1.5, 2.0];

  @override
  void initState() {
    super.initState();
    _favorite = widget.entry.isFavorite;
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        backgroundColor: AppColors.surfaceHigh,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        content: Text(msg,
            style: AppText.body.copyWith(color: AppColors.textPrimary)),
      ));
  }

  Future<void> _relog() async {
    setState(() => _busy = true);
    try {
      final repo = ref.read(nutritionRepoProvider);
      final newEntry = await repo.relogScaled(widget.entry, _scale);
      if (!mounted) return;
      Navigator.of(context).pop();
      _toast('Logged · ${newEntry.calories} kcal');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _toggleFavorite() async {
    setState(() => _favorite = !_favorite);
    try {
      await ref.read(nutritionRepoProvider).toggleFavorite(widget.entry.id);
    } catch (_) {
      if (mounted) setState(() => _favorite = !_favorite);
    }
  }

  Future<void> _delete() async {
    final ok = await _confirmDelete();
    if (!ok) return;
    try {
      await ref.read(nutritionRepoProvider).deleteFoodEntry(widget.entry.id);
      if (!mounted) return;
      Navigator.of(context).pop();
      _toast('Removed.');
    } catch (_) {
      if (mounted) _toast('Could not delete.');
    }
  }

  Future<bool> _confirmDelete() async {
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Remove this meal?',
                  style: AppText.sectionTitle.copyWith(fontSize: 17)),
              const SizedBox(height: 6),
              Text('It\'ll come out of today\'s totals.',
                  style: AppText.body),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: Text('Cancel',
                        style: AppText.body
                            .copyWith(color: AppColors.textPrimary)),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: Text(
                      'Remove',
                      style: AppText.body.copyWith(
                        color: AppColors.danger,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    return res ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.entry;
    final time = DateFormat('h:mm a').format(e.timestamp);
    final scaledCal = (e.calories * _scale).round();
    final scaledProtein = (e.proteinG * _scale).round();
    final scaledCarbs = (e.carbsG * _scale).round();
    final scaledFat = (e.fatG * _scale).round();
    final title = e.description.isEmpty ? e.rawInput : e.description;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.stroke,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.sectionTitle),
                      const SizedBox(height: 4),
                      Text(
                          '${e.quantity.isEmpty ? '1 serving' : e.quantity} · logged $time',
                          style: AppText.meta),
                    ],
                  ),
                ),
                _IconButton(
                  icon: _favorite ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: _favorite ? AppColors.streak : AppColors.textPrimary,
                  onTap: _toggleFavorite,
                ),
                const SizedBox(width: 8),
                _IconButton(
                  icon: Icons.delete_outline_rounded,
                  color: AppColors.danger,
                  onTap: _delete,
                ),
              ],
            ),
            const SizedBox(height: 22),
            Text('PORTION', style: AppText.label),
            const SizedBox(height: 10),
            Row(
              children: [
                for (final s in _scales) ...[
                  Expanded(
                    child: _ScaleChip(
                      label: s == s.roundToDouble()
                          ? '${s.toInt()}×'
                          : '${s.toStringAsFixed(1)}×',
                      selected: _scale == s,
                      onTap: () => setState(() => _scale = s),
                    ),
                  ),
                  if (s != _scales.last) const SizedBox(width: 8),
                ],
              ],
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceHigh,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.stroke),
              ),
              child: Row(
                children: [
                  _Stat(label: 'kcal', value: '$scaledCal'),
                  _Divider(),
                  _Stat(
                      label: 'P',
                      value: '${scaledProtein}g',
                      color: AppColors.protein),
                  _Divider(),
                  _Stat(
                      label: 'C',
                      value: '${scaledCarbs}g',
                      color: AppColors.carbs),
                  _Divider(),
                  _Stat(
                      label: 'F',
                      value: '${scaledFat}g',
                      color: AppColors.fat),
                ],
              ),
            ),
            const SizedBox(height: 18),
            GestureDetector(
              onTap: _busy ? null : _relog,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 54,
                decoration: BoxDecoration(
                  color: _busy
                      ? AppColors.accent.withValues(alpha: 0.5)
                      : AppColors.accent,
                  borderRadius: BorderRadius.circular(18),
                ),
                alignment: Alignment.center,
                child: _busy
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.4, color: Colors.black),
                      )
                    : Text(
                        'Log again',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _IconButton(
      {required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.surfaceHigh,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.stroke),
        ),
        child: Icon(icon, size: 20, color: color),
      ),
    );
  }
}

class _ScaleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ScaleChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 44,
        decoration: BoxDecoration(
          color: selected ? AppColors.accent : AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.accent : AppColors.stroke,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.black : AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 14,
            letterSpacing: -0.2,
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  const _Stat({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: AppText.bigNumber.copyWith(
                fontSize: 17,
                color: color ?? AppColors.textPrimary,
              )),
          const SizedBox(height: 2),
          Text(label,
              style: AppText.meta.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textTertiary)),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 26,
      color: AppColors.stroke,
    );
  }
}
