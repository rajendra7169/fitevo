import 'package:isar/isar.dart';

import '../db.dart';
import '../models/profile.dart';

class ProfileRepo {
  ProfileRepo(this._db);
  final Db _db;

  Isar get _isar => _db.isar;

  Future<Profile?> getCurrent() async {
    return _isar.profiles.where().findFirst();
  }

  Stream<Profile?> watch() {
    return _isar.profiles
        .where()
        .watch(fireImmediately: true)
        .map((all) => all.isEmpty ? null : all.first);
  }

  Future<void> save(Profile profile) async {
    profile.updatedAt = DateTime.now();
    await _isar.writeTxn(() async {
      await _isar.profiles.put(profile);
    });
  }

  Future<void> clear() async {
    await _isar.writeTxn(() async {
      await _isar.profiles.clear();
    });
  }
}
