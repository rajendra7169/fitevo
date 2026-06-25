import 'package:isar/isar.dart';

import '../db.dart';
import '../models/custom_food.dart';
import '../models/daily_log.dart';
import '../models/enums.dart';
import '../models/food_entry.dart';

class DailyTotals {
  final int calories;
  final int proteinG;
  final int carbsG;
  final int fatG;
  final int fiberG;
  final int sodiumMg;
  final int waterMl;
  final int entryCount;

  const DailyTotals({
    this.calories = 0,
    this.proteinG = 0,
    this.carbsG = 0,
    this.fatG = 0,
    this.fiberG = 0,
    this.sodiumMg = 0,
    this.waterMl = 0,
    this.entryCount = 0,
  });
}

class NutritionRepo {
  NutritionRepo(this._db);
  final Db _db;

  Isar get _isar => _db.isar;

  Future<List<FoodEntry>> entriesForDate(DateTime date) async {
    final key = DailyLog.keyFor(date);
    return _isar.foodEntrys
        .filter()
        .dateKeyEqualTo(key)
        .sortByTimestampDesc()
        .findAll();
  }

  Future<List<FoodEntry>> getAllEntries() async {
    return _isar.foodEntrys.where().sortByTimestampDesc().findAll();
  }

  Stream<List<FoodEntry>> watchAllEntries() {
    return _isar.foodEntrys
        .where()
        .sortByTimestampDesc()
        .watch(fireImmediately: true);
  }

  Stream<List<FoodEntry>> watchEntriesForDate(DateTime date) {
    final key = DailyLog.keyFor(date);
    return _isar.foodEntrys
        .filter()
        .dateKeyEqualTo(key)
        .sortByTimestampDesc()
        .watch(fireImmediately: true);
  }

  Future<DailyLog?> dailyLogFor(DateTime date) async {
    final key = DailyLog.keyFor(date);
    return _isar.dailyLogs.filter().dateKeyEqualTo(key).findFirst();
  }

  Stream<DailyLog?> watchDailyLog(DateTime date) {
    final key = DailyLog.keyFor(date);
    return _isar.dailyLogs
        .filter()
        .dateKeyEqualTo(key)
        .watch(fireImmediately: true)
        .map((all) => all.isEmpty ? null : all.first);
  }

  Future<DailyLog> getOrCreateLog(DateTime date) async {
    final key = DailyLog.keyFor(date);
    final existing =
        await _isar.dailyLogs.filter().dateKeyEqualTo(key).findFirst();
    if (existing != null) return existing;
    final log = DailyLog()..dateKey = key;
    await _isar.writeTxn(() async {
      await _isar.dailyLogs.put(log);
    });
    return log;
  }

  Future<void> addFoodEntry(FoodEntry entry) async {
    await _isar.writeTxn(() async {
      await _isar.foodEntrys.put(entry);
    });
  }

  Future<DailyLog> upsertDailyLog(DateTime date, {
    int? steps,
    int? heartRateAvg,
    int? sleepMinutes,
    double? walkingKmToday,
    double? runningKmToday,
    int? otherCardioMinutes,
    String? activityNote,
  }) async {
    final key = DailyLog.keyFor(date);
    return await _isar.writeTxn(() async {
      final existing = await _isar.dailyLogs
          .filter()
          .dateKeyEqualTo(key)
          .findFirst();
      final log = existing ?? (DailyLog()..dateKey = key);
      if (steps != null) log.steps = steps;
      if (heartRateAvg != null) log.heartRateAvg = heartRateAvg;
      if (sleepMinutes != null) log.sleepMinutes = sleepMinutes;
      if (walkingKmToday != null) log.walkingKmToday = walkingKmToday;
      if (runningKmToday != null) log.runningKmToday = runningKmToday;
      if (otherCardioMinutes != null) {
        log.otherCardioMinutes = otherCardioMinutes;
      }
      if (activityNote != null) log.activityNote = activityNote;
      log.updatedAt = DateTime.now();
      await _isar.dailyLogs.put(log);
      return log;
    });
  }

