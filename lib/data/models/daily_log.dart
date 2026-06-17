import 'package:isar/isar.dart';

part 'daily_log.g.dart';

@collection
class DailyLog {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String dateKey;

  int waterMl = 0;
  int? steps;
  int? heartRateAvg;
  int? sleepMinutes;

  DateTime createdAt = DateTime.now();
  DateTime updatedAt = DateTime.now();

  static String keyFor(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
