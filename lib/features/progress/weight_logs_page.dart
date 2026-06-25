import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/body_measurement.dart';
import '../../services/ai/ai_service.dart';
import '../../state/providers.dart';
import '../../theme.dart';
import 'measurement_entry_sheet.dart';

/// Full list of body-measurement logs (weight + optional metrics) with
/// inline edit/delete and an AI summary that watches the trend.
class WeightLogsPage extends ConsumerStatefulWidget {
  const WeightLogsPage({super.key});

  @override
  ConsumerState<WeightLogsPage> createState() => _WeightLogsPageState();
}

class _WeightLogsPageState extends ConsumerState<WeightLogsPage> {
  static const _cacheKey = 'weightLogs.aiSummary';
  static const _cacheTsKey = 'weightLogs.aiSummary.ts';
  static const _cacheCountKey = 'weightLogs.aiSummary.count';

  String? _aiSummary;
  bool _aiLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCachedSummary();
  }

  Future<void> _loadCachedSummary() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _aiSummary = prefs.getString(_cacheKey));
  }

  Future<void> _generateSummary(
      List<BodyMeasurement> measurements) async {
    if (_aiLoading) return;
    setState(() => _aiLoading = true);
    try {
      final ctx = _buildContext(measurements);
      final ai = ref.read(aiServiceProvider);
      final text = await ai.coachChat(
        userContext: ctx,
        history: const [],
        latestUserMessage:
            'Give me a brief 2-3 sentence read on this person\'s body '
            'measurement trend. Highlight one win and one thing to watch. '
            'Be specific with numbers.',
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, text);
      await prefs.setInt(
          _cacheTsKey, DateTime.now().millisecondsSinceEpoch);
      await prefs.setInt(_cacheCountKey, measurements.length);
      if (!mounted) return;
      setState(() => _aiSummary = text);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: AppColors.surfaceHigh,
        content: Text(
          e is AiException ? e.message : 'AI failed.',
          style: AppText.body.copyWith(color: AppColors.textPrimary),
        ),
      ));
    } finally {
      if (mounted) setState(() => _aiLoading = false);
    }
  }

  String _buildContext(List<BodyMeasurement> measurements) {
    final ordered = measurements.toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    final first = ordered.first;
    final latest = ordered.last;
    final dWeight = latest.weightKg - first.weightKg;
    final lines = <String>[
      'Logs: ${ordered.length}',
      'First: ${DateFormat('MMM d, y').format(first.date)} · '
          '${first.weightKg.toStringAsFixed(1)} kg',
      'Latest: ${DateFormat('MMM d, y').format(latest.date)} · '
          '${latest.weightKg.toStringAsFixed(1)} kg',
      'Net weight change: ${dWeight >= 0 ? '+' : ''}${dWeight.toStringAsFixed(1)} kg',
    ];
    if (latest.bodyFatPct != null) {
      lines.add('Latest body fat: ${latest.bodyFatPct!.toStringAsFixed(1)}%');
    }
    if (latest.waistCm != null) {
      lines.add('Latest waist: ${latest.waistCm!.toStringAsFixed(1)} cm');
    }
    if (latest.chestCm != null) {
      lines.add('Latest chest: ${latest.chestCm!.toStringAsFixed(1)} cm');
    }
    if (latest.armCm != null) {
      lines.add('Latest arm: ${latest.armCm!.toStringAsFixed(1)} cm');
    }
    if (latest.thighCm != null) {
      lines.add('Latest thigh: ${latest.thighCm!.toStringAsFixed(1)} cm');
    }
    final notes = ordered
        .where((m) => (m.note ?? '').trim().isNotEmpty)
        .take(3)
        .map((m) =>
            '- ${DateFormat('MMM d').format(m.date)}: ${m.note!.trim()}')
        .join('\n');
    if (notes.isNotEmpty) lines.add('Recent notes:\n$notes');
    return lines.join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final measurementsAsync = ref.watch(measurementsProvider);
    final ordered = (measurementsAsync.valueOrNull ?? const <BodyMeasurement>[])
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        title: Text('Body Logs', style: AppText.sectionTitle),
        iconTheme: IconThemeData(color: AppColors.textPrimary),
        actions: [
          IconButton(
            icon: Icon(Icons.add_rounded, color: AppColors.accent),
            tooltip: 'Add log',
            onPressed: () => MeasurementEntrySheet.show(context),
          ),
        ],
      ),
      body: SafeArea(
        child: ordered.isEmpty
            ? _EmptyState(
                onLog: () => MeasurementEntrySheet.show(context),
              )
            : CustomScrollView(
                physics: const ClampingScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                    sliver: SliverList.list(children: [
                      _AiInsightsCard(
                        text: _aiSummary,
                        loading: _aiLoading,
                        onGenerate: () => _generateSummary(ordered),
                      ),
                      const SizedBox(height: 16),
                      Text('ALL LOGS · ${ordered.length}',
                          style: AppText.label.copyWith(
                              fontSize: 10,
                              letterSpacing: 0.8,
                              color: AppColors.textTertiary)),
                      const SizedBox(height: 10),
                      for (var i = 0; i < ordered.length; i++) ...[
                        _WeightLogRow(
                          measurement: ordered[i],
                          previous: i + 1 < ordered.length
                              ? ordered[i + 1]
                              : null,
                        ),
                        const SizedBox(height: 8),
                      ],
                    ]),
                  ),
                ],
              ),
      ),
    );
  }
}

