import 'dart:convert';
import 'dart:io';

import 'package:intl/intl.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../../data/db.dart';
import '../../data/models/body_measurement.dart';
import '../../data/models/custom_food.dart';
import '../../data/models/daily_log.dart';
import '../../data/models/exercise.dart';
import '../../data/models/food_entry.dart';
import '../../data/models/profile.dart';
import '../../data/models/routine.dart';
import '../../data/models/workout_session.dart';

class DataExportService {
  DataExportService(this._db);
  final Db _db;

  /// Writes a JSON dump of all on-device data (food, workouts, measurements,
  /// custom foods, profile, routines, exercises) to the app documents dir
  /// and returns the file path.
  /// Photo bytes are NOT included; only the on-device path is referenced.
  Future<String> exportToFile() async {
    final isar = _db.isar;

    final profiles = await isar.profiles.where().sortByCreatedAt().findAll();
    final foods = await isar.foodEntrys.where().sortByTimestampDesc().findAll();
    final logs = await isar.dailyLogs.where().sortByDateKey().findAll();
    final customs = await isar.customFoods.where().sortByName().findAll();
    final sessions =
        await isar.workoutSessions.where().sortByStartedAtDesc().findAll();
    final routines = await isar.routines.where().sortByName().findAll();
    final measurements =
        await isar.bodyMeasurements.where().sortByDateDesc().findAll();

    final data = <String, dynamic>{
      'app': 'fitevo',
      'exportedAt': DateTime.now().toIso8601String(),
      'profile': profiles
          .map((p) => {
                'displayName': p.displayName,
                'age': p.age,
                'gender': p.gender.name,
                'heightCm': p.heightCm,
                'weightKg': p.weightKg,
                'activityLevel': p.activityLevel.name,
                'goal': p.goal.name,
                'trainingDaysPerWeek': p.trainingDaysPerWeek,
                'calorieTarget': p.effectiveCalorieTarget,
                'proteinTargetG': p.effectiveProteinTarget,
                'carbTargetG': p.effectiveCarbTarget,
                'fatTargetG': p.effectiveFatTarget,
                'fiberTargetG': p.effectiveFiberTarget,
                'waterTargetMl': p.effectiveWaterTarget,
                'bmi': p.bmi,
                'updatedAt': p.updatedAt.toIso8601String(),
              })
          .toList(),
      'foodEntries': foods
          .map((e) => {
                'timestamp': e.timestamp.toIso8601String(),
                'dateKey': e.dateKey,
                'description': e.description,
                'rawInput': e.rawInput,
                'quantity': e.quantity,
                'calories': e.calories,
                'proteinG': e.proteinG,
                'carbsG': e.carbsG,
                'fatG': e.fatG,
                'fiberG': e.fiberG,
                'sodiumMg': e.sodiumMg,
                'source': e.source.name,
                'confidence': e.confidence.name,
                'isFavorite': e.isFavorite,
              })
          .toList(),
      'dailyLogs': logs
          .map((l) => {
                'dateKey': l.dateKey,
                'waterMl': l.waterMl,
                'steps': l.steps,
                'heartRateAvg': l.heartRateAvg,
                'sleepMinutes': l.sleepMinutes,
              })
          .toList(),
      'customFoods': customs
          .map((c) => {
                'name': c.name,
                'servingDescription': c.servingDescription,
                'servingSizeG': c.servingSizeG,
                'caloriesPerServing': c.caloriesPerServing,
                'proteinGPerServing': c.proteinGPerServing,
                'carbsGPerServing': c.carbsGPerServing,
                'fatGPerServing': c.fatGPerServing,
                'fiberGPerServing': c.fiberGPerServing,
                'sodiumMgPerServing': c.sodiumMgPerServing,
                'ingredients': c.ingredients,
              })
          .toList(),
      'workoutSessions': sessions
          .map((s) => {
                'dateKey': s.dateKey,
                'startedAt': s.startedAt.toIso8601String(),
                'completedAt': s.completedAt?.toIso8601String(),
                'routineName': s.routineName,
                'routineDayName': s.routineDayName,
                'sets': s.sets
                    .map((e) => {
                          'exerciseId': e.exerciseId,
                          'exerciseName': e.exerciseName,
                          'setNumber': e.setNumber,
                          'weightKg': e.weightKg,
                          'reps': e.reps,
                          'rpe': e.rpe,
                          'isWarmup': e.isWarmup,
                          'completedAt': e.completedAt.toIso8601String(),
                        })
                    .toList(),
              })
          .toList(),
      'routines': routines
          .map((r) => {
                'name': r.name,
                'description': r.description,
                'isActive': r.isActive,
                'days': r.days
                    .map((d) => {
                          'name': d.name,
                          'weekday': d.weekday,
                          'isRest': d.isRest,
                          'items': d.items
                              .map((i) => {
                                    'exerciseName': i.exerciseName,
                                    'targetSets': i.targetSets,
                                    'targetRepsLow': i.targetRepsLow,
                                    'targetRepsHigh': i.targetRepsHigh,
                                    'restSeconds': i.restSeconds,
                                  })
                              .toList(),
                        })
                    .toList(),
              })
          .toList(),
      'bodyMeasurements': measurements
          .map((m) => {
                'date': m.date.toIso8601String(),
                'weightKg': m.weightKg,
                'bodyFatPct': m.bodyFatPct,
                'waistCm': m.waistCm,
                'chestCm': m.chestCm,
                'hipsCm': m.hipsCm,
                'thighCm': m.thighCm,
                'armCm': m.armCm,
                'note': m.note,
                'hasPhoto': m.photoPath != null,
              })
          .toList(),
    };

    final encoded = const JsonEncoder.withIndent('  ').convert(data);
    final dir = await getApplicationDocumentsDirectory();
    final ts = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File('${dir.path}/fitevo_export_$ts.json');
    await file.writeAsString(encoded);
    return file.path;
  }

  /// Wipes all on-device collections. Does NOT sign the user out and does
  /// NOT delete cloud backup — call those separately if you want a full reset.
  Future<void> clearAll() async {
    final isar = _db.isar;
    await isar.writeTxn(() async {
      await isar.profiles.clear();
      await isar.foodEntrys.clear();
      await isar.dailyLogs.clear();
      await isar.customFoods.clear();
      await isar.workoutSessions.clear();
      await isar.routines.clear();
      await isar.exercises.clear();
      await isar.bodyMeasurements.clear();
    });
  }

  /// Wipes only the day-to-day tracking history: food entries, workout
  /// sessions, daily logs, body measurements. Keeps Profile (so targets
  /// + onboarding survive), custom foods, exercises, and routines (so
  /// the user doesn't have to rebuild their library).
  ///
  /// Useful for "start fresh on January 1" without losing the user's
  /// setup or food/workout templates.
  Future<void> clearTrainingData() async {
    final isar = _db.isar;
    await isar.writeTxn(() async {
      await isar.foodEntrys.clear();
      await isar.workoutSessions.clear();
      await isar.dailyLogs.clear();
      await isar.bodyMeasurements.clear();
    });
  }
}
