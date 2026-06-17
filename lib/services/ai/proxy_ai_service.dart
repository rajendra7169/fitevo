import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../data/models/enums.dart';
import 'ai_service.dart';

/// `ProxyAiService` forwards every AiService call to a backend endpoint
/// instead of calling Gemini directly from the device.
///
/// Why: shipping the Gemini API key with the app exposes it to anyone who
/// inspects the binary. The Phase 3 plan is to:
///   1. Stand up a Cloudflare Worker or Supabase Edge Function that holds
///      the key as a secret and proxies requests to Gemini.
///   2. Point [baseUrl] at that endpoint (via --dart-define=AI_PROXY_URL=...).
///   3. The provider in providers.dart auto-picks ProxyAiService when the
///      env var is set, so no code change is needed in the rest of the app.
///
/// Endpoints expected (POST JSON, JSON response — same shapes the Gemini
/// service already produces/consumes):
///   POST /food/analyze-text        → FoodAnalysis
///   POST /food/analyze-photo       → FoodAnalysis (multipart: image + hint)
///   POST /routine/generate          → RoutinePlan
///   POST /coach/chat                → { "text": "..." }
///   POST /coach/weekly-review       → { "text": "..." }
///   POST /food/suggest-meals        → { "suggestions": [...] }
class ProxyAiService implements AiService {
  ProxyAiService({required this.baseUrl, http.Client? client})
      : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  Uri _u(String path) => Uri.parse('$baseUrl$path');

  Map<String, String> get _headers => {'Content-Type': 'application/json'};

