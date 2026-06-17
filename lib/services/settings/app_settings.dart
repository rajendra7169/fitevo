import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  AppSettings._(this._prefs);
  final SharedPreferences _prefs;

  static AppSettings? _instance;
  static AppSettings get instance {
    final s = _instance;
    if (s == null) {
      throw StateError('AppSettings.init() must be called first');
    }
    return s;
  }

  static Future<AppSettings> init() async {
    if (_instance != null) return _instance!;
    final prefs = await SharedPreferences.getInstance();
    _instance = AppSettings._(prefs);
    return _instance!;
  }

  static const _kSkippedAuth = 'auth.skipped';
  static const _kThemeMode = 'theme.mode'; // 'light' | 'dark'
  static const _kUnits = 'units'; // 'metric' | 'imperial'

  bool get skippedAuth => _prefs.getBool(_kSkippedAuth) ?? false;

  Future<void> setSkippedAuth(bool value) async {
    await _prefs.setBool(_kSkippedAuth, value);
  }

  ThemeMode get themeMode {
    final raw = _prefs.getString(_kThemeMode);
    if (raw == 'light') return ThemeMode.light;
    return ThemeMode.dark;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final raw = mode == ThemeMode.light ? 'light' : 'dark';
    await _prefs.setString(_kThemeMode, raw);
  }

  // ----------------- REMINDERS ---------------------------------------------

  static const _kWaterEnabled = 'reminders.water.enabled';
  static const _kWaterIntervalH = 'reminders.water.intervalHours';
  static const _kMealEnabled = 'reminders.meal.enabled';
  static const _kMealTimes = 'reminders.meal.timesMins'; // CSV of minutes-of-day

  bool get waterRemindersEnabled => _prefs.getBool(_kWaterEnabled) ?? false;
  Future<void> setWaterRemindersEnabled(bool v) async {
    await _prefs.setBool(_kWaterEnabled, v);
  }

  int get waterIntervalHours => _prefs.getInt(_kWaterIntervalH) ?? 2;
  Future<void> setWaterIntervalHours(int v) async {
    await _prefs.setInt(_kWaterIntervalH, v);
  }

  bool get mealRemindersEnabled => _prefs.getBool(_kMealEnabled) ?? false;
  Future<void> setMealRemindersEnabled(bool v) async {
    await _prefs.setBool(_kMealEnabled, v);
  }

  /// Meal reminder times as minutes-of-day (0..1439). Defaults to breakfast
  /// 8:00, lunch 13:00, dinner 19:00.
  List<int> get mealTimes {
    final raw = _prefs.getString(_kMealTimes);
    if (raw == null) return const [8 * 60, 13 * 60, 19 * 60];
    return raw
        .split(',')
        .where((s) => s.trim().isNotEmpty)
        .map((s) => int.tryParse(s.trim()) ?? 0)
        .toList();
  }

  Future<void> setMealTimes(List<int> times) async {
    await _prefs.setString(_kMealTimes, times.join(','));
  }

  // ----------------- UNITS -------------------------------------------------

  UnitSystem get units {
    final raw = _prefs.getString(_kUnits);
    if (raw == 'imperial') return UnitSystem.imperial;
    return UnitSystem.metric;
  }

  Future<void> setUnits(UnitSystem u) async {
    await _prefs.setString(
        _kUnits, u == UnitSystem.imperial ? 'imperial' : 'metric');
  }
}

enum UnitSystem { metric, imperial }

class UnitFormat {
  static String weight(double kg, UnitSystem u) {
    if (u == UnitSystem.imperial) {
      final lb = kg * 2.20462;
      return '${lb.toStringAsFixed(1)} lb';
    }
    return '${kg.toStringAsFixed(1)} kg';
  }

  static String height(double cm, UnitSystem u) {
    if (u == UnitSystem.imperial) {
      final inches = cm / 2.54;
      final ft = inches ~/ 12;
      final inRem = (inches - ft * 12).round();
      return "$ft' $inRem\"";
    }
    return '${cm.round()} cm';
  }

  static String volume(int ml, UnitSystem u) {
    if (u == UnitSystem.imperial) {
      final flOz = ml / 29.5735;
      return '${flOz.toStringAsFixed(0)} fl oz';
    }
    return '${(ml / 1000).toStringAsFixed(1)}L';
  }
}
