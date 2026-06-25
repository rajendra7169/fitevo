import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/models/enums.dart';
import '../../data/models/food_entry.dart';
import '../../data/models/profile.dart';
import '../../data/repositories/nutrition_repo.dart';
import '../../state/providers.dart';
import '../../theme.dart';
import 'meal_actions_sheet.dart';

class TodaysFoodPage extends ConsumerWidget {
  const TodaysFoodPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileStreamProvider);
    final entriesAsync = ref.watch(todayEntriesProvider);
    final totals = ref.watch(todayTotalsProvider);
    final dateLabel = DateFormat('EEEE, MMM d').format(DateTime.now());

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Today', style: AppText.sectionTitle),
            Text(dateLabel,
                style: AppText.meta.copyWith(fontSize: 11)),
          ],
        ),
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      body: profileAsync.when(
        loading: () => _busy(),
        error: (_, _) => _busy(),
        data: (profile) {
          if (profile == null) return _busy();
          return entriesAsync.when(
            loading: () => _busy(),
            error: (_, _) => _busy(),
            data: (entries) => SafeArea(
              child: CustomScrollView(
                physics: const ClampingScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    sliver: SliverList.list(children: [
                      _SummaryCard(profile: profile, totals: totals)
                          .animate()
                          .fadeIn(duration: 300.ms)
                          .slideY(begin: 0.06, end: 0),
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          Expanded(
                              child: Text('FOOD LOGGED', style: AppText.label)),
                          Text(
                              '${entries.length} ${entries.length == 1 ? 'entry' : 'entries'}',
                              style: AppText.label.copyWith(
                                  color: AppColors.textTertiary,
                                  letterSpacing: 0.6)),
                        ],
                      ).animate(delay: 120.ms).fadeIn(duration: 280.ms),
                      const SizedBox(height: 10),
                    ]),
                  ),
                  if (entries.isEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                      sliver: SliverList.list(children: [
                        _EmptyState()
                            .animate(delay: 160.ms)
                            .fadeIn(duration: 350.ms)
                            .scale(
                                begin: const Offset(0.95, 0.95),
                                end: const Offset(1, 1)),
                      ]),
                    )
                  else
                    () {
                      final groups = _groupEntries(entries);
                      return SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                        sliver: SliverList.builder(
                          itemCount: groups.length,
                          itemBuilder: (ctx, i) {
                            final g = groups[i];
                            // Wrap each card in a Dismissible so the user
                            // can swipe right→left to delete an accidental
                            // entry quickly. Undo is offered via SnackBar.
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _SwipeToDelete(
                                entries: g,
                                child: g.length == 1
                                    ? _FoodEntryCard(entry: g.first)
                                    : _MealGroupCard(entries: g),
                              )
                                  .animate(
                                      delay: Duration(
                                          milliseconds: 140 + i * 50))
                                  .fadeIn(duration: 280.ms)
                                  .slideY(begin: 0.06, end: 0),
                            );
                          },
                        ),
                      );
                    }(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _busy() => Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
              strokeWidth: 2.2, color: AppColors.accent),
        ),
      );
}

/// Groups entries that share the same rawInput AND were logged within ~2
/// minutes — i.e. the AI split a single meal into multiple items.
List<List<FoodEntry>> _groupEntries(List<FoodEntry> entries) {
  if (entries.isEmpty) return const [];
  final groups = <List<FoodEntry>>[];
  for (final e in entries) {
    if (groups.isNotEmpty) {
      final last = groups.last.last;
      final sameInput = last.rawInput.isNotEmpty &&
          last.rawInput == e.rawInput &&
          e.source != FoodSource.custom;
      final closeInTime =
          last.timestamp.difference(e.timestamp).abs() <
              const Duration(minutes: 2);
      if (sameInput && closeInTime) {
        groups.last.add(e);
        continue;
      }
    }
    groups.add([e]);
  }
  return groups;
}

class _MealGroupCard extends ConsumerStatefulWidget {
  final List<FoodEntry> entries;
  const _MealGroupCard({required this.entries});