  Future<void> deleteFoodEntry(int id) async {
    await _isar.writeTxn(() async {
      await _isar.foodEntrys.delete(id);
    });
  }

  /// Move an existing food entry to a new timestamp. Used when the user
  /// logged something but forgot to set the actual eating time. We also
  /// update [dateKey] so today's-totals queries pick it up under the
  /// correct day if the entry crosses midnight.
  Future<void> updateFoodEntryTimestamp(int id, DateTime newTimestamp) async {
    await _isar.writeTxn(() async {
      final e = await _isar.foodEntrys.get(id);
      if (e == null) return;
      e.timestamp = newTimestamp;
      e.dateKey = DailyLog.keyFor(newTimestamp);
      await _isar.foodEntrys.put(e);
    });
  }

  /// Batch-update timestamps for a group of entries that were logged as
  /// one meal. The AI splits multi-item prompts into several FoodEntry
  /// rows (e.g. "creatine + protein shake" → 2 entries), but the user
  /// ate them at the same moment — editing one shouldn't desync them.
  Future<void> updateFoodEntriesTimestamp(
      List<int> ids, DateTime newTimestamp) async {
    if (ids.isEmpty) return;
    await _isar.writeTxn(() async {
      final newDateKey = DailyLog.keyFor(newTimestamp);
      for (final id in ids) {
        final e = await _isar.foodEntrys.get(id);
        if (e == null) continue;
        e.timestamp = newTimestamp;
        e.dateKey = newDateKey;
        await _isar.foodEntrys.put(e);
      }
    });
  }

  Future<void> toggleFavorite(int id) async {
    await _isar.writeTxn(() async {
      final e = await _isar.foodEntrys.get(id);
      if (e == null) return;
      e.isFavorite = !e.isFavorite;
      await _isar.foodEntrys.put(e);
    });
  }

  /// Overwrite an entry's nutrition fields (used by Refine after the
  /// AI re-analyses with extra detail). Keeps timestamp, dateKey,
  /// source, photoPath, isFavorite, and rawInput unchanged — only the
  /// description, quantity, and the macros move.
  Future<void> updateFoodEntryNutrition(int id, FoodEntry updated) async {
    await _isar.writeTxn(() async {
      final e = await _isar.foodEntrys.get(id);
      if (e == null) return;
      e.description = updated.description;
      e.quantity = updated.quantity;
      e.calories = updated.calories;
      e.proteinG = updated.proteinG;
      e.carbsG = updated.carbsG;
      e.fatG = updated.fatG;
      e.fiberG = updated.fiberG;
      e.sodiumMg = updated.sodiumMg;
      e.confidence = updated.confidence;
      e.caloriesLow = updated.caloriesLow;
      e.caloriesHigh = updated.caloriesHigh;
      await _isar.foodEntrys.put(e);
    });
  }

  Future<FoodEntry> relogScaled(FoodEntry source, double scale) async {
    final now = DateTime.now();
    final copy = FoodEntry()
      ..timestamp = now
      ..dateKey = DailyLog.keyFor(now)
      ..rawInput = source.rawInput
      ..description = source.description
      ..quantity = scale == 1.0
          ? source.quantity
          : '${_fmtScale(scale)} of ${source.quantity}'.trim()
      ..unit = source.unit
      ..calories = (source.calories * scale).round()
      ..proteinG = (source.proteinG * scale).round()
      ..carbsG = (source.carbsG * scale).round()
      ..fatG = (source.fatG * scale).round()
      ..fiberG = (source.fiberG * scale).round()
      ..sodiumMg = (source.sodiumMg * scale).round()
      ..source = source.source
      ..confidence = source.confidence
      ..caloriesLow = source.caloriesLow == null
          ? null
          : (source.caloriesLow! * scale).round()
      ..caloriesHigh = source.caloriesHigh == null
          ? null
          : (source.caloriesHigh! * scale).round()
      ..isFavorite = false
      ..photoPath = source.photoPath;
    await addFoodEntry(copy);
    return copy;
  }

  Stream<List<CustomFood>> watchCustomFoods() {
    return _isar.customFoods
        .where()
        .sortByName()
        .watch(fireImmediately: true);
  }

