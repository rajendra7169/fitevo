import 'dart:io';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/models/body_measurement.dart';
import '../../data/models/daily_log.dart';
import '../../data/models/food_entry.dart';
import '../../data/models/profile.dart';
import '../../data/models/workout_session.dart';
import '../../services/progress/badges.dart' as bd;
import '../../services/progress/streak_calc.dart';
import '../../services/workout/pr_tracker.dart';
import '../../state/providers.dart';
import '../../theme.dart';
import 'daily_report_page.dart';
import 'measurement_entry_sheet.dart';

class ProgressPage extends ConsumerWidget {
  const ProgressPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileStreamProvider);
    final measurementsAsync = ref.watch(measurementsProvider);
    final foodsAsync = ref.watch(allFoodEntriesProvider);
    final sessionsAsync = ref.watch(allSessionsProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        title: Text('Progress', style: AppText.sectionTitle),
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      body: SafeArea(
        child: profileAsync.when(
          loading: () => _busy(),
          error: (_, _) => _busy(),
          data: (profile) {
            if (profile == null) return _busy();
            final measurements =
                measurementsAsync.valueOrNull ?? const <BodyMeasurement>[];
            final foods =
                foodsAsync.valueOrNull ?? const <FoodEntry>[];
            final sessions =
                sessionsAsync.valueOrNull ?? const <WorkoutSession>[];
            return CustomScrollView(
              physics: const ClampingScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  sliver: SliverList.list(children: [
                    _DailyReportEntry(),
                    const SizedBox(height: 22),
                    _StreakAndBadges(
                      foods: foods,
                      sessions: sessions,
                    ),
                    const SizedBox(height: 22),
                    _WeightSection(
                      profile: profile,
                      measurements: measurements,
                      onLog: () => _logMeasurement(context),
                    ),
                    const SizedBox(height: 22),
                    _NutritionSection(
                      foods: foods,
                      profile: profile,
                    ),
                    const SizedBox(height: 22),
                    _StrengthSection(sessions: sessions),
                    const SizedBox(height: 22),
                    _PhotosSection(measurements: measurements),
                    const SizedBox(height: 28),
                  ]),
                ),
              ],
            );
          },
        ),
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

  Future<void> _logMeasurement(BuildContext context) async {
    await MeasurementEntrySheet.show(context);
  }
}

// ----------------------- DAILY REPORT ENTRY --------------------------------

class _DailyReportEntry extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const DailyReportPage()),
      ),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.accent.withValues(alpha: 0.18),
              AppColors.accent.withValues(alpha: 0.06),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: AppColors.accent.withValues(alpha: 0.35), width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.insights_rounded,
                  color: AppColors.accent, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Daily Report',
                      style: AppText.sectionTitle.copyWith(fontSize: 15)),
                  const SizedBox(height: 2),
                  Text('See food + workout rings and AI summary for any day',
                      style: AppText.meta.copyWith(
                          fontSize: 11, color: AppColors.textTertiary)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: AppColors.textTertiary, size: 22),
          ],
        ),
      ),
    );
  }
}

// ----------------------- STREAK + BADGES -----------------------------------

class _StreakAndBadges extends StatelessWidget {
  final List<FoodEntry> foods;
  final List<WorkoutSession> sessions;
  const _StreakAndBadges({required this.foods, required this.sessions});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final streak = StreakCalc.currentStreak(
      foodEntries: foods,
      sessions: sessions,
      today: now,
    );
    final badges = bd.BadgeEngine.evaluate(
      foods: foods,
      sessions: sessions,
      today: now,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.stroke),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.streak.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.local_fire_department_rounded,
                    size: 28, color: AppColors.streak),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('STREAK', style: AppText.label),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text('$streak',
                            style: AppText.giantNumber
                                .copyWith(fontSize: 32, height: 1.0)),
                        const SizedBox(width: 6),
                        Text(streak == 1 ? 'day' : 'days',
                            style: AppText.meta.copyWith(fontSize: 13)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text('BADGES', style: AppText.label),
        const SizedBox(height: 10),
        SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: badges.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (_, i) => _BadgeTile(badge: badges[i]),
          ),
        ),
      ],
    );
  }
}

class _BadgeTile extends StatelessWidget {
  final bd.Badge badge;
  const _BadgeTile({required this.badge});

