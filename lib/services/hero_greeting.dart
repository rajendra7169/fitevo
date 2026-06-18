/// Picks an app-appropriate hero greeting based on context (time of day,
/// today's calorie progress, current streak, and whether a workout was
/// completed today).
///
/// Priority (most specific wins): workout done → target hit → strong
/// streak → time-of-day with progress hint.
class HeroGreeting {
  final String phrase;
  final bool emphasiseStreak;
  const HeroGreeting({required this.phrase, this.emphasiseStreak = false});

  static HeroGreeting build({
    required DateTime now,
    required int caloriesConsumed,
    required int calorieTarget,
    required int streakDays,
    required bool workoutCompletedToday,
  }) {
    if (workoutCompletedToday) {
      return const HeroGreeting(phrase: 'Recover well');
    }
    if (calorieTarget > 0 && caloriesConsumed >= calorieTarget) {
      return const HeroGreeting(phrase: 'You hit it');
    }
    if (streakDays >= 7) {
      return HeroGreeting(
          phrase: 'Day $streakDays strong', emphasiseStreak: true);
    }

    final h = now.hour;
    final pct = calorieTarget > 0 ? caloriesConsumed / calorieTarget : 0.0;

    if (h < 5) return const HeroGreeting(phrase: 'Get some rest');
    if (h < 9) return const HeroGreeting(phrase: 'Let\'s fuel up');
    if (h < 12) {
      return HeroGreeting(
        phrase: pct > 0.2 ? 'Strong start' : 'Light up the day',
      );
    }
    if (h < 17) {
      if (pct > 0.4 && pct < 0.7) {
        return const HeroGreeting(phrase: 'Halfway there');
      }
      return HeroGreeting(
        phrase: pct < 0.2 ? 'Time to fuel' : 'Keep it going',
      );
    }
    if (h < 21) {
      if (pct > 0.85) return const HeroGreeting(phrase: 'Almost there');
      if (pct < 0.4) return const HeroGreeting(phrase: 'Plenty left to fuel');
      return const HeroGreeting(phrase: 'Wind down well');
    }
    return const HeroGreeting(phrase: 'Wind down');
  }
}
