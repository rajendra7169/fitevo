import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/food_entry.dart';
import '../../data/models/profile.dart';
import '../../data/repositories/nutrition_repo.dart';
import '../../state/providers.dart';
import '../../theme.dart';

// ─── public entry point ────────────────────────────────────────────────────

class NutrientDetailPage extends ConsumerWidget {
  final NutrientType nutrient;
  const NutrientDetailPage({super.key, required this.nutrient});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(todayEntriesProvider).valueOrNull ?? [];
    final totals = ref.watch(todayTotalsProvider);
    final profile = ref.watch(profileStreamProvider).valueOrNull;

    final info = nutrient.info;
    final consumed = info.consumed(totals);
    final target = profile != null ? info.target(profile) : 0;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _NutrientSliverAppBar(nutrient: nutrient),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SummaryCard(
                    nutrient: nutrient,
                    consumed: consumed,
                    target: target,
                    unit: info.unit,
                  ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.06, end: 0),
                  const SizedBox(height: 24),
                  if (info.description.isNotEmpty) ...[
                    _InfoBanner(description: info.description, color: info.color)
                        .animate(delay: 80.ms)
                        .fadeIn(duration: 300.ms)
                        .slideY(begin: 0.06, end: 0),
                    const SizedBox(height: 24),
                  ],
                  Text(
                    'FROM TODAY\'S MEALS',
                    style: AppText.label.copyWith(
                      color: AppColors.textTertiary,
                      fontSize: 11,
                    ),
                  ).animate(delay: 120.ms).fadeIn(duration: 280.ms),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          _EntriesList(entries: entries, nutrient: nutrient, consumed: consumed),
          const SliverToBoxAdapter(child: SizedBox(height: 48)),
        ],
      ),
    );
  }
}

// ─── nutrient type enum ────────────────────────────────────────────────────

enum NutrientType { protein, carbs, fat, fiber, sodium }

extension NutrientInfo on NutrientType {
  NutrientMeta get info {
    switch (this) {
      case NutrientType.protein:
        return NutrientMeta(
          label: 'Protein',
          unit: 'g',
          color: AppColors.protein,
          icon: Icons.fitness_center_rounded,
          consumed: (t) => t.proteinG,
          target: (p) => p.effectiveProteinTarget,
          description:
              'Protein builds and repairs muscle, supports enzymes and hormones, and helps you feel full.',
        );
      case NutrientType.carbs:
        return NutrientMeta(
          label: 'Carbohydrates',
          unit: 'g',
          color: AppColors.carbs,
          icon: Icons.grain_rounded,
          consumed: (t) => t.carbsG,
          target: (p) => p.effectiveCarbTarget,
          description:
              'Carbs are your body\'s primary energy source, fuelling the brain and muscles during exercise.',
        );
      case NutrientType.fat:
        return NutrientMeta(
          label: 'Fat',
          unit: 'g',
          color: AppColors.fat,
          icon: Icons.water_drop_rounded,
          consumed: (t) => t.fatG,
          target: (p) => p.effectiveFatTarget,
          description:
              'Healthy fats support cell membranes, hormone production, and absorption of fat-soluble vitamins.',
        );
      case NutrientType.fiber:
        return NutrientMeta(
          label: 'Fiber',
          unit: 'g',
          color: AppColors.fiber,
          icon: Icons.grass_rounded,
          consumed: (t) => t.fiberG,
          target: (p) => p.effectiveFiberTarget,
          description:
              'Dietary fiber aids digestion, regulates blood sugar, lowers cholesterol, and promotes satiety.',
        );
      case NutrientType.sodium:
        return NutrientMeta(
          label: 'Sodium',
          unit: 'mg',
          color: AppColors.calorieFrom,
          icon: Icons.scatter_plot_rounded,
          consumed: (t) => t.sodiumMg,
          target: (_) => 2300,
          description:
              'Sodium regulates fluid balance and nerve signals. Excess intake may raise blood pressure.',
        );
    }
  }

