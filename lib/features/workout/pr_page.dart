import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../services/workout/pr_tracker.dart';
import '../../state/providers.dart';
import '../../theme.dart';

class PrPage extends ConsumerWidget {
  const PrPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(allSessionsProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        title: Text('Personal records', style: AppText.sectionTitle),
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      body: SafeArea(
        child: sessionsAsync.when(
          loading: () => Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                  strokeWidth: 2.2, color: AppColors.accent),
            ),
          ),
          error: (_, _) => const SizedBox.shrink(),
          data: (sessions) {
            final prs = PrTracker.personalRecords(sessions);
            if (prs.isEmpty) return const _Empty();
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              itemCount: prs.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _PrRow(pr: prs[i]),
            );
          },
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(Icons.emoji_events_rounded,
                  size: 28, color: AppColors.accent),
            ),
            const SizedBox(height: 18),
            Text('No records yet',
                style: AppText.sectionTitle.copyWith(fontSize: 17)),
            const SizedBox(height: 6),
            Text(
              'Log a workout — your best estimated 1-rep max for each exercise lands here.',
              textAlign: TextAlign.center,
              style: AppText.body,
            ),
          ],
        ),
      ),
    );
  }
}

class _PrRow extends StatelessWidget {
  final PrEntry pr;
  const _PrRow({required this.pr});

  @override
  Widget build(BuildContext context) {
    final w = pr.weightKg;
    final wStr =
        w == w.roundToDouble() ? w.toInt().toString() : w.toStringAsFixed(1);
    final e = pr.estimated1RM;
    final eStr =
        e == e.roundToDouble() ? e.toInt().toString() : e.toStringAsFixed(1);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.emoji_events_rounded,
                size: 18, color: AppColors.accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(pr.exerciseName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.body.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
                const SizedBox(height: 2),
                Text(
                  pr.weightKg > 0
                      ? '$wStr kg × ${pr.reps} · ${DateFormat('MMM d').format(pr.achievedAt)}'
                      : '${pr.reps} reps · ${DateFormat('MMM d').format(pr.achievedAt)}',
                  style: AppText.meta.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$eStr kg',
                  style: AppText.bigNumber.copyWith(fontSize: 16)),
              Text('est. 1RM',
                  style: AppText.meta.copyWith(
                      fontSize: 10, color: AppColors.textTertiary)),
            ],
          ),
        ],
      ),
    );
  }
}
