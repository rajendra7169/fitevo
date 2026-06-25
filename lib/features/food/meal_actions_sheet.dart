import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/models/enums.dart';
import '../../data/models/food_entry.dart';
import '../../services/ai/ai_service.dart';
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
  // Local override so the UI reflects the new timestamp immediately
  // after editing, before the Isar stream catches up.
  DateTime? _timestampOverride;

  static const _scales = [0.5, 1.0, 1.5, 2.0];

  @override
  void initState() {
    super.initState();
    _favorite = widget.entry.isFavorite;
  }

  DateTime get _displayedTimestamp =>
      _timestampOverride ?? widget.entry.timestamp;

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

  /// Lets the user fix a timestamp they forgot to set at log time.
  /// Common case: AI-logged at 9pm but the food was actually eaten at
  /// 1pm. Only edits the time-of-day; the date stays on the original
  /// day the meal was logged.
  Future<void> _editTime() async {
    final initial = _displayedTimestamp;
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme.copyWith(
                primary: AppColors.accent,
                onPrimary: AppColors.onAccent,
                surface: AppColors.surface,
                onSurface: AppColors.textPrimary,
              ),
        ),
        child: child!,
      ),
    );
    if (pickedTime == null || !mounted) return;
    final newTs = DateTime(
      initial.year,
      initial.month,
      initial.day,
      pickedTime.hour,
      pickedTime.minute,
    );
    setState(() => _timestampOverride = newTs);
    try {
      await ref
          .read(nutritionRepoProvider)
          .updateFoodEntryTimestamp(widget.entry.id, newTs);
      if (mounted) _toast('Logged time updated.');
    } catch (_) {
      if (mounted) {
        setState(() => _timestampOverride = null);
        _toast('Could not update time.');
      }
    }
  }

  /// Lets the user add detail to an existing entry the AI wasn't sure
  /// about. Opens a small text dialog, re-prompts the AI with the
  /// original + the new detail, and (when the AI returns a confident
  /// estimate) overwrites this entry's nutrition fields in place.
  /// If the AI still wants to ask another clarifying question, we
  /// surface it and the user can extend their input again.
  Future<void> _refine() async {
    final initial = widget.entry.description.isEmpty
        ? widget.entry.rawInput
        : widget.entry.description;
    String? extra = await showDialog<String>(
      context: context,
      builder: (ctx) => _RefineDialog(initial: initial),
    );
    if (extra == null || extra.trim().isEmpty || !mounted) return;
    setState(() => _busy = true);
    try {
      final ai = ref.read(aiServiceProvider);
      final combined = '${widget.entry.rawInput.trim()}\n'
          'Additional detail: ${extra.trim()}';
      final analysis = await ai.analyzeFoodText(combined);
      if (!mounted) return;
      if (analysis.needsClarification) {
        _toast('AI: "${analysis.clarificationQuestion}" — try adding that too.');
        return;
      }
      if (analysis.items.isEmpty) {
        _toast('Still couldn\'t estimate. Try a more specific description.');
        return;
      }
      // Roll all items into one updated entry so the existing food row
      // stays a single entity.
      var totalCal = 0, totalP = 0, totalC = 0, totalF = 0;
      var totalFib = 0, totalNa = 0;
      var conf = EstimateConfidence.high;
      int? cLow, cHigh;
      for (final i in analysis.items) {
        totalCal += i.calories;
        totalP += i.proteinG;
        totalC += i.carbsG;
        totalF += i.fatG;
        totalFib += i.fiberG;
        totalNa += i.sodiumMg;
        // Take the worst confidence across items.
        if (i.confidence == EstimateConfidence.low ||
            conf == EstimateConfidence.low) {
          conf = EstimateConfidence.low;
        } else if (i.confidence == EstimateConfidence.medium &&
            conf != EstimateConfidence.low) {
          conf = EstimateConfidence.medium;
        }
        cLow = (cLow ?? 0) + (i.caloriesLow ?? i.calories);
        cHigh = (cHigh ?? 0) + (i.caloriesHigh ?? i.calories);
      }
      final updated = FoodEntry()
        ..description = analysis.items.map((i) => i.name).join(', ')
        ..quantity = analysis.items
            .map((i) => i.quantity)
            .where((q) => q.isNotEmpty)
            .join(' + ')
        ..calories = totalCal
        ..proteinG = totalP
        ..carbsG = totalC
        ..fatG = totalF
        ..fiberG = totalFib
        ..sodiumMg = totalNa
        ..confidence = conf
        ..caloriesLow = cLow
        ..caloriesHigh = cHigh;
      await ref
          .read(nutritionRepoProvider)
          .updateFoodEntryNutrition(widget.entry.id, updated);
      if (!mounted) return;
      Navigator.of(context).pop();
      _toast('Refined · $totalCal kcal');
    } on AiException catch (e) {
      if (mounted) _toast(e.message);
    } catch (_) {
      if (mounted) _toast('Could not refine.');
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
    final ts = _displayedTimestamp;
    final now = DateTime.now();
    final isToday = ts.year == now.year &&
        ts.month == now.month &&
        ts.day == now.day;
    final time = isToday
        ? DateFormat('h:mm a').format(ts)
        : DateFormat('MMM d · h:mm a').format(ts);
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
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            e.quantity.isEmpty ? '1 serving' : e.quantity,
                            style: AppText.meta,
                          ),
                          Text(' · ', style: AppText.meta),
                          // Tap-to-edit timestamp chip
                          GestureDetector(
                            onTap: _editTime,
                            behavior: HitTestBehavior.opaque,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.accent
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: AppColors.accent
                                        .withValues(alpha: 0.35)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.schedule_rounded,
                                      size: 11, color: AppColors.accent),
                                  const SizedBox(width: 4),
                                  Text(
                                    time,
                                    style: AppText.meta.copyWith(
                                      color: AppColors.accent,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(Icons.edit_rounded,
                                      size: 10, color: AppColors.accent),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _IconButton(
                  icon: Icons.auto_fix_high_rounded,
                  color: AppColors.accent,
                  onTap: _busy ? () {} : _refine,
                ),
                const SizedBox(width: 8),
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
                    ? SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.4, color: AppColors.onAccent),
                      )
                    : Text(
                        'Log again',
                        style: TextStyle(
                          color: AppColors.onAccent,
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
            color: selected ? AppColors.onAccent : AppColors.textPrimary,
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

/// Small dialog that captures extra detail to refine a low-confidence
/// food entry. Returns the user's typed text, or null on cancel.
class _RefineDialog extends StatefulWidget {
  final String initial;
  const _RefineDialog({required this.initial});

  @override
  State<_RefineDialog> createState() => _RefineDialogState();
}

class _RefineDialogState extends State<_RefineDialog> {
  late final TextEditingController _ctl;

  @override
  void initState() {
    super.initState();
    _ctl = TextEditingController();
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_fix_high_rounded,
                    size: 18, color: AppColors.accent),
                const SizedBox(width: 8),
                Text('Refine this entry',
                    style: AppText.sectionTitle.copyWith(fontSize: 17)),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Add the missing details so the AI can re-estimate this entry.',
              style: AppText.body.copyWith(fontSize: 13),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
              decoration: BoxDecoration(
                color: AppColors.surfaceHigh,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.initial,
                style: AppText.meta.copyWith(
                    fontSize: 12.5, color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceHigh,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.stroke),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: TextField(
                controller: _ctl,
                autofocus: true,
                minLines: 1,
                maxLines: 3,
                cursorColor: AppColors.accent,
                style: AppText.body.copyWith(
                    color: AppColors.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  isCollapsed: true,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 14),
                  hintText:
                      'e.g. 2 eggs, scrambled with butter, on toast',
                  hintStyle: AppText.body.copyWith(
                      color: AppColors.textTertiary, fontSize: 14),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancel',
                      style: AppText.body
                          .copyWith(color: AppColors.textPrimary)),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () =>
                      Navigator.of(context).pop(_ctl.text.trim()),
                  child: Text('Refine',
                      style: AppText.body.copyWith(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
