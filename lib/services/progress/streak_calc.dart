import '../../data/models/daily_log.dart';
import '../../data/models/food_entry.dart';
import '../../data/models/workout_session.dart';

class StreakCalc {
  /// Counts consecutive days ending today on which the user logged either a
  /// food entry or a workout session.
  static int currentStreak({
    required List<FoodEntry> foodEntries,
    required List<WorkoutSession> sessions,
    required DateTime today,
  }) {
    final activeDays = <String>{};
    for (final e in foodEntries) {
      activeDays.add(e.dateKey);
    }
    for (final s in sessions) {
      activeDays.add(DailyLog.keyFor(s.startedAt));
    }
    var streak = 0;
    var cursor = DateTime(today.year, today.month, today.day);
    // If today has nothing yet, start checking from yesterday.
    final todayKey = DailyLog.keyFor(cursor);
    if (!activeDays.contains(todayKey)) {
      cursor = cursor.subtract(const Duration(days: 1));
    }
    while (activeDays.contains(DailyLog.keyFor(cursor))) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }
}
