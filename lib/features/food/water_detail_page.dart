import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/models/daily_log.dart';
import '../../services/notifications/notification_service.dart';
import '../../state/providers.dart';
import '../../theme.dart';

// ─── public entry point ────────────────────────────────────────────────────

class WaterDetailPage extends ConsumerWidget {
  const WaterDetailPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileStreamProvider).valueOrNull;
    final log = ref.watch(todayLogProvider).valueOrNull;

    final consumedMl = log?.waterMl ?? 0;
    final targetMl = profile?.effectiveWaterTarget ?? 0;
    final entries = log?.waterEntries ?? const <WaterEntry>[];
    final sortedEntries = List<WaterEntry>.of(entries)
      ..sort((a, b) => b.minutesOfDay.compareTo(a.minutesOfDay));

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _WaterSliverAppBar(consumedMl: consumedMl, targetMl: targetMl),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SummaryCard(consumedMl: consumedMl, targetMl: targetMl)
                      .animate()
                      .fadeIn(duration: 300.ms)
                      .slideY(begin: 0.06, end: 0),
                  const SizedBox(height: 18),
                  _QuickAddRow()
                      .animate(delay: 80.ms)
                      .fadeIn(duration: 300.ms)
                      .slideY(begin: 0.06, end: 0),
                  const SizedBox(height: 22),
                  _ReminderTile()
                      .animate(delay: 140.ms)
                      .fadeIn(duration: 300.ms)
                      .slideY(begin: 0.06, end: 0),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: Text('TODAY\'S SIPS',
                            style: AppText.label.copyWith(fontSize: 11)),
                      ),
                      if (sortedEntries.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.water.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${sortedEntries.length}',
                            style: AppText.label.copyWith(
                              fontSize: 10,
                              color: AppColors.water,
                              letterSpacing: 0,
                            ),
                          ),
                        ),
                    ],
                  ).animate(delay: 180.ms).fadeIn(duration: 280.ms),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
          if (sortedEntries.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                child: _EmptyState()
                    .animate(delay: 220.ms)
                    .fadeIn(duration: 350.ms)
                    .scale(
                        begin: const Offset(0.96, 0.96),
                        end: const Offset(1, 1)),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              sliver: SliverList.separated(
                itemCount: sortedEntries.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (ctx, i) {
                  int findOriginal() => entries.indexWhere((e) =>
                      e.minutesOfDay == sortedEntries[i].minutesOfDay &&
                      e.ml == sortedEntries[i].ml);
                  return _SipTile(
                    entry: sortedEntries[i],
                    onDelete: () async {
                      final originalIndex = findOriginal();
                      if (originalIndex < 0) return;
                      await ref
                          .read(nutritionRepoProvider)
                          .removeWaterEntryAt(
                              ref.read(todayProvider), originalIndex);
                    },
                    onEdit: () async {
                      final originalIndex = findOriginal();
                      if (originalIndex < 0) return;
                      await _showEditSheet(
                        context,
                        ref,
                        entry: sortedEntries[i],
                        index: originalIndex,
                      );
                    },
                    index: i,
                  )
                      .animate(delay: Duration(milliseconds: 240 + i * 50))
                      .fadeIn(duration: 280.ms)
                      .slideX(begin: -0.05, end: 0);
                },
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }
}

// ─── sliver app bar ────────────────────────────────────────────────────────

class _WaterSliverAppBar extends StatelessWidget {
  final int consumedMl;
  final int targetMl;
  const _WaterSliverAppBar({
    required this.consumedMl,
    required this.targetMl,
  });

