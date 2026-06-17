import 'package:isar/isar.dart';

import '../db.dart';
import '../models/body_measurement.dart';

class MeasurementRepo {
  MeasurementRepo(this._db);
  final Db _db;

  Isar get _isar => _db.isar;

  Stream<List<BodyMeasurement>> watchAll() {
    return _isar.bodyMeasurements
        .where()
        .sortByDateDesc()
        .watch(fireImmediately: true);
  }

  Future<List<BodyMeasurement>> all() {
    return _isar.bodyMeasurements.where().sortByDateDesc().findAll();
  }

  Future<BodyMeasurement?> latest() async {
    return _isar.bodyMeasurements.where().sortByDateDesc().findFirst();
  }

  Future<BodyMeasurement> save(BodyMeasurement m) async {
    await _isar.writeTxn(() async {
      await _isar.bodyMeasurements.put(m);
    });
    return m;
  }

  Future<void> delete(int id) async {
    await _isar.writeTxn(() async {
      await _isar.bodyMeasurements.delete(id);
    });
  }

  /// Rolling average weight over the last [windowDays] days.
  /// Returns null if not enough data.
  Future<double?> rollingAverageWeight({int windowDays = 7}) async {
    final since = DateTime.now().subtract(Duration(days: windowDays));
    final recent = await _isar.bodyMeasurements
        .filter()
        .dateGreaterThan(since)
        .findAll();
    if (recent.isEmpty) return null;
    final sum = recent.fold<double>(0, (s, m) => s + m.weightKg);
    return sum / recent.length;
  }
}
