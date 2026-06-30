import 'package:isar/isar.dart';

import '../db.dart';
import '../models/enums.dart';
import '../models/period_log.dart';

class PeriodRepo {
  PeriodRepo(this._db);
  final Db _db;

  Isar get _isar => _db.isar;

  /// Returns the entry for [date] if it exists, otherwise null.
  Future<PeriodLog?> getForDate(DateTime date) {
    return _isar.periodLogs
        .where()
        .dateKeyEqualTo(PeriodLog.keyFor(date))
        .findFirst();
  }

  /// Live stream of the entry for [date] — null when no log exists.
  Stream<PeriodLog?> watchForDate(DateTime date) {
    return _isar.periodLogs
        .where()
        .dateKeyEqualTo(PeriodLog.keyFor(date))
        .watch(fireImmediately: true)
        .map((rows) => rows.isEmpty ? null : rows.first);
  }

  /// Recent entries, most-recent first. Used by the home card to
  /// summarize the current cycle ("day 3 of period").
  Future<List<PeriodLog>> recent({int limit = 90}) {
    return _isar.periodLogs
        .where()
        .sortByDateDesc()
        .limit(limit)
        .findAll();
  }

  Stream<List<PeriodLog>> watchRecent({int limit = 90}) {
    return _isar.periodLogs
        .where()
        .sortByDateDesc()
        .limit(limit)
        .watch(fireImmediately: true);
  }

  /// Upserts the entry for [date]. Setting flow to none and symptoms
  /// empty + notes empty deletes the row instead — keeping the
  /// collection sparse so cycle-length math doesn't trip over "logged
  /// nothing" sentinel rows.
  Future<void> setEntry(
    DateTime date, {
    required MenstrualFlow flow,
    List<PeriodSymptom> symptoms = const [],
    String notes = '',
  }) async {
    final key = PeriodLog.keyFor(date);
    await _isar.writeTxn(() async {
      final existing = await _isar.periodLogs
          .where()
          .dateKeyEqualTo(key)
          .findFirst();
      final isEmpty =
          flow == MenstrualFlow.none && symptoms.isEmpty && notes.isEmpty;
      if (isEmpty) {
        if (existing != null) await _isar.periodLogs.delete(existing.id);
        return;
      }
      final row = existing ?? PeriodLog();
      row.dateKey = key;
      row.date = DateTime(date.year, date.month, date.day);
      row.flow = flow;
      row.symptoms = List<PeriodSymptom>.from(symptoms);
      row.notes = notes;
      row.updatedAt = DateTime.now();
      // Preserve original createdAt on an update; stamp now on insert.
      if (existing == null) row.createdAt = DateTime.now();
      await _isar.periodLogs.put(row);
    });
  }

  Future<void> clear(DateTime date) async {
    final key = PeriodLog.keyFor(date);
    await _isar.writeTxn(() async {
      final existing = await _isar.periodLogs
          .where()
          .dateKeyEqualTo(key)
          .findFirst();
      if (existing != null) await _isar.periodLogs.delete(existing.id);
    });
  }
}

/// Cycle-derived insight surfaced on the home card. None of the fields
/// are required for logging — they just give the user something useful
/// (and the coach something to chew on) once a few period days exist.
class CycleInsight {
  /// Number of days since the most recent period-flow day (>= spotting).
  /// Null when no flow has ever been logged.
  final int? daysSinceLastFlow;

  /// Estimated cycle length in days, from the gap between the most
  /// recent two distinct period starts. Null when only one period
  /// has been logged (or none).
  final int? estimatedCycleLength;

  /// True today has a logged period entry with flow >= spotting.
  final bool todayIsPeriodDay;

  /// The current period's day count (1, 2, 3…) when [todayIsPeriodDay]
  /// is true. Null otherwise.
  final int? currentPeriodDay;

  const CycleInsight({
    this.daysSinceLastFlow,
    this.estimatedCycleLength,
    this.todayIsPeriodDay = false,
    this.currentPeriodDay,
  });

  /// Derives an insight from the recent log list (already sorted
  /// most-recent-first by the repo). Handles the common cases without
  /// trying to be a full cycle-tracking algorithm.
  static CycleInsight from(List<PeriodLog> recent, DateTime today) {
    final flowDays = recent
        .where((e) => e.flow != MenstrualFlow.none)
        .toList(); // already date-desc
    if (flowDays.isEmpty) return const CycleInsight();

    final todayKey = PeriodLog.keyFor(today);
    final todayEntry = flowDays.where((e) => e.dateKey == todayKey).toList();
    final todayIsPeriodDay = todayEntry.isNotEmpty &&
        todayEntry.first.flow != MenstrualFlow.none;

    // Days since the most recent flow day.
    final mostRecent = flowDays.first.date;
    final daysSince = today.difference(mostRecent).inDays;

    // Group consecutive flow days into "periods" to estimate cycle length.
    // A gap of >= 3 days between consecutive logged flow days is treated
    // as a new period.
    final periods = <List<DateTime>>[];
    List<DateTime> current = [];
    for (final e in flowDays.reversed) {
      if (current.isEmpty) {
        current = [e.date];
      } else {
        final gap = e.date.difference(current.last).inDays;
        if (gap <= 2) {
          current.add(e.date);
        } else {
          periods.add(current);
          current = [e.date];
        }
      }
    }
    if (current.isNotEmpty) periods.add(current);

    int? estCycle;
    if (periods.length >= 2) {
      final a = periods[periods.length - 2].first;
      final b = periods.last.first;
      estCycle = b.difference(a).inDays;
    }

    int? currentPeriodDay;
    if (todayIsPeriodDay && periods.isNotEmpty) {
      currentPeriodDay =
          today.difference(periods.last.first).inDays + 1;
    }

    return CycleInsight(
      daysSinceLastFlow: daysSince,
      estimatedCycleLength: estCycle,
      todayIsPeriodDay: todayIsPeriodDay,
      currentPeriodDay: currentPeriodDay,
    );
  }
}
