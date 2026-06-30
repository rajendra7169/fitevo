import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../ai/ai_service.dart';
import '../../data/models/daily_log.dart';
import '../../data/models/food_entry.dart';
import '../../data/models/profile.dart';
import '../../data/repositories/nutrition_repo.dart';
import '../../home/todays_activity_card.dart' show TodaysActivityMath;

/// A 3-meal plan for a single day. Generated once per day, cached so
/// the user sees the same plan across restarts and so we don't burn
/// AI calls on every rebuild.
class DailyMealPlan {
  /// YYYY-MM-DD anchor for the cache key.
  final String dateKey;

  /// Slot label per item — breakfast / lunch / dinner. Always length 3
  /// when [meals] is length 3; not used as a hard constraint, the AI
  /// just suggests 3 meals and the UI labels them by position.
  static const slots = ['Breakfast', 'Lunch', 'Dinner'];

  /// The actual suggestions. Should be length 3 — caller treats fewer
  /// as a partial result and prompts to regenerate.
  final List<MealSuggestion> meals;

  final DateTime generatedAt;

  const DailyMealPlan({
    required this.dateKey,
    required this.meals,
    required this.generatedAt,
  });

  Map<String, dynamic> toJson() => {
        'dateKey': dateKey,
        'generatedAt': generatedAt.toIso8601String(),
        'meals': meals
            .map((m) => {
                  'name': m.name,
                  'calories': m.calories,
                  'proteinG': m.proteinG,
                  'portion': m.portion,
                  'note': m.note,
                })
            .toList(),
      };

  static DailyMealPlan? fromJson(Map<String, dynamic>? j) {
    if (j == null) return null;
    try {
      final list = (j['meals'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map((m) => MealSuggestion(
                name: (m['name'] as String?) ?? '',
                calories: (m['calories'] as num?)?.toInt() ?? 0,
                proteinG: (m['proteinG'] as num?)?.toInt() ?? 0,
                portion: m['portion'] as String?,
                note: m['note'] as String?,
              ))
          .toList();
      return DailyMealPlan(
        dateKey: (j['dateKey'] as String?) ?? '',
        meals: list,
        generatedAt: DateTime.tryParse(j['generatedAt'] as String? ?? '') ??
            DateTime.now(),
      );
    } catch (_) {
      return null;
    }
  }
}

class DailyMealPlanService {
  static const _prefsKey = 'home.dailyMealPlan.v1';

  /// Load the cached plan if it exists and is for today. Null
  /// otherwise — caller decides whether to generate fresh.
  static Future<DailyMealPlan?> loadForToday() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final parsed = jsonDecode(raw);
      if (parsed is! Map<String, dynamic>) return null;
      final plan = DailyMealPlan.fromJson(parsed);
      if (plan == null) return null;
      if (plan.dateKey != DailyLog.keyFor(DateTime.now())) return null;
      return plan;
    } catch (_) {
      return null;
    }
  }

  static Future<void> save(DailyMealPlan plan) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(plan.toJson()));
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }

  /// Hits the AI to generate a 3-meal plan that fits the user's
  /// full-day target. Uses the same culturally-aware suggestMeals
  /// surface so diet preference + country routing already work.
  ///
  /// [allFoods] is the user's full food history — used to compute the
  /// "foods they actually eat" vocabulary so suggestions are anchored
  /// to dal-bhat / paneer / chickpeas (whatever they really eat) rather
  /// than generic Western defaults. Caller passes the full list; the
  /// repo's recentFoodVocabulary clips to the recent window + dedupes.
  static Future<DailyMealPlan> generate({
    required AiService ai,
    required Profile profile,
    required DailyLog? todayLog,
    List<FoodEntry> allFoods = const [],
  }) async {
    final calT = TodaysActivityMath.effectiveTodayCalorieTarget(
        profile: profile, log: todayLog);
    final macros = TodaysActivityMath.effectiveTodayMacros(
        profile: profile, log: todayLog);
    final vocab = NutritionRepo.recentFoodVocabulary(allFoods);

    // Hand the AI the PER-MEAL macro envelope, not the whole day. The
    // prompt already caps each meal at 35% of the daily budget — this
    // wires that math into the request itself so the model isn't free
    // to interpret "calories remaining" as "make one giant meal".
    // Split into 3 (breakfast / lunch / dinner) with a small lean
    // toward lunch + dinner.
    int perMealKcal(double share) => (calT * share).round();
    int perMealG(int total, double share) => (total * share).round();

    // Average share for the prompt — the cap in the system prompt
    // still binds the upper end; this just keeps the central
    // suggestion realistic.
    const share = 0.33;
    final suggestions = await ai.suggestMeals(
      caloriesRemaining: perMealKcal(share),
      proteinGRemaining: perMealG(macros.proteinG, share),
      carbsGRemaining: perMealG(macros.carbG, share),
      fatGRemaining: perMealG(macros.fatG, share),
      cuisineHint: profile.country.isEmpty ? null : profile.country,
      recentFoodHistory: vocab,
      dietPreference: profile.dietPreference.name,
    );
    // We always store the first 3; if the model gave fewer, the UI
    // shows what's there + a regenerate button.
    final trimmed = suggestions.take(3).toList();
    final plan = DailyMealPlan(
      dateKey: DailyLog.keyFor(DateTime.now()),
      meals: trimmed,
      generatedAt: DateTime.now(),
    );
    await save(plan);
    return plan;
  }
}
