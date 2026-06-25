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

    // Filter to relevant entries once so the meal-count badge matches the list.
    final relevant = entries
        .where((e) => nutrient.entryValue(e) > 0)
        .toList()
      ..sort((a, b) =>
          nutrient.entryValue(b).compareTo(nutrient.entryValue(a)));

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _NutrientSliverAppBar(nutrient: nutrient),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _RingSummary(
                    nutrient: nutrient,
                    consumed: consumed,
                    target: target,
                    unit: info.unit,
                  )
                      .animate()
                      .fadeIn(duration: 360.ms)
                      .slideY(begin: 0.06, end: 0),
                  const SizedBox(height: 22),
                  if (info.description.isNotEmpty) ...[
                    _InfoBanner(
                      description: info.description,
                      color: info.color,
                      icon: info.icon,
                    )
                        .animate(delay: 80.ms)
                        .fadeIn(duration: 320.ms)
                        .slideY(begin: 0.06, end: 0),
                    const SizedBox(height: 22),
                  ],
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'FROM TODAY\'S MEALS',
                        style: AppText.label.copyWith(
                          color: AppColors.textTertiary,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (relevant.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: info.color.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${relevant.length}',
                            style: AppText.label.copyWith(
                              fontSize: 10,
                              color: info.color,
                              letterSpacing: 0,
                            ),
                          ),
                        ),
                    ],
                  ).animate(delay: 120.ms).fadeIn(duration: 280.ms),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          _EntriesList(
              entries: relevant, nutrient: nutrient, consumed: consumed),
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
              'Builds and repairs muscle, fuels enzymes and hormones, and keeps you full longer.',
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
              'Your body\'s primary energy source. Fuels your brain and lights up your gym sessions.',
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
              'Healthy fats support hormones, brain function, and the absorption of vitamins A, D, E, K.',
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
              'Slows digestion, steadies blood sugar, lowers cholesterol, and keeps you feeling full.',
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
              'Regulates fluid balance and nerve signals. The 2,300 mg ceiling is the FDA upper limit.',
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
      expandedHeight: 140,
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
        titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: info.color.withValues(alpha: 0.20),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(info.icon, size: 18, color: info.color),
            ),
            const SizedBox(width: 10),
            Text(
              info.label,
              style: AppText.sectionTitle.copyWith(fontSize: 18),
            ),
          ],
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Vertical gradient — stronger at top, fades into bg
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    info.color.withValues(alpha: 0.22),
                    info.color.withValues(alpha: 0.05),
                    AppColors.bg,
                  ],
                  stops: const [0.0, 0.6, 1.0],
                ),
              ),
            ),
            // Soft radial highlight in upper-right for depth
            Align(
              alignment: const Alignment(0.85, -0.8),
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      info.color.withValues(alpha: 0.18),
                      info.color.withValues(alpha: 0.0),
                    ],
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

// ─── ring summary ──────────────────────────────────────────────────────────

class _RingSummary extends StatelessWidget {
  final NutrientType nutrient;
  final int consumed;
  final int target;
  final String unit;

