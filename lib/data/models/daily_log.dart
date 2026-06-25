import 'package:isar/isar.dart';

part 'daily_log.g.dart';

@collection
class DailyLog {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String dateKey;

  int waterMl = 0;
  // Timestamped water sips so the detail page can show "when" not just
  // "how much". Each entry is (minute-of-day, ml). The aggregate
  // [waterMl] is kept in sync for legacy queries.
  List<WaterEntry> waterEntries = [];
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

/// Single sip / glass / bottle the user logged. Stored embedded inside
/// the day's DailyLog so the per-day timeline is one read.
@embedded
class WaterEntry {
  /// Minute-of-day the sip was logged (0..1439).
  int minutesOfDay = 0;

  /// Volume in ml. Typical quick-add values: 200, 250, 500, 750.
  int ml = 0;
}
