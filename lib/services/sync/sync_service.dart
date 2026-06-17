import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:isar/isar.dart';

import '../../data/db.dart';
import '../../data/models/custom_food.dart';
import '../../data/models/daily_log.dart';
import '../../data/models/enums.dart';
import '../../data/models/food_entry.dart';
import '../../data/models/profile.dart';

class SyncService {
  SyncService({
    required Db db,
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _db = db,
        _fs = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final Db _db;
  final FirebaseFirestore _fs;
  final FirebaseAuth _auth;

  Isar get _isar => _db.isar;

  String? get _uid => _auth.currentUser?.uid;

  DocumentReference<Map<String, dynamic>> _userDoc() {
    final uid = _uid;
    if (uid == null) throw StateError('Not signed in.');
    return _fs.collection('users').doc(uid);
  }

  CollectionReference<Map<String, dynamic>> _foodEntries() =>
      _userDoc().collection('foodEntries');
  CollectionReference<Map<String, dynamic>> _dailyLogs() =>
      _userDoc().collection('dailyLogs');
  CollectionReference<Map<String, dynamic>> _customFoods() =>
      _userDoc().collection('customFoods');
  DocumentReference<Map<String, dynamic>> _profileDoc() =>
      _userDoc().collection('profile').doc('main');

  // Detect whether the user has any cloud data — used to decide push vs pull
  // on first sign-in.
  Future<bool> cloudHasData() async {
    final p = await _profileDoc().get();
    if (p.exists) return true;
    final f = await _foodEntries().limit(1).get();
    return f.docs.isNotEmpty;
  }

  Future<bool> localHasData() async {
    final p = await _isar.profiles.count();
    if (p > 0) return true;
    final f = await _isar.foodEntrys.count();
    return f > 0;
  }

  /// Push everything in Isar up to Firestore. Last-write-wins.
  Future<void> pushAll() async {
    final batch = _fs.batch();

    final profile = await _isar.profiles.where().findFirst();
    if (profile != null) {
      batch.set(_profileDoc(), _profileToMap(profile));
    }

    final entries = await _isar.foodEntrys.where().findAll();
    for (final e in entries) {
      batch.set(_foodEntries().doc(e.id.toString()), _foodEntryToMap(e));
    }

    final logs = await _isar.dailyLogs.where().findAll();
    for (final l in logs) {
      batch.set(_dailyLogs().doc(l.dateKey), _dailyLogToMap(l));
    }

    final foods = await _isar.customFoods.where().findAll();
    for (final c in foods) {
      batch.set(_customFoods().doc(c.id.toString()), _customFoodToMap(c));
    }

    await batch.commit();
    await _userDoc().set({'lastBackupAt': FieldValue.serverTimestamp()},
        SetOptions(merge: true));
  }

  /// Pull everything from Firestore into local Isar. Overwrites local rows
  /// with the same identity. Privacy guardrail: this only restores the
  /// collections the sync service knows about — body measurements / photos
  /// are intentionally NOT in the schema map.
  Future<void> pullAll() async {
    final pf = await _profileDoc().get();
    final entries = await _foodEntries().get();
    final logs = await _dailyLogs().get();
    final foods = await _customFoods().get();

    await _isar.writeTxn(() async {
      if (pf.exists) {
        final p = _profileFromMap(pf.data()!);
        await _isar.profiles.put(p);
      }
      for (final d in entries.docs) {
        final e = _foodEntryFromMap(d.data());
        await _isar.foodEntrys.put(e);
      }
      for (final d in logs.docs) {
        final l = _dailyLogFromMap(d.data());
        await _isar.dailyLogs.put(l);
      }
      for (final d in foods.docs) {
        final c = _customFoodFromMap(d.data());
        await _isar.customFoods.put(c);
      }
    });
  }

  Future<DateTime?> lastBackupAt() async {
    try {
      final snap = await _userDoc().get();
      final ts = snap.data()?['lastBackupAt'];
      if (ts is Timestamp) return ts.toDate();
    } catch (_) {}
    return null;
  }

  // --- mappers ----------------------------------------------------------

  Map<String, dynamic> _profileToMap(Profile p) => {
        'displayName': p.displayName,
        'age': p.age,
        'gender': p.gender.name,
        'heightCm': p.heightCm,
        'weightKg': p.weightKg,
        'activityLevel': p.activityLevel.name,
        'goal': p.goal.name,
        'trainingDaysPerWeek': p.trainingDaysPerWeek,
        'bmr': p.bmr,
        'tdee': p.tdee,
        'calorieTarget': p.calorieTarget,
        'proteinTargetG': p.proteinTargetG,
        'carbTargetG': p.carbTargetG,
        'fatTargetG': p.fatTargetG,
        'fiberTargetG': p.fiberTargetG,
        'waterTargetMl': p.waterTargetMl,
        'bmi': p.bmi,
        'calorieOverride': p.calorieOverride,
        'proteinOverride': p.proteinOverride,
        'carbOverride': p.carbOverride,
        'fatOverride': p.fatOverride,
        'fiberOverride': p.fiberOverride,
        'waterOverride': p.waterOverride,
        'createdAt': p.createdAt.toIso8601String(),
        'updatedAt': p.updatedAt.toIso8601String(),
      };

  Profile _profileFromMap(Map<String, dynamic> m) {
    return Profile()
      ..id = 0
      ..displayName = (m['displayName'] as String?) ?? ''
      ..age = (m['age'] as num?)?.toInt() ?? 22
      ..gender = _enumFromName(Gender.values, m['gender'] as String?) ?? Gender.male
      ..heightCm = (m['heightCm'] as num?)?.toDouble() ?? 170
      ..weightKg = (m['weightKg'] as num?)?.toDouble() ?? 70
      ..activityLevel = _enumFromName(ActivityLevel.values, m['activityLevel'] as String?) ??
          ActivityLevel.moderate
      ..goal = _enumFromName(FitnessGoal.values, m['goal'] as String?) ??
          FitnessGoal.generalFitness
      ..trainingDaysPerWeek = (m['trainingDaysPerWeek'] as num?)?.toInt() ?? 3
      ..bmr = (m['bmr'] as num?)?.toDouble() ?? 0
      ..tdee = (m['tdee'] as num?)?.toDouble() ?? 0
      ..calorieTarget = (m['calorieTarget'] as num?)?.toInt() ?? 2000
      ..proteinTargetG = (m['proteinTargetG'] as num?)?.toInt() ?? 120
      ..carbTargetG = (m['carbTargetG'] as num?)?.toInt() ?? 230
      ..fatTargetG = (m['fatTargetG'] as num?)?.toInt() ?? 65
      ..fiberTargetG = (m['fiberTargetG'] as num?)?.toInt() ?? 28
      ..waterTargetMl = (m['waterTargetMl'] as num?)?.toInt() ?? 2500
      ..bmi = (m['bmi'] as num?)?.toDouble() ?? 22
      ..calorieOverride = (m['calorieOverride'] as num?)?.toInt()
      ..proteinOverride = (m['proteinOverride'] as num?)?.toInt()
      ..carbOverride = (m['carbOverride'] as num?)?.toInt()
      ..fatOverride = (m['fatOverride'] as num?)?.toInt()
      ..fiberOverride = (m['fiberOverride'] as num?)?.toInt()
      ..waterOverride = (m['waterOverride'] as num?)?.toInt()
      ..createdAt = DateTime.tryParse(m['createdAt'] as String? ?? '') ??
          DateTime.now()
      ..updatedAt = DateTime.tryParse(m['updatedAt'] as String? ?? '') ??
          DateTime.now();
  }

  Map<String, dynamic> _foodEntryToMap(FoodEntry e) => {
        'id': e.id,
        'timestamp': e.timestamp.toIso8601String(),
        'dateKey': e.dateKey,
        'rawInput': e.rawInput,
        'description': e.description,
        'quantity': e.quantity,
        'unit': e.unit,
        'calories': e.calories,
        'proteinG': e.proteinG,
        'carbsG': e.carbsG,
        'fatG': e.fatG,
        'fiberG': e.fiberG,
        'sodiumMg': e.sodiumMg,
        'source': e.source.name,
        'confidence': e.confidence.name,
        'caloriesLow': e.caloriesLow,
        'caloriesHigh': e.caloriesHigh,
        'isFavorite': e.isFavorite,
      };

  FoodEntry _foodEntryFromMap(Map<String, dynamic> m) {
    return FoodEntry()
      ..id = (m['id'] as num?)?.toInt() ?? Isar.autoIncrement
      ..timestamp = DateTime.tryParse(m['timestamp'] as String? ?? '') ??
          DateTime.now()
      ..dateKey = (m['dateKey'] as String?) ?? ''
      ..rawInput = (m['rawInput'] as String?) ?? ''
      ..description = (m['description'] as String?) ?? ''
      ..quantity = (m['quantity'] as String?) ?? ''
      ..unit = (m['unit'] as String?) ?? ''
      ..calories = (m['calories'] as num?)?.toInt() ?? 0
      ..proteinG = (m['proteinG'] as num?)?.toInt() ?? 0
      ..carbsG = (m['carbsG'] as num?)?.toInt() ?? 0
      ..fatG = (m['fatG'] as num?)?.toInt() ?? 0
      ..fiberG = (m['fiberG'] as num?)?.toInt() ?? 0
      ..sodiumMg = (m['sodiumMg'] as num?)?.toInt() ?? 0
      ..source = _enumFromName(FoodSource.values, m['source'] as String?) ??
          FoodSource.aiText
      ..confidence =
          _enumFromName(EstimateConfidence.values, m['confidence'] as String?) ??
              EstimateConfidence.medium
      ..caloriesLow = (m['caloriesLow'] as num?)?.toInt()
      ..caloriesHigh = (m['caloriesHigh'] as num?)?.toInt()
      ..isFavorite = (m['isFavorite'] as bool?) ?? false;
  }

  Map<String, dynamic> _dailyLogToMap(DailyLog l) => {
        'dateKey': l.dateKey,
        'waterMl': l.waterMl,
        'steps': l.steps,
        'heartRateAvg': l.heartRateAvg,
        'sleepMinutes': l.sleepMinutes,
        'updatedAt': l.updatedAt.toIso8601String(),
      };

  DailyLog _dailyLogFromMap(Map<String, dynamic> m) {
    return DailyLog()
      ..dateKey = (m['dateKey'] as String?) ?? ''
      ..waterMl = (m['waterMl'] as num?)?.toInt() ?? 0
      ..steps = (m['steps'] as num?)?.toInt()
      ..heartRateAvg = (m['heartRateAvg'] as num?)?.toInt()
      ..sleepMinutes = (m['sleepMinutes'] as num?)?.toInt()
      ..updatedAt = DateTime.tryParse(m['updatedAt'] as String? ?? '') ??
          DateTime.now();
  }

  Map<String, dynamic> _customFoodToMap(CustomFood c) => {
        'id': c.id,
        'name': c.name,
        'servingSizeG': c.servingSizeG,
        'servingDescription': c.servingDescription,
        'caloriesPerServing': c.caloriesPerServing,
        'proteinGPerServing': c.proteinGPerServing,
        'carbsGPerServing': c.carbsGPerServing,
        'fatGPerServing': c.fatGPerServing,
        'fiberGPerServing': c.fiberGPerServing,
        'sodiumMgPerServing': c.sodiumMgPerServing,
        'ingredients': c.ingredients,
        'createdAt': c.createdAt.toIso8601String(),
      };

  CustomFood _customFoodFromMap(Map<String, dynamic> m) {
    return CustomFood()
      ..id = (m['id'] as num?)?.toInt() ?? Isar.autoIncrement
      ..name = (m['name'] as String?) ?? ''
      ..servingSizeG = (m['servingSizeG'] as num?)?.toDouble() ?? 100
      ..servingDescription =
          (m['servingDescription'] as String?) ?? '1 serving'
      ..caloriesPerServing = (m['caloriesPerServing'] as num?)?.toInt() ?? 0
      ..proteinGPerServing = (m['proteinGPerServing'] as num?)?.toInt() ?? 0
      ..carbsGPerServing = (m['carbsGPerServing'] as num?)?.toInt() ?? 0
      ..fatGPerServing = (m['fatGPerServing'] as num?)?.toInt() ?? 0
      ..fiberGPerServing = (m['fiberGPerServing'] as num?)?.toInt() ?? 0
      ..sodiumMgPerServing = (m['sodiumMgPerServing'] as num?)?.toInt() ?? 0
      ..ingredients = m['ingredients'] as String?
      ..createdAt = DateTime.tryParse(m['createdAt'] as String? ?? '') ??
          DateTime.now();
  }

  T? _enumFromName<T extends Enum>(List<T> values, String? name) {
    if (name == null) return null;
    for (final v in values) {
      if (v.name == name) return v;
    }
    return null;
  }
}