  Future<Map<String, dynamic>> _postJson(
      String path, Map<String, dynamic> body) async {
    final res = await _client.post(_u(path),
        headers: _headers, body: jsonEncode(body));
    if (res.statusCode >= 400) {
      throw AiException('Proxy ${res.statusCode}: ${res.body}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  @override
  Future<FoodAnalysis> analyzeFoodText(String input) async {
    final json = await _postJson('/food/analyze-text', {'input': input});
    return _parseFoodAnalysis(json);
  }

  @override
  Future<FoodAnalysis> analyzeFoodPhoto(List<int> imageBytes,
      {String? hint}) async {
    final json = await _postJson('/food/analyze-photo', {
      'imageBase64': base64Encode(imageBytes),
      'hint': ?hint,
    });
    return _parseFoodAnalysis(json);
  }

  @override
  Future<RoutinePlan> generateStarterRoutine({
    required FitnessGoal goal,
    required int trainingDaysPerWeek,
    required List<String> libraryExerciseNames,
  }) async {
    final json = await _postJson('/routine/generate', {
      'goal': goal.name,
      'trainingDaysPerWeek': trainingDaysPerWeek,
      'library': libraryExerciseNames,
    });
    return _parseRoutinePlan(json);
  }

  @override
  Future<String> coachChat({
    required String userContext,
    required List<CoachMessage> history,
    required String latestUserMessage,
  }) async {
    final json = await _postJson('/coach/chat', {
      'context': userContext,
      'history': history
          .map((m) => {
                'fromUser': m.fromUser,
                'text': m.text,
                'timestamp': m.timestamp.toIso8601String(),
              })
          .toList(),
      'message': latestUserMessage,
    });
    return (json['text'] as String?) ?? '';
  }

  @override
  Future<String> weeklyReview({required String contextSummary}) async {
    final json = await _postJson('/coach/weekly-review', {
      'context': contextSummary,
    });
    return (json['text'] as String?) ?? '';
  }

  @override
  Future<List<MealSuggestion>> suggestMeals({
    required int caloriesRemaining,
    required int proteinGRemaining,
    required int carbsGRemaining,
    required int fatGRemaining,
    String? cuisineHint,
  }) async {
    final json = await _postJson('/food/suggest-meals', {
      'caloriesRemaining': caloriesRemaining,
      'proteinGRemaining': proteinGRemaining,
      'carbsGRemaining': carbsGRemaining,
      'fatGRemaining': fatGRemaining,
      'cuisineHint': ?cuisineHint,
    });
    final list = (json['suggestions'] as List?) ?? const [];
    return list.whereType<Map>().map((m) {
      final mm = Map<String, dynamic>.from(m);
      return MealSuggestion(
        name: (mm['name'] as String?)?.trim() ?? 'meal',
        calories: _i(mm['calories']) ?? 0,
        proteinG: _i(mm['protein_g']) ?? 0,
        portion: (mm['portion'] as String?)?.trim(),
        note: (mm['note'] as String?)?.trim(),
      );
    }).toList();
  }

  FoodAnalysis _parseFoodAnalysis(Map<String, dynamic> json) {
    final items = ((json['items'] as List?) ?? const [])
        .whereType<Map>()
        .map((m) {
      final mm = Map<String, dynamic>.from(m);
      return FoodItemAnalysis(
        name: (mm['name'] as String?)?.trim() ?? 'food',
        quantity: (mm['quantity'] as String?)?.trim() ?? '',
        calories: _i(mm['calories']) ?? 0,
        proteinG: _i(mm['protein_g']) ?? 0,
        carbsG: _i(mm['carbs_g']) ?? 0,
        fatG: _i(mm['fat_g']) ?? 0,
        fiberG: _i(mm['fiber_g']) ?? 0,
        sodiumMg: _i(mm['sodium_mg']) ?? 0,
        confidence: _confidence(mm['confidence'] as String?),
        caloriesLow: _i((mm['range'] as Map?)?['calories_low']),
        caloriesHigh: _i((mm['range'] as Map?)?['calories_high']),
      );
    }).toList();
    final totals = (json['totals'] as Map?)?.cast<String, dynamic>() ?? {};
    return FoodAnalysis(
      items: items,
      totalCalories: _i(totals['calories']) ??
          items.fold<int>(0, (s, e) => s + e.calories),
      totalProteinG: _i(totals['protein_g']) ??
          items.fold<int>(0, (s, e) => s + e.proteinG),
      totalCarbsG:
          _i(totals['carbs_g']) ?? items.fold<int>(0, (s, e) => s + e.carbsG),
      totalFatG:
          _i(totals['fat_g']) ?? items.fold<int>(0, (s, e) => s + e.fatG),
      totalFiberG:
          _i(totals['fiber_g']) ?? items.fold<int>(0, (s, e) => s + e.fiberG),
      totalSodiumMg: _i(totals['sodium_mg']) ??
          items.fold<int>(0, (s, e) => s + e.sodiumMg),
    );
  }

  RoutinePlan _parseRoutinePlan(Map<String, dynamic> json) {
    final name = (json['name'] as String?)?.trim() ?? 'My routine';
    final days = ((json['days'] as List?) ?? const [])
        .whereType<Map>()
        .map((d) {
      final dm = Map<String, dynamic>.from(d);
      return RoutinePlanDay(
        name: (dm['name'] as String?)?.trim() ?? 'Day',
        weekday: _i(dm['weekday']) ?? 0,
        isRest: (dm['is_rest'] as bool?) ?? false,
        exercises: ((dm['exercises'] as List?) ?? const [])
            .whereType<Map>()
            .map((e) {
          final em = Map<String, dynamic>.from(e);
          return RoutinePlanExercise(
            name: (em['name'] as String?)?.trim() ?? 'Exercise',
            sets: _i(em['sets']) ?? 3,
            repsLow: _i(em['reps_low']) ?? 8,
            repsHigh: _i(em['reps_high']) ?? 12,
            notes: (em['notes'] as String?)?.trim(),
          );
        }).toList(),
      );
    }).toList();
    return RoutinePlan(name: name, days: days);
  }

  EstimateConfidence _confidence(String? raw) {
    switch (raw?.toLowerCase()) {
      case 'high':
        return EstimateConfidence.high;
      case 'low':
        return EstimateConfidence.low;
      default:
        return EstimateConfidence.medium;
    }
  }

  int? _i(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.round();
    if (v is String) return int.tryParse(v) ?? double.tryParse(v)?.round();
    return null;
  }
}
