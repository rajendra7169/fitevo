import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import 'models/body_measurement.dart';
import 'models/custom_food.dart';
import 'models/daily_log.dart';
import 'models/exercise.dart';
import 'models/food_entry.dart';
import 'models/profile.dart';
import 'models/routine.dart';
import 'models/workout_session.dart';

class Db {
  Db._(this.isar);
  final Isar isar;

  static Db? _instance;
  static Db get instance {
    final db = _instance;
    if (db == null) {
      throw StateError('Db.init() must be called before accessing Db.instance');
    }
    return db;
  }

  /// Wipes every collection. Used by the account-deletion flow so a
  /// user who hits "Delete account" leaves no local trace behind.
  /// Does not close or reset the Isar instance — the app keeps running.
  Future<void> wipeAll() async {
    await isar.writeTxn(() async {
      await isar.profiles.clear();
      await isar.dailyLogs.clear();
      await isar.foodEntrys.clear();
      await isar.customFoods.clear();
      await isar.exercises.clear();
      await isar.routines.clear();
      await isar.workoutSessions.clear();
      await isar.bodyMeasurements.clear();
    });
  }

  static Future<Db> init() async {
    if (_instance != null) return _instance!;
    final dir = await getApplicationDocumentsDirectory();
    final isar = await Isar.open(
      [
        ProfileSchema,
        DailyLogSchema,
        FoodEntrySchema,
        CustomFoodSchema,
        ExerciseSchema,
        RoutineSchema,
        WorkoutSessionSchema,
        BodyMeasurementSchema,
      ],
      directory: dir.path,
      name: 'fitevo',
    );
    _instance = Db._(isar);
    return _instance!;
  }
}
