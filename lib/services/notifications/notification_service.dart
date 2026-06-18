import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../data/models/enums.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const _waterChannelId = 'water_reminders';
  static const _mealChannelId = 'meal_reminders';

  static const _waterIdStart = 1000;
  static const _mealIdStart = 2000;
  static const _weighInIdStart = 3000;

  Future<void> init() async {
    if (_initialized) return;
    // On web there are no local notifications — degrade to a silent no-op
    // so the rest of the app continues to work without platform errors.
    if (kIsWeb) {
      _initialized = true;
      return;
    }
    tz.initializeTimeZones();
    const androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _plugin.initialize(initSettings);

    final android =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      await android.requestNotificationsPermission();
      await android.createNotificationChannel(const AndroidNotificationChannel(
        _waterChannelId,
        'Water reminders',
        description: 'Gentle nudges to drink water.',
        importance: Importance.defaultImportance,
      ));
      await android.createNotificationChannel(const AndroidNotificationChannel(
        _mealChannelId,
        'Meal reminders',
        description: 'Reminders to log your meals.',
        importance: Importance.defaultImportance,
      ));
    }
    _initialized = true;
  }

  AndroidNotificationDetails _waterDetails() =>
      const AndroidNotificationDetails(
        _waterChannelId,
        'Water reminders',
        channelDescription: 'Gentle nudges to drink water.',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      );

  AndroidNotificationDetails _mealDetails() =>
      const AndroidNotificationDetails(
        _mealChannelId,
        'Meal reminders',
        channelDescription: 'Reminders to log your meals.',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      );

  /// Schedules water reminders every [intervalHours] between [startHour] and
  /// [endHour], for the next 7 days.
  Future<void> scheduleWaterReminders({
    required int intervalHours,
    int startHour = 8,
    int endHour = 21,
  }) async {
    await init();
    if (kIsWeb) return;
    await cancelWaterReminders();
    if (intervalHours <= 0) return;
    final now = tz.TZDateTime.now(tz.local);
    var id = _waterIdStart;
    for (var day = 0; day < 7; day++) {
      final base = now.add(Duration(days: day));
      for (var h = startHour; h <= endHour; h += intervalHours) {
        var fire =
            tz.TZDateTime(tz.local, base.year, base.month, base.day, h);
        if (fire.isBefore(now)) continue;
        await _plugin.zonedSchedule(
          id++,
          'Time for water',
          'A small sip keeps you on track.',
          fire,
          NotificationDetails(android: _waterDetails()),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: 'water',
        );
      }
    }
  }

  /// Schedules meal reminders at [times] (minutes-of-day, 0..1439) for the
  /// next 7 days.
  Future<void> scheduleMealReminders(List<int> times) async {
    await init();
    if (kIsWeb) return;
    await cancelMealReminders();
    if (times.isEmpty) return;
    final now = tz.TZDateTime.now(tz.local);
    var id = _mealIdStart;
    for (var day = 0; day < 7; day++) {
      final base = now.add(Duration(days: day));
      for (final t in times) {
        final h = t ~/ 60;
        final m = t % 60;
        final fire =
            tz.TZDateTime(tz.local, base.year, base.month, base.day, h, m);
        if (fire.isBefore(now)) continue;
        await _plugin.zonedSchedule(
          id++,
          'Don\'t forget to log',
          'Quick — what did you eat?',
          fire,
          NotificationDetails(android: _mealDetails()),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: 'meal',
        );
      }
    }
  }

  Future<void> cancelWaterReminders() async {
    final pending = await _plugin.pendingNotificationRequests();
    for (final p in pending) {
      if (p.id >= _waterIdStart && p.id < _mealIdStart) {
        await _plugin.cancel(p.id);
      }
    }
  }

  Future<void> cancelMealReminders() async {
    final pending = await _plugin.pendingNotificationRequests();
    for (final p in pending) {
      if (p.id >= _mealIdStart && p.id < _weighInIdStart) {
        await _plugin.cancel(p.id);
      }
    }
  }

  Future<void> cancelWeighInReminders() async {
    final pending = await _plugin.pendingNotificationRequests();
    for (final p in pending) {
      if (p.id >= _weighInIdStart) {
        await _plugin.cancel(p.id);
      }
    }
  }

  /// Schedules weigh-in reminders for the next 4 weeks based on the
  /// user's cadence + preferred weekday.
  Future<void> scheduleWeighInReminders({
    required WeighInCadence cadence,
    int? preferredWeekday, // 1=Mon..7=Sun
    int hour = 7,
    int minute = 30,
  }) async {
    await init();
    if (kIsWeb) return;
    await cancelWeighInReminders();

    int stepDays;
    switch (cadence) {
      case WeighInCadence.daily:
        stepDays = 1;
        break;
      case WeighInCadence.everyOtherDay:
        stepDays = 2;
        break;
      case WeighInCadence.twiceAWeek:
        stepDays = 3;
        break;
      case WeighInCadence.weekly:
        stepDays = 7;
        break;
    }

    final now = tz.TZDateTime.now(tz.local);
    // Find first fire date: if a preferred weekday is set and cadence is
    // weekly/twice/every-other, jump to that day. Otherwise start tomorrow.
    var start = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (start.isBefore(now)) start = start.add(const Duration(days: 1));
    if (preferredWeekday != null && cadence == WeighInCadence.weekly) {
      while (start.weekday != preferredWeekday) {
        start = start.add(const Duration(days: 1));
      }
    }

    var id = _weighInIdStart;
    final horizonDays = 28;
    for (var d = 0; d < horizonDays; d += stepDays) {
      final fire = start.add(Duration(days: d));
      await _plugin.zonedSchedule(
        id++,
        'Quick weigh-in',
        'Hop on the scale — your adaptive target depends on it.',
        fire,
        NotificationDetails(android: _mealDetails()),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'weighin',
      );
    }
  }

  Future<void> cancelAll() => _plugin.cancelAll();

  /// One-off snooze: re-fires the given notification in [snoozeMinutes].
  Future<void> snoozeWater(int snoozeMinutes) async {
    await init();
    final fire =
        tz.TZDateTime.now(tz.local).add(Duration(minutes: snoozeMinutes));
    await _plugin.zonedSchedule(
      _waterIdStart - 1,
      'Time for water',
      'A small sip keeps you on track.',
      fire,
      NotificationDetails(android: _waterDetails()),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: 'water_snoozed',
    );
  }
}