  @override
  Widget build(BuildContext context) {
    final color = badge.earned ? AppColors.accent : AppColors.textTertiary;
    return Container(
      width: 110,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: badge.earned
              ? AppColors.accent.withValues(alpha: 0.4)
              : AppColors.stroke,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(badge.icon, size: 18, color: color),
          ),
          const SizedBox(height: 8),
          Text(badge.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.body.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 12)),
          const SizedBox(height: 2),
          Text(badge.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppText.meta.copyWith(fontSize: 10, height: 1.2)),
        ],
      ),
    );
  }
}

// ----------------------- WEIGHT --------------------------------------------

class _WeightSection extends StatelessWidget {
  final Profile profile;
  final List<BodyMeasurement> measurements;
  final VoidCallback onLog;
  const _WeightSection({
    required this.profile,
    required this.measurements,
    required this.onLog,
  });

  @override
  Widget build(BuildContext context) {
    final ordered = measurements.toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    final latest = ordered.isNotEmpty ? ordered.last : null;
    final avg = _rollingAvg(ordered, 7);
    final delta = ordered.length >= 2
        ? ordered.last.weightKg - ordered.first.weightKg
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text('WEIGHT', style: AppText.label)),
            GestureDetector(
              onTap: onLog,
              child: Row(
                children: [
                  Icon(Icons.add_rounded, size: 14, color: AppColors.accent),
                  const SizedBox(width: 2),
                  Text('Log',
                      style: AppText.label.copyWith(
                          color: AppColors.accent, letterSpacing: 0.6)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.stroke),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('CURRENT', style: AppText.label),
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                                (latest?.weightKg ?? profile.weightKg)
                                    .toStringAsFixed(1),
                                style: AppText.giantNumber
                                    .copyWith(fontSize: 36)),
                            const SizedBox(width: 4),
                            Text('kg',
                                style: AppText.meta.copyWith(
                                    fontSize: 14,
                                    color: AppColors.textTertiary)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (avg != null) ...[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('7-DAY AVG', style: AppText.label),
                        const SizedBox(height: 6),
                        Text('${avg.toStringAsFixed(1)} kg',
                            style: AppText.bigNumber.copyWith(fontSize: 18)),
                      ],
                    ),
                  ],
                ],
              ),
              if (delta != null) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      delta < 0
                          ? Icons.trending_down_rounded
                          : delta > 0
                              ? Icons.trending_up_rounded
                              : Icons.trending_flat_rounded,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(1)} kg since first log',
                      style: AppText.meta.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 14),
              SizedBox(
                height: 140,
                child: ordered.length < 2
                    ? Center(
                        child: Text(
                          ordered.isEmpty
                              ? 'Log your first measurement to see the trend.'
                              : 'Add one more measurement to see a trend.',
                          textAlign: TextAlign.center,
                          style: AppText.body.copyWith(fontSize: 13),
                        ),
                      )
                    : _WeightChart(measurements: ordered),
              ),
            ],
          ),
        ),
        if (ordered.isNotEmpty) ...[
          const SizedBox(height: 14),
          _WeightLogList(measurements: ordered.reversed.toList()),
        ],
      ],
    );
  }

  double? _rollingAvg(List<BodyMeasurement> ordered, int days) {
    if (ordered.isEmpty) return null;
    final since = DateTime.now().subtract(Duration(days: days));
    final recent =
        ordered.where((m) => m.date.isAfter(since)).toList();
    if (recent.isEmpty) return null;
    final sum = recent.fold<double>(0, (s, m) => s + m.weightKg);
    return sum / recent.length;
  }
}

/// Newest-first list of weight logs. Tap a row to edit it; swipe
/// right-to-left to delete with a 5 s undo. Lets users fix typos
/// (e.g. 45.4 instead of 75.4) instead of being stuck with a wrong
/// reading that throws off the trend.
class _WeightLogList extends ConsumerWidget {
  final List<BodyMeasurement> measurements;
  const _WeightLogList({required this.measurements});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text('RECENT LOGS', style: AppText.label)),
            Text('Edit or delete each log',
                style: AppText.label.copyWith(
                    color: AppColors.textTertiary, letterSpacing: 0.4)),
          ],
        ),
        const SizedBox(height: 8),
        for (var i = 0; i < measurements.length; i++) ...[
          _WeightLogRow(
            measurement: measurements[i],
            previous: i + 1 < measurements.length ? measurements[i + 1] : null,
          ),
          const SizedBox(height: 6),
        ],
      ],
    );
  }
}