  @override
  Widget build(BuildContext context) {
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
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: AppColors.water.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(Icons.water_drop_rounded,
                  size: 16, color: AppColors.water),
            ),
            const SizedBox(width: 10),
            Text('Water', style: AppText.sectionTitle.copyWith(fontSize: 18)),
          ],
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.water.withValues(alpha: 0.10),
                AppColors.bg,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── hero summary ──────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final int consumedMl;
  final int targetMl;
  const _SummaryCard({required this.consumedMl, required this.targetMl});

  @override
  Widget build(BuildContext context) {
    final progress =
        targetMl == 0 ? 0.0 : (consumedMl / targetMl).clamp(0.0, 1.0);
    final remainingMl = math.max(0, targetMl - consumedMl);
    final done = remainingMl == 0 && targetMl > 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.stroke),
        boxShadow: [
          BoxShadow(
            color: AppColors.water.withValues(alpha: 0.10),
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('CONSUMED', style: AppText.label.copyWith(fontSize: 10)),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: consumedMl.toDouble()),
                        duration: const Duration(milliseconds: 700),
                        curve: Curves.easeOutCubic,
                        builder: (_, v, _) => Text(
                          (v / 1000).toStringAsFixed(1),
                          style: AppText.bigNumber.copyWith(
                            fontSize: 36,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text('L',
                          style: AppText.meta.copyWith(
                              fontSize: 14,
                              color: AppColors.textSecondary)),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              if (targetMl > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceHigh,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: AppColors.stroke),
                  ),
                  child: Column(
                    children: [
                      Text('TARGET', style: AppText.label.copyWith(fontSize: 9)),
                      const SizedBox(height: 2),
                      Text(
                        (targetMl / 1000).toStringAsFixed(1),
                        style: AppText.meta.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text('L',
                          style: AppText.meta.copyWith(
                              fontSize: 10, color: AppColors.textTertiary)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          // Wave-style progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: Stack(
              children: [
                Container(height: 14, color: AppColors.surfaceHigh),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: progress),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOutCubic,
                  builder: (_, v, _) => FractionallySizedBox(
                    widthFactor: v,
                    child: Container(
                      height: 14,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.water,
                            AppColors.water.withValues(alpha: 0.7),
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
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (done ? AppColors.success : AppColors.water)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  done
                      ? 'Hydration goal hit ✓'
                      : '${(remainingMl / 1000).toStringAsFixed(1)}L to go',
                  style: AppText.meta.copyWith(
                    fontSize: 11,
                    color: done ? AppColors.success : AppColors.water,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${(progress * 100).round()}%',
                style: AppText.meta.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
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

// ─── quick add buttons ─────────────────────────────────────────────────────

class _QuickAddRow extends ConsumerStatefulWidget {
  @override
  ConsumerState<_QuickAddRow> createState() => _QuickAddRowState();
}

class _QuickAddRowState extends ConsumerState<_QuickAddRow> {
  static const _options = <(int, String, IconData)>[
    (200, '200', Icons.local_cafe_rounded),
    (250, '250', Icons.local_drink_rounded),
    (500, '500', Icons.water_drop_rounded),
    (750, '750', Icons.sports_bar_rounded),
  ];

  Future<void> _add(int ml) async {
    await ref
        .read(nutritionRepoProvider)
        .addWater(ref.read(todayProvider), ml);
  }

  Future<void> _addCustom() async {
    final ml = await showDialog<int>(
      context: context,
      builder: (ctx) => _CustomAmountDialog(),
    );
    if (ml != null && ml > 0) await _add(ml);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('QUICK ADD', style: AppText.label.copyWith(fontSize: 11)),
        const SizedBox(height: 10),
        Row(
          children: [
            for (var i = 0; i < _options.length; i++) ...[
              Expanded(
                child: _QuickAddButton(
                  ml: _options[i].$1,
                  label: _options[i].$2,
                  icon: _options[i].$3,
                  onTap: () => _add(_options[i].$1),
                ),
              ),
              if (i < _options.length - 1) const SizedBox(width: 8),
            ],
          ],
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: _addCustom,
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.stroke),
            ),
            child: Row(
              children: [
                Icon(Icons.edit_rounded,
                    size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Text('Custom amount…',
                    style: AppText.body.copyWith(
                        fontSize: 13, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _QuickAddButton extends StatefulWidget {
  final int ml;
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _QuickAddButton({
    required this.ml,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_QuickAddButton> createState() => _QuickAddButtonState();
}

class _QuickAddButtonState extends State<_QuickAddButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
  );

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  void _tap() {
    _ctl.forward(from: 0);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _tap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _ctl,
        builder: (ctx, _) {
          final scale = 1.0 - 0.06 * (1 - (1 - _ctl.value).abs());
          return Transform.scale(
            scale: scale,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.water.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: AppColors.water.withValues(alpha: 0.30)),
              ),
              child: Column(
                children: [
                  Icon(widget.icon, size: 18, color: AppColors.water),
                  const SizedBox(height: 4),
                  Text(widget.label,
                      style: AppText.bigNumber.copyWith(
                          fontSize: 14, color: AppColors.textPrimary)),
                  Text('ml',
                      style: AppText.label.copyWith(
                          fontSize: 9,
                          color: AppColors.textTertiary,
                          letterSpacing: 0.4)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CustomAmountDialog extends StatefulWidget {
  @override
  State<_CustomAmountDialog> createState() => _CustomAmountDialogState();
}

class _CustomAmountDialogState extends State<_CustomAmountDialog> {
  final _ctl = TextEditingController();

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Custom amount',
                style: AppText.sectionTitle.copyWith(fontSize: 17)),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceHigh,
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
                      cursorColor: AppColors.water,
                      keyboardType: TextInputType.number,
                      style: AppText.bigNumber.copyWith(fontSize: 22),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        isCollapsed: true,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 14),
                        hintText: '0',
                        hintStyle: AppText.bigNumber.copyWith(
                            fontSize: 22, color: AppColors.textTertiary),
                      ),
                    ),
                  ),
                  Text('ml',
                      style: AppText.meta.copyWith(
                          fontSize: 13, color: AppColors.textTertiary)),
                ],
              ),
            ),
            const SizedBox(height: 16),
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
                  onPressed: () => Navigator.of(context)
                      .pop(int.tryParse(_ctl.text.trim())),
                  child: Text('Add',
                      style: AppText.body.copyWith(
                          color: AppColors.water,
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

// ─── reminder toggle tile ─────────────────────────────────────────────────

class _ReminderTile extends ConsumerStatefulWidget {
  @override
  ConsumerState<_ReminderTile> createState() => _ReminderTileState();
}

class _ReminderTileState extends ConsumerState<_ReminderTile> {
  bool _busy = false;

  Future<void> _toggle(bool on) async {
    setState(() => _busy = true);
    try {
      final settings = ref.read(appSettingsProvider);
      await settings.setWaterRemindersEnabled(on);
      final profile = await ref.read(profileRepoProvider).getCurrent();
      final notif = NotificationService.instance;
      if (on) {
        final todayWeekday = DateTime.now().weekday;
        await notif.scheduleWaterReminders(
          intervalHours: settings.waterIntervalHours,
          wakeMin: profile?.wakeMinFor(todayWeekday),
          sleepMin: profile?.sleepMinFor(todayWeekday),
          mealTimesMin:
              settings.mealRemindersEnabled ? settings.mealTimes : const [],
        );
      } else {
        await notif.cancelWaterReminders();
      }
      if (mounted) setState(() {});
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _windowSummary() {
    final settings = ref.read(appSettingsProvider);
    final profile = ref.read(profileStreamProvider).valueOrNull;
    final todayWeekday = DateTime.now().weekday;
    final wake = profile?.wakeMinFor(todayWeekday) ?? 8 * 60;
    final sleep = profile?.sleepMinFor(todayWeekday) ?? 21 * 60;
    final endMin = (sleep - 60).clamp(0, 1439);
    String fmt(int m) {
      final h = m ~/ 60;
      final mm = m % 60;
      final p = h >= 12 ? 'PM' : 'AM';
      final h12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
      return '$h12:${mm.toString().padLeft(2, '0')} $p';
    }
    return 'Every ${settings.waterIntervalHours} hr · ${fmt(wake)} – ${fmt(endMin)}';
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider);
    final on = settings.waterRemindersEnabled;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: on
            ? AppColors.water.withValues(alpha: 0.06)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: on
                ? AppColors.water.withValues(alpha: 0.30)
                : AppColors.stroke),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.water.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.notifications_active_rounded,
                size: 18, color: AppColors.water),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Water reminders',
                  style: AppText.body.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  on
                      ? _windowSummary()
                      : 'Stay hydrated — flip on for smart nudges.',
                  style: AppText.meta.copyWith(fontSize: 11.5, height: 1.35),
                ),
                if (on) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Skips meal windows (-20/+45 min) and stops an hour before bed.',
                    style: AppText.meta.copyWith(
                        fontSize: 10.5,
                        color: AppColors.textTertiary,
                        height: 1.3),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 6),
          _busy
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.water),
                )
              : Switch.adaptive(
                  value: on,
                  activeThumbColor: AppColors.water,
                  onChanged: _toggle,
                ),
        ],
      ),
    );
  }
}

// ─── sip tile ──────────────────────────────────────────────────────────────

class _SipTile extends StatelessWidget {
  final WaterEntry entry;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final int index;
  const _SipTile({
    required this.entry,
    required this.onDelete,
    required this.onEdit,
    required this.index,
  });

  String _formatTime() {
    final h = entry.minutesOfDay ~/ 60;
    final m = entry.minutesOfDay % 60;
    final dt = DateTime(2000, 1, 1, h, m);
    return DateFormat('h:mm a').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final mlText = entry.ml >= 1000
        ? '${(entry.ml / 1000).toStringAsFixed(1)}L'
        : '${entry.ml}ml';
    return Dismissible(
      key: ValueKey('water-$index-${entry.minutesOfDay}-${entry.ml}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(Icons.delete_outline_rounded,
            color: AppColors.danger, size: 22),
      ),
      onDismissed: (_) => onDelete(),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onEdit,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.stroke),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.water.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.water_drop_rounded,
                    size: 16, color: AppColors.water),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mlText,
                      style: AppText.body.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 14.5,
                      ),
                    ),
                    Text(
                      _formatTime(),
                      style: AppText.meta.copyWith(
                          fontSize: 11.5, color: AppColors.textTertiary),
                    ),
                  ],
                ),
              ),
              Icon(Icons.edit_outlined,
                  size: 16, color: AppColors.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── edit sheet ────────────────────────────────────────────────────────────

Future<void> _showEditSheet(
  BuildContext context,
  WidgetRef ref, {
  required WaterEntry entry,
  required int index,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (ctx) => _EditSipSheet(entry: entry, index: index),
  );
}

class _EditSipSheet extends ConsumerStatefulWidget {
  final WaterEntry entry;
  final int index;
  const _EditSipSheet({required this.entry, required this.index});

  @override
  ConsumerState<_EditSipSheet> createState() => _EditSipSheetState();
}

class _EditSipSheetState extends ConsumerState<_EditSipSheet> {
  late int _ml = widget.entry.ml;
  late TimeOfDay _time = TimeOfDay(
      hour: widget.entry.minutesOfDay ~/ 60,
      minute: widget.entry.minutesOfDay % 60);
  late final TextEditingController _mlCtl =
      TextEditingController(text: widget.entry.ml.toString());

  @override
  void dispose() {
    _mlCtl.dispose();
    super.dispose();
  }

  String _fmtTime(TimeOfDay t) {
    final dt = DateTime(2000, 1, 1, t.hour, t.minute);
    return DateFormat('h:mm a').format(dt);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme.copyWith(
                primary: AppColors.water,
              ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _save() async {
    final parsed = int.tryParse(_mlCtl.text.trim());
    if (parsed == null || parsed <= 0) return;
    await ref.read(nutritionRepoProvider).updateWaterEntryAt(
          ref.read(todayProvider),
          widget.index,
          ml: parsed,
          minutesOfDay: _time.hour * 60 + _time.minute,
        );
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    await ref
        .read(nutritionRepoProvider)
        .removeWaterEntryAt(ref.read(todayProvider), widget.index);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 18, 20, 20 + viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.stroke,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.water.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.water_drop_rounded,
                    size: 16, color: AppColors.water),
              ),
              const SizedBox(width: 10),
              Text('Edit sip',
                  style: AppText.sectionTitle.copyWith(fontSize: 17)),
            ],
          ),
          const SizedBox(height: 16),
          Text('AMOUNT', style: AppText.label.copyWith(fontSize: 11)),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceHigh,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.stroke),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _mlCtl,
                    cursorColor: AppColors.water,
                    keyboardType: TextInputType.number,
                    style: AppText.bigNumber.copyWith(fontSize: 22),
                    onChanged: (v) => setState(() => _ml = int.tryParse(v) ?? _ml),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      isCollapsed: true,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                Text('ml',
                    style: AppText.meta.copyWith(
                        fontSize: 13, color: AppColors.textTertiary)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text('TIME', style: AppText.label.copyWith(fontSize: 11)),
          const SizedBox(height: 6),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _pickTime,
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              decoration: BoxDecoration(
                color: AppColors.surfaceHigh,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.stroke),
              ),
              child: Row(
                children: [
                  Icon(Icons.schedule_rounded,
                      size: 16, color: AppColors.water),
                  const SizedBox(width: 10),
                  Text(_fmtTime(_time),
                      style: AppText.body.copyWith(
                          fontSize: 15, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  Icon(Icons.chevron_right_rounded,
                      size: 18, color: AppColors.textTertiary),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _delete,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: AppColors.danger.withValues(alpha: 0.35)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.delete_outline_rounded,
                            size: 16, color: AppColors.danger),
                        const SizedBox(width: 6),
                        Text('Delete',
                            style: AppText.body.copyWith(
                                color: AppColors.danger,
                                fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _ml > 0 ? _save : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.water,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text('Save',
                          style: AppText.body.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── empty state ───────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
              color: AppColors.water.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.water_drop_rounded,
                size: 26, color: AppColors.water),
          ),
          const SizedBox(height: 14),
          Text('No sips yet today',
              style: AppText.sectionTitle.copyWith(fontSize: 16)),
          const SizedBox(height: 6),
          Text(
            'Tap a quick-add button above. Each sip lands here with the time.',
            textAlign: TextAlign.center,
            style: AppText.body.copyWith(fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }
}