  const _RingSummary({
    required this.nutrient,
    required this.consumed,
    required this.target,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final info = nutrient.info;
    final progress = target == 0 ? 0.0 : (consumed / target).clamp(0.0, 1.2);
    final remaining = math.max(0, target - consumed);
    final over = consumed > target && target > 0;
    final done = remaining == 0 && target > 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.stroke),
        boxShadow: [
          BoxShadow(
            color: info.color.withValues(alpha: 0.10),
            blurRadius: 28,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // The ring itself
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: progress),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOutCubic,
                  builder: (_, v, _) => SizedBox(
                    width: 200,
                    height: 200,
                    child: CustomPaint(
                      painter: _RingPainter(
                        progress: v,
                        color: info.color,
                        trackColor: AppColors.surfaceHigh,
                      ),
                    ),
                  ),
                ),
                // Center label stack
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'CONSUMED',
                      style: AppText.label.copyWith(
                        fontSize: 10,
                        color: AppColors.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: consumed.toDouble()),
                          duration: const Duration(milliseconds: 800),
                          curve: Curves.easeOutCubic,
                          builder: (_, v, _) => Text(
                            _formatValue(v.round(), unit),
                            style: AppText.giantNumber.copyWith(
                              fontSize: 44,
                              letterSpacing: -1.4,
                              color: over
                                  ? AppColors.danger
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            unit,
                            style: AppText.meta.copyWith(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (target > 0) ...[
                      const SizedBox(height: 2),
                      Text(
                        'of ${_formatValue(target, unit)} $unit',
                        style: AppText.meta.copyWith(
                          fontSize: 12,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _StatusPill(
                label: done
                    ? 'Goal reached'
                    : over
                        ? 'Over by ${_formatValue(consumed - target, unit)} $unit'
                        : '${_formatValue(remaining, unit)} $unit to go',
                color: done
                    ? AppColors.success
                    : over
                        ? AppColors.danger
                        : info.color,
                icon: done
                    ? Icons.check_rounded
                    : over
                        ? Icons.warning_amber_rounded
                        : Icons.trending_flat_rounded,
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

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;

  _RingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = 12.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - stroke) / 2;

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = trackColor;
    canvas.drawCircle(center, radius, track);

    if (progress <= 0) return;
    final sweep = (progress.clamp(0.0, 1.0)) * 2 * math.pi;
    final fg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: math.pi * 1.5,
        colors: [
          color.withValues(alpha: 0.7),
          color,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweep,
      false,
      fg,
    );

    // Overflow indicator — paint a second arc in danger color past 100%.
    if (progress > 1.0) {
      final overflow = ((progress - 1.0).clamp(0.0, 0.2)) * 2 * math.pi;
      final overflowPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = AppColors.danger;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        overflow,
        false,
        overflowPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress ||
      old.color != color ||
      old.trackColor != trackColor;
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  const _StatusPill({
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppText.meta.copyWith(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── info banner ───────────────────────────────────────────────────────────

class _InfoBanner extends StatelessWidget {
  final String description;
  final Color color;
  final IconData icon;
  const _InfoBanner({
    required this.description,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 12),
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
    if (entries.isEmpty) {
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
        itemCount: entries.length,
        separatorBuilder: (_, i) => const SizedBox(height: 10),
        itemBuilder: (ctx, i) {
          final entry = entries[i];
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
    final isTop = index == 0;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isTop
              ? info.color.withValues(alpha: 0.35)
              : AppColors.stroke,
          width: isTop ? 1.2 : 1,
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Vertical color stripe — bolder for top contributor
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: info.color
                    .withValues(alpha: isTop ? 1.0 : 0.5 + (share * 0.4)),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
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
                              height: 1.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (entry.quantity.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              '${entry.quantity}${entry.unit.isNotEmpty ? ' ${entry.unit}' : ''}',
                              style: AppText.meta.copyWith(
                                fontSize: 11.5,
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _formatValue(value, info.unit),
                          style: AppText.bigNumber.copyWith(
                            fontSize: 20,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: info.color.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '$pct%',
                            style: AppText.label.copyWith(
                              fontSize: 10,
                              color: info.color,
                              letterSpacing: 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
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
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: info.color.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(info.icon, size: 26, color: info.color),
          ),
          const SizedBox(height: 16),
          Text(
            'Nothing logged yet',
            style: AppText.sectionTitle.copyWith(fontSize: 16),
          ),
          const SizedBox(height: 6),
          Text(
            'Log a meal to see how each food contributes to your ${info.label.toLowerCase()} for today.',
            textAlign: TextAlign.center,
            style: AppText.body.copyWith(fontSize: 13, height: 1.5),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 350.ms)
        .scale(begin: const Offset(0.96, 0.96), end: const Offset(1, 1));
  }
}
