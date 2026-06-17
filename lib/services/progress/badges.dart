import 'package:flutter/material.dart';

import '../../data/models/food_entry.dart';
import '../../data/models/workout_session.dart';
import '../workout/pr_tracker.dart';
import 'streak_calc.dart';

class Badge {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final bool earned;
  const Badge({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.earned,
  });
}

class BadgeEngine {
  static List<Badge> evaluate({
    required List<FoodEntry> foods,
    required List<WorkoutSession> sessions,
    required DateTime today,
  }) {
    final streak = StreakCalc.currentStreak(
      foodEntries: foods,
      sessions: sessions,
      today: today,
    );
    final hasPR = PrTracker.personalRecords(sessions).isNotEmpty;
    final completedSessions =
        sessions.where((s) => s.completedAt != null).length;

    return [
      Badge(
        id: 'first_meal',
        name: 'First bite',
        description: 'Log your first meal.',
        icon: Icons.restaurant_rounded,
        earned: foods.isNotEmpty,
      ),
      Badge(
        id: 'first_workout',
        name: 'First lift',
        description: 'Finish your first workout.',
        icon: Icons.fitness_center_rounded,
        earned: completedSessions >= 1,
      ),
      Badge(
        id: 'first_pr',
        name: 'New PR',
        description: 'Hit your first personal record.',
        icon: Icons.emoji_events_rounded,
        earned: hasPR,
      ),
      Badge(
        id: 'streak_7',
        name: '7-day streak',
        description: 'Stay active 7 days in a row.',
        icon: Icons.local_fire_department_rounded,
        earned: streak >= 7,
      ),
      Badge(
        id: 'streak_30',
        name: '30-day streak',
        description: 'A full month of consistency.',
        icon: Icons.whatshot_rounded,
        earned: streak >= 30,
      ),
      Badge(
        id: 'ten_sessions',
        name: '10 sessions',
        description: 'Finish 10 workouts.',
        icon: Icons.military_tech_rounded,
        earned: completedSessions >= 10,
      ),
    ];
  }
}