  Future<List<CustomFood>> getCustomFoods() async {
    return _isar.customFoods.where().sortByName().findAll();
  }

  Future<void> saveCustomFood(CustomFood food) async {
    await _isar.writeTxn(() async {
      await _isar.customFoods.put(food);
    });
  }

  Future<void> deleteCustomFood(int id) async {
    await _isar.writeTxn(() async {
      await _isar.customFoods.delete(id);
    });
  }

  Future<FoodEntry> logCustomFood(CustomFood food, double servings) async {
    final now = DateTime.now();
    final entry = FoodEntry()
      ..timestamp = now
      ..dateKey = DailyLog.keyFor(now)
      ..rawInput = food.name
      ..description = food.name
      ..quantity = servings == 1.0
          ? food.servingDescription
          : '${_fmtScale(servings)} ${food.servingDescription}'
      ..calories = (food.caloriesPerServing * servings).round()
      ..proteinG = (food.proteinGPerServing * servings).round()
      ..carbsG = (food.carbsGPerServing * servings).round()
      ..fatG = (food.fatGPerServing * servings).round()
      ..fiberG = (food.fiberGPerServing * servings).round()
      ..sodiumMg = (food.sodiumMgPerServing * servings).round()
      ..source = FoodSource.custom
      ..confidence = EstimateConfidence.high;
    await addFoodEntry(entry);
    return entry;
  }

  Stream<List<FoodEntry>> watchFavorites({int limit = 12}) {
    return _isar.foodEntrys
        .filter()
        .isFavoriteEqualTo(true)
        .sortByTimestampDesc()
        .limit(limit)
        .watch(fireImmediately: true);
  }

  String _fmtScale(double s) {
    if (s == s.roundToDouble()) return '${s.toInt()}×';
    return '${s.toStringAsFixed(1)}×';
  }

  /// Add water with a timestamp. Records a WaterEntry AND increments the
  /// aggregate waterMl so existing dashboard queries keep working.
  /// The timestamp defaults to the current minute-of-day.
  Future<void> addWater(DateTime date, int ml, {int? minutesOfDay}) async {
    final log = await getOrCreateLog(date);
    final now = DateTime.now();
    final mod = minutesOfDay ?? (now.hour * 60 + now.minute);
    log.waterMl = log.waterMl + ml;
    log.waterEntries = List.of(log.waterEntries)
      ..add(WaterEntry()
        ..minutesOfDay = mod
        ..ml = ml);
    log.updatedAt = now;
    await _isar.writeTxn(() async {
      await _isar.dailyLogs.put(log);
    });
  }

  /// Remove a specific water entry by index (timeline order) and
  /// re-derive the total. Used by the detail page's swipe-to-delete.
  Future<void> removeWaterEntryAt(DateTime date, int index) async {
    final log = await getOrCreateLog(date);
    if (index < 0 || index >= log.waterEntries.length) return;
    final updated = List.of(log.waterEntries)..removeAt(index);
    log.waterEntries = updated;
    log.waterMl = updated.fold<int>(0, (s, e) => s + e.ml);
    log.updatedAt = DateTime.now();
    await _isar.writeTxn(() async {
      await _isar.dailyLogs.put(log);
    });
  }

  Future<void> setWater(DateTime date, int ml) async {
    final log = await getOrCreateLog(date);
    log.waterMl = ml < 0 ? 0 : ml;
    log.updatedAt = DateTime.now();
    await _isar.writeTxn(() async {
      await _isar.dailyLogs.put(log);
    });
  }

  static DailyTotals sumEntries(List<FoodEntry> entries, {int waterMl = 0}) {
    int c = 0, p = 0, cb = 0, f = 0, fb = 0, s = 0;
    for (final e in entries) {
      c += e.calories;
      p += e.proteinG;
      cb += e.carbsG;
      f += e.fatG;
      fb += e.fiberG;
      s += e.sodiumMg;
    }
    return DailyTotals(
      calories: c,
      proteinG: p,
      carbsG: cb,
      fatG: f,
      fiberG: fb,
      sodiumMg: s,
      waterMl: waterMl,
      entryCount: entries.length,
    );
  }
}
