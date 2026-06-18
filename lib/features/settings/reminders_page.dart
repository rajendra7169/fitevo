import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/notifications/notification_service.dart';
import '../../state/providers.dart';
import '../../theme.dart';

class RemindersPage extends ConsumerStatefulWidget {
  const RemindersPage({super.key});

  @override
  ConsumerState<RemindersPage> createState() => _RemindersPageState();
}

class _RemindersPageState extends ConsumerState<RemindersPage> {
  late bool _waterEnabled;
  late int _waterInterval;
  late bool _mealEnabled;
  late List<int> _mealTimes;

  @override
  void initState() {
    super.initState();
    final s = ref.read(appSettingsProvider);
    _waterEnabled = s.waterRemindersEnabled;
    _waterInterval = s.waterIntervalHours;
    _mealEnabled = s.mealRemindersEnabled;
    _mealTimes = List.of(s.mealTimes);
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        backgroundColor: AppColors.surfaceHigh,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)),
        content: Text(msg,
            style: AppText.body.copyWith(color: AppColors.textPrimary)),
      ));
  }

  Future<void> _persistAndReschedule() async {
    final settings = ref.read(appSettingsProvider);
    await settings.setWaterRemindersEnabled(_waterEnabled);
    await settings.setWaterIntervalHours(_waterInterval);
    await settings.setMealRemindersEnabled(_mealEnabled);
    await settings.setMealTimes(_mealTimes);

    // Pull the user's wake/sleep window from Profile so water reminders
    // only fire when they're awake. Default to 8am-9pm if unset.
    final profile = await ref.read(profileRepoProvider).getCurrent();
    var startHour = 8;
    var endHour = 21;
    if (profile != null) {
      final wake = profile.wakeTimeMin;
      final sleep = profile.sleepTimeMin;
      if (wake >= 0 && wake <= 1439 && sleep >= 0 && sleep <= 1439) {
        startHour = wake ~/ 60;
        // End an hour before sleep so the user isn't woken to pee.
        endHour = ((sleep ~/ 60) - 1).clamp(startHour + 1, 23);
      }
    }

    final notif = NotificationService.instance;
    if (_waterEnabled) {
      await notif.scheduleWaterReminders(
        intervalHours: _waterInterval,
        startHour: startHour,
        endHour: endHour,
      );
    } else {
      await notif.cancelWaterReminders();
    }
    if (_mealEnabled) {
      await notif.scheduleMealReminders(_mealTimes);
    } else {
      await notif.cancelMealReminders();
    }
  }

  Future<void> _pickMealTime(int index) async {
    final mins = _mealTimes[index];
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: mins ~/ 60, minute: mins % 60),
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: Theme.of(ctx).colorScheme.copyWith(
                  primary: AppColors.accent,
                  onPrimary: Colors.black,
                  surface: AppColors.surface,
                  onSurface: AppColors.textPrimary,
                ),
          ),
          child: child!,
        );
      },
    );
    if (picked == null) return;
    setState(() => _mealTimes[index] = picked.hour * 60 + picked.minute);
    await _persistAndReschedule();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        title: Text('Reminders', style: AppText.sectionTitle),
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            Text('WATER', style: AppText.label),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.stroke),
              ),
              child: Column(
                children: [
                  SwitchListTile.adaptive(
                    value: _waterEnabled,
                    activeThumbColor: AppColors.accent,
                    title: Text('Water nudges',
                        style: AppText.body.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700)),
                    subtitle: Text('Between 8 AM and 9 PM, on your interval.',
                        style: AppText.meta.copyWith(fontSize: 12)),
                    onChanged: (v) async {
                      setState(() => _waterEnabled = v);
                      await _persistAndReschedule();
                      if (v) _toast('Water reminders on.');
                    },
                  ),
                  if (_waterEnabled) ...[
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('EVERY', style: AppText.label),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              for (final h in [1, 2, 3, 4]) ...[
                                Expanded(
                                  child: _PillButton(
                                    label:
                                        h == 1 ? '1 hr' : '$h hrs',
                                    selected: _waterInterval == h,
                                    onTap: () async {
                                      setState(() => _waterInterval = h);
                                      await _persistAndReschedule();
                                    },
                                  ),
                                ),
                                if (h != 4) const SizedBox(width: 8),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 22),
            Text('MEALS', style: AppText.label),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.stroke),
              ),
              child: Column(
                children: [
                  SwitchListTile.adaptive(
                    value: _mealEnabled,
                    activeThumbColor: AppColors.accent,
                    title: Text('Meal nudges',
                        style: AppText.body.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700)),
                    subtitle: Text(
                        'A gentle reminder to log around each meal.',
                        style: AppText.meta.copyWith(fontSize: 12)),
                    onChanged: (v) async {
                      setState(() => _mealEnabled = v);
                      await _persistAndReschedule();
                      if (v) _toast('Meal reminders on.');
                    },
                  ),
                  if (_mealEnabled) ...[
                    const Divider(height: 1),
                    for (var i = 0; i < _mealTimes.length; i++)
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 0),
                        leading: Icon(
                            i == 0
                                ? Icons.wb_sunny_rounded
                                : i == 1
                                    ? Icons.wb_twilight_rounded
                                    : Icons.dark_mode_rounded,
                            size: 18,
                            color: AppColors.accent),
                        title: Text(
                            i == 0
                                ? 'Breakfast'
                                : i == 1
                                    ? 'Lunch'
                                    : 'Dinner',
                            style: AppText.body.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 14)),
                        trailing: GestureDetector(
                          onTap: () => _pickMealTime(i),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceHigh,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.stroke),
                            ),
                            child: Text(_fmtTime(_mealTimes[i]),
                                style: AppText.body.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13)),
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmtTime(int mins) {
    final h = mins ~/ 60;
    final m = mins % 60;
    final period = h >= 12 ? 'PM' : 'AM';
    final h12 = h == 0
        ? 12
        : h > 12
            ? h - 12
            : h;
    return '$h12:${m.toString().padLeft(2, '0')} $period';
  }
}

class _PillButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _PillButton({
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
        height: 42,
        decoration: BoxDecoration(
          color: selected ? AppColors.accent : AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(12),
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
            fontSize: 13,
            letterSpacing: -0.1,
          ),
        ),
      ),
    );
  }
}