class _WeightLogRow extends ConsumerWidget {
  final BodyMeasurement measurement;
  final BodyMeasurement? previous;
  const _WeightLogRow({required this.measurement, this.previous});

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(measurementRepoProvider);
    final snapshot = _clone(measurement);
    await repo.delete(measurement.id);
    await ref.read(adaptiveTargetsProvider).recomputeFromWeightTrend();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        backgroundColor: AppColors.surfaceHigh,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 5),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)),
        content: Text(
          'Removed · ${measurement.weightKg.toStringAsFixed(1)} kg',
          style: AppText.body.copyWith(color: AppColors.textPrimary),
        ),
        action: SnackBarAction(
          label: 'Undo',
          textColor: AppColors.accent,
          onPressed: () async {
            await repo.save(snapshot);
            await ref
                .read(adaptiveTargetsProvider)
                .recomputeFromWeightTrend();
          },
        ),
      ));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateLabel = DateFormat('MMM d, y · h:mm a').format(measurement.date);
    final delta =
        previous != null ? measurement.weightKg - previous!.weightKg : null;
    // Flag a suspiciously large swing — common typo case (e.g. 45.4
    // instead of 75.4). Doesn't block, just nudges the eye.
    final suspicious = delta != null && delta.abs() >= 5;

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Dismissible(
        key: ValueKey('weight-${measurement.id}'),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => _delete(context, ref),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          color: AppColors.danger.withValues(alpha: 0.18),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.delete_outline_rounded,
                  color: AppColors.danger, size: 20),
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
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () async {
            await MeasurementEntrySheet.show(context, edit: measurement);
          },
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(
                  color: suspicious
                      ? AppColors.danger.withValues(alpha: 0.45)
                      : AppColors.stroke),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                              measurement.weightKg.toStringAsFixed(1),
                              style: AppText.bigNumber
                                  .copyWith(fontSize: 18)),
                          const SizedBox(width: 4),
                          Text('kg',
                              style: AppText.meta.copyWith(
                                  fontSize: 11,
                                  color: AppColors.textTertiary)),
                          if (delta != null) ...[
                            const SizedBox(width: 10),
                            Icon(
                              delta < 0
                                  ? Icons.trending_down_rounded
                                  : delta > 0
                                      ? Icons.trending_up_rounded
                                      : Icons.trending_flat_rounded,
                              size: 12,
                              color: suspicious
                                  ? AppColors.danger
                                  : AppColors.textTertiary,
                            ),
                            const SizedBox(width: 2),
                            Text(
                                '${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(1)} kg',
                                style: AppText.meta.copyWith(
                                  fontSize: 11,
                                  color: suspicious
                                      ? AppColors.danger
                                      : AppColors.textTertiary,
                                  fontWeight: suspicious
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                )),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(dateLabel,
                          style: AppText.meta.copyWith(
                              fontSize: 11,
                              color: AppColors.textTertiary)),
                      if (suspicious) ...[
                        const SizedBox(height: 4),
                        Text('Looks like a big jump — edit if this is a typo.',
                            style: AppText.meta.copyWith(
                                fontSize: 10,
                                color: AppColors.danger,
                                fontWeight: FontWeight.w600)),
                      ],
                    ],
                  ),
                ),
                _RowIconButton(
                  icon: Icons.edit_rounded,
                  tooltip: 'Edit',
                  color: AppColors.accent,
                  onTap: () => MeasurementEntrySheet.show(context,
                      edit: measurement),
                ),
                const SizedBox(width: 6),
                _RowIconButton(
                  icon: Icons.delete_outline_rounded,
                  tooltip: 'Delete',
                  color: AppColors.danger,
                  onTap: () => _confirmDelete(context, ref),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Text('Delete this log?',
            style: AppText.sectionTitle.copyWith(fontSize: 16)),
        content: Text(
          '${measurement.weightKg.toStringAsFixed(1)} kg on '
          '${DateFormat('MMM d, y').format(measurement.date)} will be '
          'removed. You can undo this for 5 seconds.',
          style: AppText.body.copyWith(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete',
                style: TextStyle(
                  color: AppColors.danger,
                  fontWeight: FontWeight.w800,
                )),
          ),
        ],
      ),
    );
    if (ok != true) return;
    if (!context.mounted) return;
    await _delete(context, ref);
  }

  BodyMeasurement _clone(BodyMeasurement m) {
    return BodyMeasurement()
      ..date = m.date
      ..weightKg = m.weightKg
      ..bodyFatPct = m.bodyFatPct
      ..waistCm = m.waistCm
      ..chestCm = m.chestCm
      ..hipsCm = m.hipsCm
      ..thighCm = m.thighCm
      ..armCm = m.armCm
      ..neckCm = m.neckCm
      ..photoPath = m.photoPath
      ..note = m.note
      ..createdAt = m.createdAt;
  }
}