  @override
  ConsumerState<_MealGroupCard> createState() => _MealGroupCardState();
}

class _MealGroupCardState extends ConsumerState<_MealGroupCard> {
  bool _expanded = true;
  // Local override so the timestamp updates instantly after editing,
  // before the Isar stream rebuilds the parent list.
  DateTime? _tsOverride;

  Future<void> _editGroupTime() async {
    final initial = _tsOverride ?? widget.entries.first.timestamp;
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
    // Keep the entry on its original date — only the time changes.
    final newTs = DateTime(
      initial.year,
      initial.month,
      initial.day,
      pickedTime.hour,
      pickedTime.minute,
    );
    setState(() => _tsOverride = newTs);
    try {
      final ids = widget.entries.map((e) => e.id).toList();
      await ref
          .read(nutritionRepoProvider)
          .updateFoodEntriesTimestamp(ids, newTs);
    } catch (_) {
      if (mounted) setState(() => _tsOverride = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final entries = widget.entries;
    final displayedTs = _tsOverride ?? entries.first.timestamp;
    final now = DateTime.now();
    final isToday = displayedTs.year == now.year &&
        displayedTs.month == now.month &&
        displayedTs.day == now.day;
    final time = isToday
        ? DateFormat('h:mm a').format(displayedTs)
        : DateFormat('MMM d · h:mm a').format(displayedTs);
    final totalKcal = entries.fold<int>(0, (s, e) => s + e.calories);
    final totalP = entries.fold<int>(0, (s, e) => s + e.proteinG);
    final totalC = entries.fold<int>(0, (s, e) => s + e.carbsG);
    final totalF = entries.fold<int>(0, (s, e) => s + e.fatG);
    final totalFib = entries.fold<int>(0, (s, e) => s + e.fiberG);
    final totalNa = entries.fold<int>(0, (s, e) => s + e.sodiumMg);
    final inputSnippet = entries.first.rawInput.length > 80
        ? '${entries.first.rawInput.substring(0, 80)}…'
        : entries.first.rawInput;

    return Container(
      decoration: BoxDecoration(
        // Flat soft accent tint — matches single-meal cards in shape and
        // border weight; the saffron wash distinguishes a multi-item
        // meal from a single entry without shouting. Was a gradient
        // that read as messy at small sizes.
        color: AppColors.accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: AppColors.accent.withValues(alpha: 0.30), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.restaurant_rounded,
                              size: 11, color: AppColors.accent),
                          const SizedBox(width: 4),
                          Text('MEAL · ${entries.length} ITEMS',
                              style: TextStyle(
                                color: AppColors.accent,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                              )),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Tap-to-edit meal time. Batch updates all items in
                    // the group so AI-split entries stay in sync.
                    GestureDetector(
                      onTap: _editGroupTime,
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: AppColors.accent
                                  .withValues(alpha: 0.30)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.schedule_rounded,
                                size: 11, color: AppColors.accent),
                            const SizedBox(width: 4),
                            Text(time,
                                style: AppText.meta.copyWith(
                                  fontSize: 12,
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.w700,
                                )),
                            const SizedBox(width: 4),
                            Icon(Icons.edit_rounded,
                                size: 10, color: AppColors.accent),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '"$inputSnippet"',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.body.copyWith(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text('$totalKcal',
                        style: AppText.giantNumber.copyWith(fontSize: 32)),
                    const SizedBox(width: 4),
                    Text('kcal · total',
                        style: AppText.meta.copyWith(
                            fontSize: 12,
                            color: AppColors.textTertiary,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                        child: _Nutrient(
                            label: 'P',
                            value: totalP,
                            unit: 'g',
                            color: AppColors.protein)),
                    Expanded(
                        child: _Nutrient(
                            label: 'C',
                            value: totalC,
                            unit: 'g',
                            color: AppColors.carbs)),
                    Expanded(
                        child: _Nutrient(
                            label: 'F',
                            value: totalF,
                            unit: 'g',
                            color: AppColors.fat)),
                    Expanded(
                        child: _Nutrient(
                            label: 'Fib',
                            value: totalFib,
                            unit: 'g',
                            color: AppColors.fiber)),
                    Expanded(
                        child: _Nutrient(
                            label: 'Na',
                            value: totalNa,
                            unit: 'mg',
                            color: AppColors.calorieFrom)),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppColors.stroke),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                      _expanded
                          ? 'HIDE ITEMS'
                          : 'SHOW ${entries.length} ITEMS',
                      style: AppText.label.copyWith(
                          color: AppColors.accent, letterSpacing: 0.8)),
                  const SizedBox(width: 4),
                  Icon(
                      _expanded
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      size: 14,
                      color: AppColors.accent),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            child: !_expanded
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                    child: Column(
                      children: [
                        for (var i = 0; i < entries.length; i++) ...[
                          _MealItem(
                            entry: entries[i],
                            index: i + 1,
                          ),
                          if (i < entries.length - 1)
                            const SizedBox(height: 6),
                        ],
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _MealItem extends StatelessWidget {
  final FoodEntry entry;
  final int index;
  const _MealItem({required this.entry, required this.index});

  @override
  Widget build(BuildContext context) {
    final name = entry.description.isEmpty ? entry.rawInput : entry.description;
    return GestureDetector(
      onTap: () => MealActionsSheet.show(context, entry),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.stroke),
        ),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: AppColors.surfaceHigh,
                borderRadius: BorderRadius.circular(7),
              ),
              alignment: Alignment.center,
              child: Text('$index',
                  style: TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  )),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.body.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13)),
                  if (entry.quantity.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(entry.quantity,
                        style: AppText.meta.copyWith(fontSize: 11)),
                  ],
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      _MicroChip(value: '${entry.proteinG}g P', color: AppColors.protein),
                      _MicroChip(value: '${entry.carbsG}g C', color: AppColors.carbs),
                      _MicroChip(value: '${entry.fatG}g F', color: AppColors.fat),
                      if (entry.fiberG > 0)
                        _MicroChip(value: '${entry.fiberG}g Fib', color: AppColors.fiber),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${entry.calories}',
                    style: AppText.bigNumber.copyWith(fontSize: 16)),
                Text('kcal',
                    style: AppText.meta.copyWith(
                        fontSize: 9,
                        color: AppColors.textTertiary,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MicroChip extends StatelessWidget {
  final String value;
  final Color color;
  const _MicroChip({required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(value,
          style: TextStyle(
            color: color,
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.1,
          )),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final Profile profile;
  final DailyTotals totals;
  const _SummaryCard({required this.profile, required this.totals});

  @override
  Widget build(BuildContext context) {
    final calLeft = (profile.effectiveCalorieTarget - totals.calories).clamp(0, 99999);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surface,
            AppColors.surfaceHigh,
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('TODAY · ${totals.calories} kcal',
                        style: AppText.label),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text('$calLeft',
                            style: AppText.giantNumber.copyWith(fontSize: 40)),
                        const SizedBox(width: 6),
                        Text('kcal left',
                            style: AppText.meta.copyWith(
                                fontSize: 13,
                                color: AppColors.textTertiary)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text('of ${profile.effectiveCalorieTarget} target',
                        style: AppText.meta.copyWith(fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MacroChip(
                  label: 'Protein',
                  value: '${totals.proteinG}',
                  target: profile.effectiveProteinTarget,
                  color: AppColors.protein,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MacroChip(
                  label: 'Carbs',
                  value: '${totals.carbsG}',
                  target: profile.effectiveCarbTarget,
                  color: AppColors.carbs,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MacroChip(
                  label: 'Fat',
                  value: '${totals.fatG}',
                  target: profile.effectiveFatTarget,
                  color: AppColors.fat,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _MacroChip(
                  label: 'Fiber',
                  value: '${totals.fiberG}',
                  target: profile.effectiveFiberTarget,
                  color: AppColors.fiber,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MacroChip(
                  label: 'Sodium',
                  value: '${totals.sodiumMg}',
                  target: 2300,
                  unit: 'mg',
                  color: AppColors.calorieFrom,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MacroChip(
                  label: 'Water',
                  value: (totals.waterMl / 1000).toStringAsFixed(1),
                  target: profile.effectiveWaterTarget ~/ 1000,
                  unit: 'L',
                  targetUnit: 'L',
                  color: AppColors.water,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MacroChip extends StatelessWidget {
  final String label;
  final String value;
  final int target;
  final String unit;
  final String? targetUnit;
  final Color color;
  const _MacroChip({
    required this.label,
    required this.value,
    required this.target,
    required this.color,
    this.unit = 'g',
    this.targetUnit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                    color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(label,
                  style: AppText.meta.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textTertiary)),
            ],
          ),
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: AppText.bigNumber.copyWith(
                      fontSize: 18, color: AppColors.textPrimary),
                ),
                TextSpan(
                  text: '$unit / $target${targetUnit ?? unit}',
                  style: AppText.meta.copyWith(
                      fontSize: 10, color: AppColors.textTertiary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FoodEntryCard extends StatelessWidget {
  final FoodEntry entry;
  const _FoodEntryCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('h:mm a').format(entry.timestamp);
    final name = entry.description.isEmpty ? entry.rawInput : entry.description;
    return GestureDetector(
      onTap: () => MealActionsSheet.show(context, entry),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.stroke),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.sectionTitle.copyWith(fontSize: 15)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.schedule_rounded,
                              size: 11, color: AppColors.textTertiary),
                          const SizedBox(width: 4),
                          Text(time,
                              style: AppText.meta.copyWith(fontSize: 12)),
                          if (entry.quantity.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Container(
                              width: 3,
                              height: 3,
                              decoration: BoxDecoration(
                                color: AppColors.textTertiary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(entry.quantity,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppText.meta.copyWith(fontSize: 12)),
                            ),
                          ],
                          const SizedBox(width: 8),
                          _SourceBadge(source: entry.source),
                          if (entry.isFavorite) ...[
                            const SizedBox(width: 6),
                            Icon(Icons.star_rounded,
                                size: 12, color: AppColors.streak),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${entry.calories}',
                        style: AppText.bigNumber.copyWith(fontSize: 22)),
                    Text('kcal',
                        style: AppText.meta.copyWith(
                            fontSize: 10,
                            color: AppColors.textTertiary,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ],
            ),
            if (entry.confidence == EstimateConfidence.low &&
                entry.caloriesLow != null &&
                entry.caloriesHigh != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceHigh,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '~${entry.caloriesLow}–${entry.caloriesHigh} kcal · estimate may vary',
                  style: AppText.meta.copyWith(
                      fontSize: 10, color: AppColors.textTertiary),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                    child: _Nutrient(
                        label: 'P',
                        value: entry.proteinG,
                        unit: 'g',
                        color: AppColors.protein)),
                Expanded(
                    child: _Nutrient(
                        label: 'C',
                        value: entry.carbsG,
                        unit: 'g',
                        color: AppColors.carbs)),
                Expanded(
                    child: _Nutrient(
                        label: 'F',
                        value: entry.fatG,
                        unit: 'g',
                        color: AppColors.fat)),
                Expanded(
                    child: _Nutrient(
                        label: 'Fib',
                        value: entry.fiberG,
                        unit: 'g',
                        color: AppColors.fiber)),
                Expanded(
                    child: _Nutrient(
                        label: 'Na',
                        value: entry.sodiumMg,
                        unit: 'mg',
                        color: AppColors.calorieFrom)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Nutrient extends StatelessWidget {
  final String label;
  final int value;
  final String unit;
  final Color color;
  const _Nutrient({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: '$value',
                style: AppText.bigNumber.copyWith(
                    fontSize: 15, color: AppColors.textPrimary),
              ),
              TextSpan(
                text: unit,
                style: AppText.meta.copyWith(
                    fontSize: 10,
                    color: AppColors.textTertiary,
                    fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Text(label,
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            )),
      ],
    );
  }
}

class _SourceBadge extends StatelessWidget {
  final FoodSource source;
  const _SourceBadge({required this.source});

  @override
  Widget build(BuildContext context) {
    String label;
    IconData icon;
    switch (source) {
      case FoodSource.aiText:
        label = 'AI';
        icon = Icons.auto_awesome_rounded;
        break;
      case FoodSource.aiPhoto:
        label = 'Photo';
        icon = Icons.photo_camera_rounded;
        break;
      case FoodSource.custom:
        label = 'Custom';
        icon = Icons.bookmark_rounded;
        break;
      case FoodSource.favorite:
        label = 'Favorite';
        icon = Icons.star_rounded;
        break;
      case FoodSource.usdaVerified:
        label = 'USDA';
        icon = Icons.verified_rounded;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 9, color: AppColors.accent),
          const SizedBox(width: 3),
          Text(label,
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              )),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.restaurant_rounded,
                size: 24, color: AppColors.accent),
          ),
          const SizedBox(height: 14),
          Text('Nothing logged yet',
              style: AppText.sectionTitle.copyWith(fontSize: 16)),
          const SizedBox(height: 6),
          Text(
            'Open the dashboard and type a meal — your day fills in here.',
            textAlign: TextAlign.center,
            style: AppText.body.copyWith(fontSize: 13),
          ),
        ],
      ),
    );
  }
}

/// Wraps a food card with swipe-to-delete + undo. The Dismissible
/// removes the card from the list as soon as the user swipes; the
/// actual Isar delete happens in the same tick. If they tap UNDO in
/// the snackbar within 5 s we re-add the original entries.
class _SwipeToDelete extends ConsumerWidget {
  final List<FoodEntry> entries;
  final Widget child;
  const _SwipeToDelete({required this.entries, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(nutritionRepoProvider);
    final key = ValueKey('meal-${entries.map((e) => e.id).join('-')}');
    return Dismissible(
      key: key,
      direction: DismissDirection.endToStart,
      onDismissed: (_) async {
        // Snapshot BEFORE delete so undo gets a fresh detached copy.
        final snapshots = entries.map(_clone).toList();
        for (final e in entries) {
          await repo.deleteFoodEntry(e.id);
        }
        if (!context.mounted) return;
        final messenger = ScaffoldMessenger.of(context);
        messenger
          ..clearSnackBars()
          ..showSnackBar(SnackBar(
            backgroundColor: AppColors.surfaceHigh,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 5),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            content: Text(
              entries.length == 1
                  ? 'Removed · ${entries.first.calories} kcal'
                  : 'Removed meal · ${entries.length} items',
              style:
                  AppText.body.copyWith(color: AppColors.textPrimary),
            ),
            action: SnackBarAction(
              label: 'Undo',
              textColor: AppColors.accent,
              onPressed: () async {
                for (final s in snapshots) {
                  await repo.addFoodEntry(s);
                }
              },
            ),
          ));
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_outline_rounded,
                color: AppColors.danger, size: 22),
            const SizedBox(width: 6),
            Text('Delete',
                style: AppText.body.copyWith(
                  color: AppColors.danger,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                )),
          ],
        ),
      ),
      child: child,
    );
  }

  FoodEntry _clone(FoodEntry e) {
    return FoodEntry()
      ..timestamp = e.timestamp
      ..dateKey = e.dateKey
      ..rawInput = e.rawInput
      ..description = e.description
      ..quantity = e.quantity
      ..unit = e.unit
      ..calories = e.calories
      ..proteinG = e.proteinG
      ..carbsG = e.carbsG
      ..fatG = e.fatG
      ..fiberG = e.fiberG
      ..sodiumMg = e.sodiumMg
      ..source = e.source
      ..confidence = e.confidence
      ..caloriesLow = e.caloriesLow
      ..caloriesHigh = e.caloriesHigh
      ..isFavorite = e.isFavorite
      ..photoPath = e.photoPath;
  }
}
