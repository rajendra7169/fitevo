import 'package:isar/isar.dart';

import '../db.dart';
import '../models/exercise.dart';
import '../seed/exercise_seed.dart';

class ExerciseRepo {
  ExerciseRepo(this._db);
  final Db _db;

  Isar get _isar => _db.isar;

  /// Seed the bundled exercise library on first run.
  /// Idempotent — only inserts if the collection is empty.
  Future<void> seedIfEmpty() async {
    final count = await _isar.exercises.count();
    if (count > 0) return;
    final seed = buildSeedExercises();
    await _isar.writeTxn(() async {
      await _isar.exercises.putAll(seed);
    });
  }

  Future<List<Exercise>> all() async {
    return _isar.exercises.where().sortByName().findAll();
  }

  Stream<List<Exercise>> watchAll() {
    return _isar.exercises
        .where()
        .sortByName()
        .watch(fireImmediately: true);
  }

  Future<Exercise?> get(int id) => _isar.exercises.get(id);

  Future<List<Exercise>> findByNames(Iterable<String> names) async {
    final lower = names.map((n) => n.toLowerCase().trim()).toSet();
    final all = await this.all();
    return all
        .where((e) => lower.contains(e.name.toLowerCase().trim()))
        .toList();
  }

  Future<Exercise> save(Exercise e) async {
    await _isar.writeTxn(() async {
      await _isar.exercises.put(e);
    });
    return e;
  }

  Future<int> upsertByName(String name, {Exercise Function()? newExercise}) async {
    final existing = await _isar.exercises
        .filter()
        .nameEqualToInsensitive(name)
        .findFirst();
    if (existing != null) return existing.id;
    final e = newExercise?.call() ?? (Exercise()..name = name)
      ..isSeeded = false;
    return await _isar.writeTxn(() async => _isar.exercises.put(e));
  }
}

extension on QueryBuilder<Exercise, Exercise, QFilterCondition> {
  QueryBuilder<Exercise, Exercise, QAfterFilterCondition>
      nameEqualToInsensitive(String value) {
    return nameEqualTo(value, caseSensitive: false);
  }
}