  int entryValue(FoodEntry e) {
    switch (this) {
      case NutrientType.protein:
        return e.proteinG;
      case NutrientType.carbs:
        return e.carbsG;
      case NutrientType.fat:
        return e.fatG;
      case NutrientType.fiber:
        return e.fiberG;
      case NutrientType.sodium:
        return e.sodiumMg;
    }
  }
}

class NutrientMeta {
  final String label;
  final String unit;
  final Color color;
  final IconData icon;
  final int Function(DailyTotals) consumed;
  final int Function(Profile) target;
  final String description;

  const NutrientMeta({
    required this.label,
    required this.unit,
    required this.color,
    required this.icon,
    required this.consumed,
    required this.target,
    required this.description,
  });
}

// ─── sliver app bar ────────────────────────────────────────────────────────

class _NutrientSliverAppBar extends StatelessWidget {
  final NutrientType nutrient;
  const _NutrientSliverAppBar({required this.nutrient});

  @override
  Widget build(BuildContext context) {
    final info = nutrient.info;
    return SliverAppBar(
      pinned: true,
      expandedHeight: 120,
      backgroundColor: AppColors.bg,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      leading: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Container(
          margin: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.surfaceHigh,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.arrow_back_rounded,
              size: 18, color: AppColors.textPrimary),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: info.color.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(info.icon, size: 16, color: info.color),
            ),
            const SizedBox(width: 10),
            Text(
              info.label,
              style: AppText.sectionTitle.copyWith(fontSize: 18),
            ),
          ],
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                info.color.withValues(alpha: 0.08),
                AppColors.bg,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── summary card ──────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final NutrientType nutrient;
  final int consumed;
  final int target;
  final String unit;

