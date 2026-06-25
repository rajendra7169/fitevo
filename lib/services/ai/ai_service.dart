import '../../data/models/enums.dart';

class RoutinePlanExercise {
  final String name;
  final int sets;
  final int repsLow;
  final int repsHigh;
  final String? notes;
  const RoutinePlanExercise({
    required this.name,
    required this.sets,
    required this.repsLow,
    required this.repsHigh,
    this.notes,
  });
}

class RoutinePlanDay {
  final String name;
  final int weekday; // 1=Mon..7=Sun, 0=unassigned
  final bool isRest;
  final List<RoutinePlanExercise> exercises;
  const RoutinePlanDay({
    required this.name,
    required this.weekday,
    required this.isRest,
    required this.exercises,
  });
}

class RoutinePlan {
  final String name;
  final List<RoutinePlanDay> days;
  const RoutinePlan({required this.name, required this.days});
}

class FoodItemAnalysis {
  final String name;
  final String quantity;
  final int calories;
  final int proteinG;
  final int carbsG;
  final int fatG;
  final int fiberG;
  final int sodiumMg;
  final EstimateConfidence confidence;
  final int? caloriesLow;
  final int? caloriesHigh;

  const FoodItemAnalysis({
    required this.name,
    required this.quantity,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.fiberG,
    required this.sodiumMg,
    required this.confidence,
    this.caloriesLow,
    this.caloriesHigh,
  });
}

class FoodAnalysis {
  final List<FoodItemAnalysis> items;
  final int totalCalories;
  final int totalProteinG;
  final int totalCarbsG;
  final int totalFatG;
  final int totalFiberG;
  final int totalSodiumMg;

  /// When set, the model didn't have enough info to log confidently and
  /// is asking for one short clarification (e.g. "How many eggs?").
  /// The UI shows this as an inline chip below the input — when the
  /// user answers, the AI is re-prompted with both the original input
  /// and the answer combined.
  final String? clarificationQuestion;

  /// True when the response is purely a clarification request — no
  /// items were estimated. Use this to skip logging entirely.
  bool get needsClarification =>
      clarificationQuestion != null && clarificationQuestion!.isNotEmpty;

  const FoodAnalysis({
    required this.items,
    required this.totalCalories,
    required this.totalProteinG,
    required this.totalCarbsG,
    required this.totalFatG,
    required this.totalFiberG,
    required this.totalSodiumMg,
    this.clarificationQuestion,
  });

  /// Convenience constructor for a clarification-only response — no
  /// estimates, just the question.
  factory FoodAnalysis.clarification(String question) => FoodAnalysis(
        items: const [],
        totalCalories: 0,
        totalProteinG: 0,
        totalCarbsG: 0,
        totalFatG: 0,
        totalFiberG: 0,
        totalSodiumMg: 0,
        clarificationQuestion: question,
      );
}

class CoachMessage {
  final bool fromUser;
  final String text;
  final DateTime timestamp;
  const CoachMessage({
    required this.fromUser,
    required this.text,
    required this.timestamp,
  });
}

class MealSuggestion {
  final String name;
  final int calories;
  final int proteinG;
  final String? portion;
  final String? note;
  const MealSuggestion({
    required this.name,
    required this.calories,
    required this.proteinG,
    this.portion,
    this.note,
  });
}

abstract class AiService {
  Future<FoodAnalysis> analyzeFoodText(String input);
  Future<FoodAnalysis> analyzeFoodPhoto(List<int> imageBytes, {String? hint});
  Future<RoutinePlan> generateStarterRoutine({
    required FitnessGoal goal,
    required int trainingDaysPerWeek,
    required List<String> libraryExerciseNames,
  });
  Future<String> coachChat({
    required String userContext,
    required List<CoachMessage> history,
    required String latestUserMessage,
  });
  Future<String> weeklyReview({
    required String contextSummary,
  });
  Future<String> targetsAdvisory({
    required String profileSummary,
  });
  Future<List<MealSuggestion>> suggestMeals({
    required int caloriesRemaining,
    required int proteinGRemaining,
    required int carbsGRemaining,
    required int fatGRemaining,
    String? cuisineHint,
  });
}

class AiException implements Exception {
  final String message;
  AiException(this.message);

  @override
  String toString() => message;
}

class AiNotConfiguredException extends AiException {
  AiNotConfiguredException()
      : super(
            'AI is not configured. Add your free Groq API key (console.groq.com) or Gemini key (aistudio.google.com) to enable logging.');
}
