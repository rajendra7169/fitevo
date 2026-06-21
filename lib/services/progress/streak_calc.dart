import '../../data/models/daily_log.dart';
import '../../data/models/food_entry.dart';
import '../../data/models/workout_session.dart';

class StreakCalc {
  /// Counts consecutive days ending today on which the user logged either
  /// a food entry or a workout session. Supports an optional grace
  /// budget: 1 missed day is forgiven for every 7-day window walked back,
  /// so a single off day doesn't shatter long streaks.
  static int currentStreak({
    required List<FoodEntry> foodEntries,
    required List<WorkoutSession> sessions,
    required DateTime today,
    bool allowFreeze = true,
  }) {
    final activeDays = <String>{};
    for (final e in foodEntries) {
      activeDays.add(e.dateKey);
    }
    for (final s in sessions) {
      activeDays.add(DailyLog.keyFor(s.startedAt));
    }
    var streak = 0;
    var freezesUsed = 0;
    var cursor = DateTime(today.year, today.month, today.day);
    // If today has nothing yet, start checking from yesterday.
    final todayKey = DailyLog.keyFor(cursor);
    if (!activeDays.contains(todayKey)) {
      cursor = cursor.subtract(const Duration(days: 1));
    }
    while (true) {
      final key = DailyLog.keyFor(cursor);
      if (activeDays.contains(key)) {
        streak++;
        cursor = cursor.subtract(const Duration(days: 1));
        continue;
      }
      // Try a freeze: 1 per started 7-day window. e.g. you can spend a
      // freeze at any point in days 1-7, days 8-14, etc.
      if (allowFreeze) {
        final windowIndex = streak ~/ 7; // 0 for first week, 1 for 2nd…
        if (freezesUsed <= windowIndex) {
          freezesUsed++;
          cursor = cursor.subtract(const Duration(days: 1));
          continue;
        }
      }
      break;
    }
    return streak;
  }
}