  const _SummaryCard({
    required this.nutrient,
    required this.consumed,
    required this.target,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final info = nutrient.info;
    final progress = target == 0 ? 0.0 : (consumed / target).clamp(0.0, 1.0);
    final remaining = math.max(0, target - consumed);
    final over = consumed > target && target > 0;
    final done = remaining == 0 && target > 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.stroke),
        boxShadow: [
          BoxShadow(
            color: info.color.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Consumed big number
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CONSUMED',
                    style: AppText.label.copyWith(fontSize: 10),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: consumed.toDouble()),
                        duration: const Duration(milliseconds: 700),
                        curve: Curves.easeOutCubic,
                        builder: (_, v, child) => Text(
                          _formatValue(v.round(), unit),
                          style: AppText.bigNumber.copyWith(
                            fontSize: 36,
                            color: over
                                ? AppColors.calorieFrom
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        unit,
                        style: AppText.meta.copyWith(
                            fontSize: 14, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              // Target bubble
              if (target > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceHigh,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: AppColors.stroke),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'TARGET',
                        style: AppText.label.copyWith(fontSize: 9),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatValue(target, unit),
                        style: AppText.meta.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        unit,
                        style: AppText.meta.copyWith(
                            fontSize: 10, color: AppColors.textTertiary),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          // Animated progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: Stack(
              children: [
                Container(height: 10, color: AppColors.surfaceHigh),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: progress),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutCubic,
                  builder: (_, v, child) => FractionallySizedBox(
                    widthFactor: v,
                    child: Container(
                      height: 10,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            info.color,
                            info.color.withValues(alpha: 0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Status row
          Row(
            children: [
              _StatPill(
                label: done
                    ? 'Goal reached! ✓'
                    : over
                        ? 'Over by ${_formatValue(consumed - target, unit)} $unit'
                        : '${_formatValue(remaining, unit)} $unit remaining',
                color: done
                    ? AppColors.protein
                    : over
                        ? AppColors.calorieFrom
                        : AppColors.textSecondary,
              ),
              const Spacer(),
              Text(
                '${(progress * 100).round()}%',
                style: AppText.meta.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: info.color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatValue(int v, String unit) {
    if (unit == 'mg' && v >= 1000) {
      return (v / 1000).toStringAsFixed(v % 1000 == 0 ? 0 : 1);
    }
    return '$v';
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final Color color;
  const _StatPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: AppText.meta.copyWith(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ─── info banner ───────────────────────────────────────────────────────────

class _InfoBanner extends StatelessWidget {
  final String description;
  final Color color;
  const _InfoBanner({required this.description, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 15, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              description,
              style: AppText.body.copyWith(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── entries list ──────────────────────────────────────────────────────────

class _EntriesList extends StatelessWidget {
  final List<FoodEntry> entries;
  final NutrientType nutrient;
  final int consumed;

  const _EntriesList({
    required this.entries,
    required this.nutrient,
    required this.consumed,
  });

  @override
  Widget build(BuildContext context) {
    // Only show entries that contributed to this nutrient
    final relevant = entries
        .where((e) => nutrient.entryValue(e) > 0)
        .toList()
      ..sort((a, b) =>
          nutrient.entryValue(b).compareTo(nutrient.entryValue(a)));

    if (relevant.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: _EmptyState(nutrient: nutrient),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      sliver: SliverList.separated(
        itemCount: relevant.length,
        separatorBuilder: (_, i) => const SizedBox(height: 10),
        itemBuilder: (ctx, i) {
          final entry = relevant[i];
          final value = nutrient.entryValue(entry);
          return _EntryTile(
            entry: entry,
            value: value,
            total: consumed,
            nutrient: nutrient,
            index: i,
          );
        },
      ),
    );
  }
}

class _EntryTile extends StatelessWidget {
  final FoodEntry entry;
  final int value;
  final int total;
  final NutrientType nutrient;
  final int index;

  const _EntryTile({
    required this.entry,
    required this.value,
    required this.total,
    required this.nutrient,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final info = nutrient.info;
    final share = total == 0 ? 0.0 : (value / total).clamp(0.0, 1.0);
    final pct = (share * 100).round();

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.stroke, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Rank badge
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: info.color.withValues(alpha: index == 0 ? 0.22 : 0.10),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '${index + 1}',
                  style: AppText.label.copyWith(
                    fontSize: 10,
                    color: info.color,
                    letterSpacing: 0,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.description,
                      style: AppText.body.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (entry.quantity.isNotEmpty)
                      Text(
                        '${entry.quantity}${entry.unit.isNotEmpty ? ' ${entry.unit}' : ''}',
                        style: AppText.meta.copyWith(
                          fontSize: 11,
                          color: AppColors.textTertiary,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // Value + percentage
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatValue(value, info.unit),
                    style: AppText.bigNumber.copyWith(
                      fontSize: 18,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    '$pct%',
                    style: AppText.meta.copyWith(
                      fontSize: 11,
                      color: info.color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Contribution bar
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                Container(height: 4, color: AppColors.surfaceHigh),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: share),
                  duration: Duration(milliseconds: 500 + index * 60),
                  curve: Curves.easeOutCubic,
                  builder: (_, v, _) => FractionallySizedBox(
                    widthFactor: v,
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: info.color,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: 140 + index * 50))
        .fadeIn(duration: 280.ms)
        .slideY(begin: 0.06, end: 0);
  }

  String _formatValue(int v, String unit) {
    if (unit == 'mg') return '${v}mg';
    return '${v}g';
  }
}

// ─── empty state ───────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final NutrientType nutrient;
  const _EmptyState({required this.nutrient});

  @override
  Widget build(BuildContext context) {
    final info = nutrient.info;
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: info.color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(info.icon, size: 24, color: info.color),
          ),
          const SizedBox(height: 14),
          Text(
            'No ${info.label} logged today',
            style: AppText.sectionTitle.copyWith(fontSize: 16),
          ),
          const SizedBox(height: 6),
          Text(
            'Log a meal to see how each food contributes to your ${info.label.toLowerCase()} intake.',
            textAlign: TextAlign.center,
            style: AppText.body.copyWith(fontSize: 13, height: 1.5),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 350.ms).scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1));
  }
}
