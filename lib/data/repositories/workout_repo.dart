import 'package:isar/isar.dart';

import '../db.dart';
import '../models/routine.dart';
import '../models/workout_session.dart';

class WorkoutRepo {
  WorkoutRepo(this._db);
  final Db _db;

  Isar get _isar => _db.isar;

  // ---- Routines ------------------------------------------------------------

  Future<Routine?> getActiveRoutine() async {
    return _isar.routines.filter().isActiveEqualTo(true).findFirst();
  }

  Stream<Routine?> watchActiveRoutine() {
    return _isar.routines
        .filter()
        .isActiveEqualTo(true)
        .watch(fireImmediately: true)
        .map((rs) => rs.isEmpty ? null : rs.first);
  }

  Future<List<Routine>> allRoutines() {
    return _isar.routines.where().sortByUpdatedAtDesc().findAll();
  }

  Future<void> activateRoutine(int routineId) async {
    await _isar.writeTxn(() async {
      final all = await _isar.routines.where().findAll();
      for (final r in all) {
        if (r.isActive && r.id != routineId) {
          r.isActive = false;
          await _isar.routines.put(r);
        }
      }
      final picked = await _isar.routines.get(routineId);
      if (picked != null) {
        picked.isActive = true;
        picked.updatedAt = DateTime.now();
        await _isar.routines.put(picked);
      }
    });
  }

  Future<Routine> saveRoutine(Routine routine) async {
    routine.updatedAt = DateTime.now();
    await _isar.writeTxn(() async {
      await _isar.routines.put(routine);
    });
    return routine;
  }

  Future<void> deleteRoutine(int id) async {
    await _isar.writeTxn(() async {
      await _isar.routines.delete(id);
    });
  }

  /// Resolve which routine day to do today.
  /// Strategy:
  ///   1. If the active routine has a day with weekday == today's weekday → that.
  ///   2. Otherwise, pick the day that hasn't been trained in the longest
  ///      (or the first day for a brand-new routine).
  ///   3. Returns null if there's no active routine or it has no days.
  Future<RoutineDay?> resolveTodaysDay(DateTime today) async {
    final routine = await getActiveRoutine();
    if (routine == null || routine.days.isEmpty) return null;

    final weekday = today.weekday; // 1=Mon..7=Sun
    final byWeekday = routine.days.where((d) => d.weekday == weekday);
    if (byWeekday.isNotEmpty) return byWeekday.first;

    // Find the day we've trained least recently.
    final recent = await _isar.workoutSessions
        .where()
        .sortByStartedAtDesc()
        .limit(20)
        .findAll();
    final lastTrainedByName = <String, DateTime>{};
    for (final s in recent) {
      lastTrainedByName.putIfAbsent(s.routineDayName, () => s.startedAt);
    }
    final pickable = routine.days.where((d) => !d.isRest).toList();
    if (pickable.isEmpty) return null;
    pickable.sort((a, b) {
      final at = lastTrainedByName[a.name] ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bt = lastTrainedByName[b.name] ?? DateTime.fromMillisecondsSinceEpoch(0);
      return at.compareTo(bt);
    });
    return pickable.first;
  }

  // ---- Sessions ------------------------------------------------------------

  Future<WorkoutSession> startSession({
    required String routineName,
    required String routineDayName,
  }) async {
    final now = DateTime.now();
    final s = WorkoutSession()
      ..dateKey = WorkoutSession.keyFor(now)
      ..startedAt = now
      ..routineName = routineName
      ..routineDayName = routineDayName;
    await _isar.writeTxn(() async {
      await _isar.workoutSessions.put(s);
    });
    return s;
  }

  Future<void> updateSession(WorkoutSession s) async {
    await _isar.writeTxn(() async {
      await _isar.workoutSessions.put(s);
    });
  }

  Future<void> completeSession(int id) async {
    await _isar.writeTxn(() async {
      final s = await _isar.workoutSessions.get(id);
      if (s == null) return;
      s.completedAt = DateTime.now();
      await _isar.workoutSessions.put(s);
    });
  }

  Future<void> deleteSession(int id) async {
    await _isar.writeTxn(() async {
      await _isar.workoutSessions.delete(id);
    });
  }

  Stream<List<WorkoutSession>> watchRecentSessions({int limit = 10}) {
    return _isar.workoutSessions
        .where()
        .sortByStartedAtDesc()
        .limit(limit)
        .watch(fireImmediately: true);
  }

  Stream<List<WorkoutSession>> watchAllSessions() {
    return _isar.workoutSessions
        .where()
        .sortByStartedAtDesc()
        .watch(fireImmediately: true);
  }

  Future<List<WorkoutSession>> sessionsSince(DateTime since) async {
    final all = await _isar.workoutSessions
        .where()
        .sortByStartedAtDesc()
        .findAll();
    return all.where((s) => s.startedAt.isAfter(since)).toList();
  }

  /// Returns the most recent completed sets for the given exercise so the
  /// logger can show "last time: 30 kg × 10".
  Future<List<SetEntry>> previousSetsFor(int exerciseId,
      {int sessionLimit = 5}) async {
    final sessions = await _isar.workoutSessions
        .where()
        .sortByStartedAtDesc()
        .findAll();
    for (final s in sessions) {
      final relevant = s.sets.where((e) => e.exerciseId == exerciseId).toList();
      if (relevant.isNotEmpty) return relevant;
    }
    return const [];
  }
}
