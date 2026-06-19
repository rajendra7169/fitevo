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

  // Actual activity logged today — overrides the Profile's weekly
  // average for today's calorie target so users who skip running on a
  // rest day don't get phantom burn credit, and users who run extra
  // get the extra calories on the day they earned them.
  double walkingKmToday = 0;
  double runningKmToday = 0;
  int otherCardioMinutes = 0;
  String? activityNote;

  DateTime createdAt = DateTime.now();
  DateTime updatedAt = DateTime.now();

  static String keyFor(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