class _RowIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onTap;
  const _RowIconButton({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}

class _WeightChart extends StatelessWidget {
  final List<BodyMeasurement> measurements;
  const _WeightChart({required this.measurements});

  @override
  Widget build(BuildContext context) {
    final firstMs =
        measurements.first.date.millisecondsSinceEpoch.toDouble();
    final spots = measurements.map((m) {
      final x = (m.date.millisecondsSinceEpoch - firstMs) /
          (1000 * 60 * 60 * 24);
      return FlSpot(x, m.weightKg);
    }).toList();
    final minY = (spots.map((s) => s.y).reduce((a, b) => a < b ? a : b) - 1)
        .floorToDouble();
    final maxY = (spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) + 1)
        .ceilToDouble();
    final maxX = spots.last.x;

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: maxX == 0 ? 1 : maxX,
        minY: minY,
        maxY: maxY,
        gridData: FlGridData(
          drawVerticalLine: false,
          horizontalInterval: ((maxY - minY) / 3).clamp(1, 10),
          getDrawingHorizontalLine: (_) => FlLine(
            color: AppColors.stroke,
            strokeWidth: 1,
            dashArray: const [4, 4],
          ),
        ),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => AppColors.surfaceHigh,
            tooltipRoundedRadius: 10,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                return LineTooltipItem(
                  '${spot.y.toStringAsFixed(1)} kg',
                  TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                );
              }).toList();
            },
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.25,
            barWidth: 2.5,
            color: AppColors.accent,
            dotData: FlDotData(
              show: true,
              getDotPainter: (_, _, _, _) => FlDotCirclePainter(
                radius: 2.5,
                color: AppColors.accent,
                strokeColor: AppColors.bg,
                strokeWidth: 1,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.accent.withValues(alpha: 0.22),
                  AppColors.accent.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ----------------------- NUTRITION TRENDS ----------------------------------

class _NutritionSection extends StatelessWidget {
  final List<FoodEntry> foods;
  final Profile profile;
  const _NutritionSection({required this.foods, required this.profile});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    const days = 14;
    final caloriesByDay = <String, int>{};
    for (var i = 0; i < days; i++) {
      final d = today.subtract(Duration(days: days - 1 - i));
      caloriesByDay[DailyLog.keyFor(d)] = 0;
    }
    for (final e in foods) {
      if (caloriesByDay.containsKey(e.dateKey)) {
        caloriesByDay[e.dateKey] = (caloriesByDay[e.dateKey] ?? 0) + e.calories;
      }
    }
    final values = caloriesByDay.values.toList();

    final target = profile.effectiveCalorieTarget.toDouble();
    final maxY = (values.fold<int>(0, (m, v) => v > m ? v : m).toDouble() < target
            ? target
            : values.fold<int>(0, (m, v) => v > m ? v : m).toDouble())
        * 1.15;
    final avg = values.where((v) => v > 0).isEmpty
        ? 0
        : values.where((v) => v > 0).reduce((a, b) => a + b) ~/
            values.where((v) => v > 0).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('CALORIES · LAST 14 DAYS', style: AppText.label),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
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
                        Text('DAILY AVG', style: AppText.label),
                        const SizedBox(height: 4),
                        Text('$avg kcal',
                            style: AppText.bigNumber.copyWith(fontSize: 22)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('TARGET', style: AppText.label),
                      const SizedBox(height: 4),
                      Text('${target.round()} kcal',
                          style: AppText.bigNumber.copyWith(
                              fontSize: 16,
                              color: AppColors.textTertiary)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 140,
                child: _CalorieChart(
                  values: values.map((v) => v.toDouble()).toList(),
                  target: target,
                  maxY: maxY,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CalorieChart extends StatelessWidget {
  final List<double> values;
  final double target;
  final double maxY;
  const _CalorieChart({
    required this.values,
    required this.target,
    required this.maxY,
  });

  @override
  Widget build(BuildContext context) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceBetween,
        maxY: maxY <= 0 ? 100 : maxY,
        minY: 0,
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        extraLinesData: ExtraLinesData(horizontalLines: [
          HorizontalLine(
            y: target,
            color: AppColors.textTertiary.withValues(alpha: 0.4),
            strokeWidth: 1,
            dashArray: const [5, 5],
          ),
        ]),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => AppColors.surfaceHigh,
            tooltipRoundedRadius: 10,
            getTooltipItem: (group, _, rod, _) {
              return BarTooltipItem(
                '${rod.toY.round()} kcal',
                TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              );
            },
          ),
        ),
        barGroups: [
          for (var i = 0; i < values.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: values[i],
                  width: 9,
                  borderRadius: BorderRadius.circular(3),
                  color: values[i] >= target * 0.85
                      ? AppColors.accent
                      : AppColors.accent.withValues(alpha: 0.45),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// ----------------------- STRENGTH ------------------------------------------

class _StrengthSection extends StatefulWidget {
  final List<WorkoutSession> sessions;
  const _StrengthSection({required this.sessions});

  @override
  State<_StrengthSection> createState() => _StrengthSectionState();
}

class _StrengthSectionState extends State<_StrengthSection> {
  int? _exerciseId;

  @override
  Widget build(BuildContext context) {
    final exerciseStats = _topExercises(widget.sessions);
    if (exerciseStats.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('STRENGTH', style: AppText.label),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.stroke),
            ),
            child: Text(
              'Log a workout to see strength progression.',
              style: AppText.body.copyWith(fontSize: 13),
            ),
          ),
        ],
      );
    }
    final selectedId = _exerciseId ?? exerciseStats.first.id;
    final selectedName = exerciseStats
        .firstWhere((e) => e.id == selectedId,
            orElse: () => exerciseStats.first)
        .name;
    final spots = _spotsFor(widget.sessions, selectedId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('STRENGTH · EST. 1RM', style: AppText.label),
        const SizedBox(height: 10),
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: exerciseStats.length,
            separatorBuilder: (_, _) => const SizedBox(width: 6),
            itemBuilder: (_, i) {
              final e = exerciseStats[i];
              final selected = e.id == selectedId;
              return GestureDetector(
                onTap: () => setState(() => _exerciseId = e.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.accent
                        : AppColors.surfaceHigh,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected
                          ? AppColors.accent
                          : AppColors.stroke,
                    ),
                  ),
                  child: Text(
                    e.name,
                    style: TextStyle(
                      color: selected
                          ? AppColors.onAccent
                          : AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.stroke),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(selectedName,
                  style: AppText.sectionTitle.copyWith(fontSize: 15)),
              const SizedBox(height: 12),
              SizedBox(
                height: 140,
                child: spots.length < 2
                    ? Center(
                        child: Text(
                          'Log this exercise more than once to see progression.',
                          textAlign: TextAlign.center,
                          style: AppText.body.copyWith(fontSize: 13),
                        ),
                      )
                    : _StrengthChart(spots: spots),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<_ExStat> _topExercises(List<WorkoutSession> sessions) {
    final counts = <int, _ExStat>{};
    for (final s in sessions) {
      for (final set in s.sets) {
        final stat = counts.putIfAbsent(
            set.exerciseId,
            () => _ExStat(
                id: set.exerciseId, name: set.exerciseName, sets: 0));
        stat.sets++;
      }
    }
    final list = counts.values.toList()
      ..sort((a, b) => b.sets.compareTo(a.sets));
    return list.take(8).toList();
  }

  List<FlSpot> _spotsFor(List<WorkoutSession> sessions, int exerciseId) {
    // One point per session that contains the exercise: best e1RM that session.
    final perSession = <DateTime, double>{};
    for (final s in sessions) {
      double best = 0;
      for (final set in s.sets) {
        if (set.exerciseId != exerciseId) continue;
        final e = PrTracker.estimatedFromSet(set);
        if (e > best) best = e;
      }
      if (best > 0) perSession[s.startedAt] = best;
    }
    if (perSession.isEmpty) return const [];
    final ordered = perSession.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final firstMs = ordered.first.key.millisecondsSinceEpoch.toDouble();
    return [
      for (final e in ordered)
        FlSpot(
            (e.key.millisecondsSinceEpoch - firstMs) /
                (1000 * 60 * 60 * 24),
            e.value),
    ];
  }
}

class _ExStat {
  final int id;
  final String name;
  int sets;
  _ExStat({required this.id, required this.name, required this.sets});
}

class _StrengthChart extends StatelessWidget {
  final List<FlSpot> spots;
  const _StrengthChart({required this.spots});

  @override
  Widget build(BuildContext context) {
    final minY = (spots.map((s) => s.y).reduce((a, b) => a < b ? a : b) * 0.92)
        .floorToDouble();
    final maxY = (spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) * 1.08)
        .ceilToDouble();
    return LineChart(
      LineChartData(
        minX: 0,
        maxX: spots.last.x == 0 ? 1 : spots.last.x,
        minY: minY,
        maxY: maxY,
        gridData: FlGridData(
          drawVerticalLine: false,
          horizontalInterval: ((maxY - minY) / 3).clamp(1, 100),
          getDrawingHorizontalLine: (_) => FlLine(
            color: AppColors.stroke,
            strokeWidth: 1,
            dashArray: const [4, 4],
          ),
        ),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => AppColors.surfaceHigh,
            tooltipRoundedRadius: 10,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                return LineTooltipItem(
                  '${spot.y.toStringAsFixed(1)} kg',
                  TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                );
              }).toList();
            },
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.25,
            barWidth: 2.5,
            color: AppColors.calorieFrom,
            dotData: FlDotData(
              show: true,
              getDotPainter: (_, _, _, _) => FlDotCirclePainter(
                radius: 2.5,
                color: AppColors.calorieFrom,
                strokeColor: AppColors.bg,
                strokeWidth: 1,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.calorieFrom.withValues(alpha: 0.22),
                  AppColors.calorieFrom.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ----------------------- PHOTOS --------------------------------------------

class _PhotosSection extends StatelessWidget {
  final List<BodyMeasurement> measurements;
  const _PhotosSection({required this.measurements});

  @override
  Widget build(BuildContext context) {
    final withPhotos =
        measurements.where((m) => m.photoPath != null).toList();
    if (withPhotos.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('PROGRESS PHOTOS', style: AppText.label),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.stroke),
            ),
            child: Row(
              children: [
                Icon(Icons.lock_outline_rounded,
                    size: 16, color: AppColors.textTertiary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Attach a photo when you log a measurement. Stays on device.',
                    style: AppText.body.copyWith(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text('PROGRESS PHOTOS', style: AppText.label)),
            Row(
              children: [
                Icon(Icons.lock_outline_rounded,
                    size: 12, color: AppColors.textTertiary),
                const SizedBox(width: 4),
                Text('On device only',
                    style: AppText.label
                        .copyWith(color: AppColors.textTertiary)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 130,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: withPhotos.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final m = withPhotos[i];
              return GestureDetector(
                onTap: () => _viewPhoto(context, m),
                child: Container(
                  width: 100,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.stroke),
                    image: DecorationImage(
                      image: FileImage(File(m.photoPath!)),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: Container(
                      margin: const EdgeInsets.all(6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        DateFormat('MMM d').format(m.date),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _viewPhoto(BuildContext context, BodyMeasurement m) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _PhotoViewer(measurement: m),
    ));
  }
}

class _PhotoViewer extends StatelessWidget {
  final BodyMeasurement measurement;
  const _PhotoViewer({required this.measurement});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          DateFormat('MMM d, yyyy').format(measurement.date),
          style: const TextStyle(color: Colors.white, fontSize: 15),
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.file(File(measurement.photoPath!)),
        ),
      ),
    );
  }
}