// ---------------------------------------------------------------------
// AI insights card
// ---------------------------------------------------------------------

class _AiInsightsCard extends StatelessWidget {
  final String? text;
  final bool loading;
  final VoidCallback onGenerate;
  const _AiInsightsCard({
    required this.text,
    required this.loading,
    required this.onGenerate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
            children: [
              Icon(Icons.auto_awesome_rounded,
                  size: 16, color: AppColors.accent),
              const SizedBox(width: 8),
              Text('AI TRACKING',
                  style: AppText.label.copyWith(
                    color: AppColors.accent,
                    fontSize: 10,
                    letterSpacing: 0.8,
                  )),
              const Spacer(),
              if (text != null && !loading)
                GestureDetector(
                  onTap: onGenerate,
                  behavior: HitTestBehavior.opaque,
                  child: Icon(Icons.refresh_rounded,
                      size: 16, color: AppColors.textTertiary),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (loading)
            const SizedBox(
              height: 24,
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2.2),
                ),
              ),
            )
          else if (text == null)
            GestureDetector(
              onTap: onGenerate,
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.auto_awesome_rounded,
                        size: 14, color: AppColors.accent),
                    const SizedBox(width: 8),
                    Text('Generate insights from your logs',
                        style: AppText.body.copyWith(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        )),
                  ],
                ),
              ),
            )
          else
            Text(text!,
                style: AppText.body.copyWith(
                  color: AppColors.textPrimary,
                  height: 1.4,
                  fontSize: 14,
                )),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Log row
// ---------------------------------------------------------------------

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

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateLabel =
        DateFormat('MMM d, y · h:mm a').format(measurement.date);
    final delta =
        previous != null ? measurement.weightKg - previous!.weightKg : null;
    final suspicious = delta != null && delta.abs() >= 5;
    final chips = _statChips(measurement);
    final hasPhoto =
        measurement.photoPath != null && measurement.photoPath!.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(
            color: suspicious
                ? AppColors.danger.withValues(alpha: 0.45)
                : AppColors.stroke),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasPhoto) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      File(measurement.photoPath!),
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        width: 56,
                        height: 56,
                        color: AppColors.surfaceHigh,
                        alignment: Alignment.center,
                        child: Icon(Icons.broken_image_rounded,
                            color: AppColors.textTertiary, size: 22),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(measurement.weightKg.toStringAsFixed(1),
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
                        Text(
                            'Looks like a big jump — edit if this is a typo.',
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
          if (chips.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: chips,
              ),
            ),
          if ((measurement.note ?? '').trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Container(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceHigh,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.notes_rounded,
                        size: 12, color: AppColors.textTertiary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        measurement.note!.trim(),
                        style: AppText.body.copyWith(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontStyle: FontStyle.italic,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _statChips(BodyMeasurement m) {
    final chips = <Widget>[];
    if (m.bodyFatPct != null) {
      chips.add(_StatChip(
          label: 'Body fat',
          value: '${m.bodyFatPct!.toStringAsFixed(1)}%'));
    }
    if (m.waistCm != null) {
      chips.add(_StatChip(
          label: 'Waist',
          value: '${m.waistCm!.toStringAsFixed(1)} cm'));
    }
    if (m.chestCm != null) {
      chips.add(_StatChip(
          label: 'Chest',
          value: '${m.chestCm!.toStringAsFixed(1)} cm'));
    }
    if (m.armCm != null) {
      chips.add(_StatChip(
          label: 'Arm', value: '${m.armCm!.toStringAsFixed(1)} cm'));
    }
    if (m.thighCm != null) {
      chips.add(_StatChip(
          label: 'Thigh',
          value: '${m.thighCm!.toStringAsFixed(1)} cm'));
    }
    return chips;
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

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: AppText.meta.copyWith(
                  fontSize: 10,
                  color: AppColors.textTertiary,
                  fontWeight: FontWeight.w700)),
          const SizedBox(width: 6),
          Text(value,
              style: AppText.body.copyWith(
                  fontSize: 12,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800)),
        ],
      ),
    );
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

class _EmptyState extends StatelessWidget {
  final VoidCallback onLog;
  const _EmptyState({required this.onLog});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.monitor_weight_rounded,
                size: 36, color: AppColors.textTertiary),
            const SizedBox(height: 10),
            Text('No logs yet',
                style: AppText.sectionTitle.copyWith(fontSize: 16)),
            const SizedBox(height: 6),
            Text(
              'Log your weight, measurements, and a private photo to see '
              'your trend and let the AI track your progress.',
              textAlign: TextAlign.center,
              style: AppText.body.copyWith(fontSize: 13),
            ),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: onLog,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text('Add first log',
                    style: TextStyle(
                      color: AppColors.onAccent,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    )),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
