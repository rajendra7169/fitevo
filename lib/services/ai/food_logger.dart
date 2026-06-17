import '../../data/models/daily_log.dart';
import '../../data/models/enums.dart';
import '../../data/models/food_entry.dart';
import '../../data/repositories/nutrition_repo.dart';
import '../nutrition/usda_service.dart';
import 'ai_service.dart';

class FoodLogger {
  FoodLogger({
    required this.ai,
    required this.nutrition,
    required this.usda,
  });

  final AiService ai;
  final NutritionRepo nutrition;
  final UsdaService usda;

  Future<LogResult> logFromText(String input) async {
    final analysis = await ai.analyzeFoodText(input);
    return _persistAnalysis(analysis,
        rawInput: input, source: FoodSource.aiText);
  }

  Future<LogResult> logFromPhoto(List<int> bytes,
      {String? hint, String? photoPath}) async {
    final analysis = await ai.analyzeFoodPhoto(bytes, hint: hint);
    return _persistAnalysis(
      analysis,
      rawInput: hint ?? '(photo)',
      source: FoodSource.aiPhoto,
      photoPath: photoPath,
    );
  }

  Future<LogResult> _persistAnalysis(
    FoodAnalysis analysis, {
    required String rawInput,
    required FoodSource source,
    String? photoPath,
  }) async {
    final now = DateTime.now();
    final dateKey = DailyLog.keyFor(now);

    int totalKcal = 0;
    final entries = <FoodEntry>[];
    for (final item in analysis.items) {
      final adjusted = await _maybeCrossCheckUsda(item);
      final entry = FoodEntry()
        ..timestamp = now
        ..dateKey = dateKey
        ..rawInput = rawInput
        ..description = adjusted.name
        ..quantity = adjusted.quantity
        ..calories = adjusted.calories
        ..proteinG = adjusted.proteinG
        ..carbsG = adjusted.carbsG
        ..fatG = adjusted.fatG
        ..fiberG = adjusted.fiberG
        ..sodiumMg = adjusted.sodiumMg
        ..confidence = adjusted.confidence
        ..caloriesLow = adjusted.caloriesLow
        ..caloriesHigh = adjusted.caloriesHigh
        ..source = source
        ..photoPath = photoPath;
      entries.add(entry);
      totalKcal += entry.calories;
      await nutrition.addFoodEntry(entry);
    }

    return LogResult(
      entries: entries,
      totalCalories: totalKcal,
      hasLowConfidence:
          entries.any((e) => e.confidence == EstimateConfidence.low),
    );
  }

  Future<FoodItemAnalysis> _maybeCrossCheckUsda(FoodItemAnalysis item) async {
    if (item.confidence != EstimateConfidence.low) return item;
    if (!usda.isConfigured) return item;
    final words = item.name.trim().split(RegExp(r'\s+'));
    if (words.length > 4) return item;
    final hit = await usda.searchSingleFood(item.name);
    if (hit == null) return item;
    // Without a parsed gram weight we can't recompute exactly; just nudge
    // confidence up to medium when USDA confirms the food exists.
    return FoodItemAnalysis(
      name: item.name,
      quantity: item.quantity,
      calories: item.calories,
      proteinG: item.proteinG,
      carbsG: item.carbsG,
      fatG: item.fatG,
      fiberG: item.fiberG,
      sodiumMg: item.sodiumMg,
      confidence: EstimateConfidence.medium,
      caloriesLow: item.caloriesLow,
      caloriesHigh: item.caloriesHigh,
    );
  }
}

class LogResult {
  final List<FoodEntry> entries;
  final int totalCalories;
  final bool hasLowConfidence;

  const LogResult({
    required this.entries,
    required this.totalCalories,
    required this.hasLowConfidence,
  });
}
