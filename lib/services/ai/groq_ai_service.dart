import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../../data/models/enums.dart';
import 'ai_service.dart';

const String _baseUrl = 'https://api.groq.com/openai/v1';
const String _defaultTextModel = 'llama-3.3-70b-versatile';
const String _defaultVisionModel = 'meta-llama/llama-4-scout-17b-16e-instruct';

const String _foodSystemPrompt = '''
You are a nutrition estimation assistant.
Given a food description (or list of foods) and quantity, return estimated nutrition as STRICT JSON only.
Estimate per the described quantity. If unsure, give a best estimate AND a low/high calorie range.
Be realistic, not falsely precise. Do not refuse normal foods. Do not add commentary or markdown.

Required JSON shape:
{
  "items": [
    {
      "name": "string",
      "quantity": "string",
      "calories": 0,
      "protein_g": 0,
      "carbs_g": 0,
      "fat_g": 0,
      "fiber_g": 0,
      "sodium_mg": 0,
      "confidence": "high | medium | low",
      "range": { "calories_low": 0, "calories_high": 0 }
    }
  ],
  "totals": {
    "calories": 0, "protein_g": 0, "carbs_g": 0,
    "fat_g": 0, "fiber_g": 0, "sodium_mg": 0
  }
}

Rules:
- All numeric fields are integers.
- Totals MUST equal the sum of items.
- Output JSON only. No prose, no markdown fences.
''';

const String _routineSystemPrompt = '''
You are a beginner-friendly personal trainer.
Build a safe, sensible workout split given a goal and the number of training days per week.

Rules:
- Pick 4-7 exercises per training day.
- Use standard, widely-known exercise names. Prefer library names provided.
- Mix compound and isolation movements appropriately.
- Spread training across the week with rest days.
- weekday: 1=Mon..7=Sun. Mark rest days "is_rest": true, exercises: [].
- Sensible rep ranges: 5-8 strength, 8-12 hypertrophy, 12-20 endurance.
- Output STRICT JSON only.

JSON shape:
{
  "name": "string",
  "days": [
    {
      "name": "string",
      "weekday": 1,
      "is_rest": false,
      "exercises": [
        {"name": "string", "sets": 3, "reps_low": 8, "reps_high": 12, "notes": null}
      ]
    }
  ]
}
''';

const String _coachSystemPrompt = '''
You are a friendly, beginner-aware fitness coach inside the Fitevo app.

Style:
- Supportive, conversational, practical. Short paragraphs, no markdown headers.
- Celebrate small wins. Never shame, never use restrictive or fear-based language.
- Respect safety guardrails: do not push aggressive calorie deficits/surpluses,
  or unsafe weight-change pacing (cap ~0.75% bodyweight/week).
- Form over weight. Beginners should start light and build technique first.
- If asked about medical conditions, injury, or medication, advise consulting a professional.

Output: plain text, 1-4 short paragraphs. No JSON.
''';

const String _mealSuggestionPrompt = '''
You are a nutrition coach helping the user fit their remaining macros.

Rules:
- Suggest 3 simple meal ideas that approximately fit the macros provided.
- Prefer everyday, easy-to-prepare foods.
- Realistic estimates, not falsely precise.
- Output STRICT JSON only.

JSON shape:
{
  "suggestions": [
    {
      "name": "string",
      "portion": "string",
      "calories": 0,
      "protein_g": 0,
      "note": "optional"
    }
  ]
}
''';

class GroqAiService implements AiService {
  GroqAiService({
    required String apiKey,
    http.Client? client,
    String? textModel,
    String? visionModel,
  })  : _apiKey = apiKey,
        _client = client ?? http.Client(),
        _textModel = textModel ?? _defaultTextModel,
        _visionModel = visionModel ?? _defaultVisionModel;

  final String _apiKey;
  final http.Client _client;
  final String _textModel;
  final String _visionModel;

  Map<String, String> get _headers => {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      };

  Future<Map<String, dynamic>> _chat({
    required String model,
    required List<Map<String, dynamic>> messages,
    bool json = false,
    double temperature = 0.3,
  }) async {
    if (_apiKey.isEmpty) throw AiNotConfiguredException();
    final body = <String, dynamic>{
      'model': model,
      'messages': messages,
      'temperature': temperature,
      if (json) 'response_format': {'type': 'json_object'},
    };

    const maxAttempts = 3;
    Object? lastErr;
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      try {
        final res = await _client.post(
          Uri.parse('$_baseUrl/chat/completions'),
          headers: _headers,
          body: jsonEncode(body),
        );
        if (res.statusCode == 429 || res.statusCode >= 500) {
          throw _RetryableError(res.statusCode, res.body);
        }
        if (res.statusCode >= 400) {
          throw AiException(_friendly(res.statusCode, res.body));
        }
        return jsonDecode(res.body) as Map<String, dynamic>;
      } on AiException {
        rethrow;
      } catch (e) {
        lastErr = e;
        if (attempt == maxAttempts - 1) break;
        final backoffMs = (600 * pow(2, attempt)).toInt();
        await Future.delayed(Duration(milliseconds: backoffMs));
      }
    }
    throw AiException('AI request failed: $lastErr');
  }

  String _extract(Map<String, dynamic> response) {
    final choices = response['choices'] as List?;
    if (choices == null || choices.isEmpty) {
      throw AiException('Empty response from AI.');
    }
    final msg = (choices.first as Map)['message'] as Map?;
    final content = msg?['content'];
    if (content is String && content.trim().isNotEmpty) {
      return content.trim();
    }
    if (content is List) {
      final parts =
          content.whereType<Map>().map((p) => p['text']).whereType<String>();
      final joined = parts.join('\n').trim();
      if (joined.isNotEmpty) return joined;
    }
    throw AiException('Empty response from AI.');
  }

  String _friendly(int status, String body) {
    final lower = body.toLowerCase();
    if (status == 401 || status == 403) return 'AI key is invalid or revoked.';
    if (status == 429 ||
        lower.contains('rate limit') ||
        lower.contains('quota')) {
      return 'Daily AI limit reached. Try again later.';
    }
    return 'AI service error ($status).';
  }

  // --- AiService implementation -----------------------------------------

  @override
  Future<FoodAnalysis> analyzeFoodText(String input) async {
    final trimmed = input.trim();
    if (trimmed.isEmpty) throw AiException('Empty input.');
    final response = await _chat(
      model: _textModel,
      json: true,
      temperature: 0.2,
      messages: [
        {'role': 'system', 'content': _foodSystemPrompt},
        {'role': 'user', 'content': trimmed},
      ],
    );
    return _parseFoodAnalysis(_extract(response));
  }

  @override
  Future<FoodAnalysis> analyzeFoodPhoto(List<int> imageBytes,
      {String? hint}) async {
    if (imageBytes.isEmpty) throw AiException('Empty photo.');
    final b64 = base64Encode(Uint8List.fromList(imageBytes));
    final response = await _chat(
      model: _visionModel,
      json: false, // many vision models don't honor json mode reliably
      temperature: 0.2,
      messages: [
        {
          'role': 'user',
          'content': [
            {
              'type': 'text',
              'text':
                  '$_foodSystemPrompt\n\nIdentify each food in this photo and estimate nutrition per visible portion. ${hint ?? ''}'
                      .trim(),
            },
            {
              'type': 'image_url',
              'image_url': {'url': 'data:image/jpeg;base64,$b64'},
            },
          ],
        },
      ],
    );
    return _parseFoodAnalysis(_extract(response));
  }

  @override
  Future<RoutinePlan> generateStarterRoutine({
    required FitnessGoal goal,
    required int trainingDaysPerWeek,
    required List<String> libraryExerciseNames,
  }) async {
    final goalLabel = switch (goal) {
      FitnessGoal.buildMuscle => 'build muscle (modest surplus)',
      FitnessGoal.loseFat => 'lose fat while preserving muscle',
      FitnessGoal.recomp => 'body recomposition (slow change)',
      FitnessGoal.generalFitness => 'general fitness and strength',
    };
    final prompt =
        'Build a beginner-friendly $trainingDaysPerWeek-day-per-week routine for someone whose goal is $goalLabel.\n'
        'Prefer exercises from this library when they fit:\n${libraryExerciseNames.join(', ')}.\n'
        'Return JSON only.';
    final response = await _chat(
      model: _textModel,
      json: true,
      temperature: 0.3,
      messages: [
        {'role': 'system', 'content': _routineSystemPrompt},
        {'role': 'user', 'content': prompt},
      ],
    );
    return _parseRoutine(_extract(response));
  }

  @override
  Future<String> coachChat({
    required String userContext,
    required List<CoachMessage> history,
    required String latestUserMessage,
  }) async {
    final messages = <Map<String, dynamic>>[
      {'role': 'system', 'content': _coachSystemPrompt},
      {
        'role': 'system',
        'content': 'User profile and recent context:\n$userContext',
      },
      ...history.map((m) => {
            'role': m.fromUser ? 'user' : 'assistant',
            'content': m.text,
          }),
      {'role': 'user', 'content': latestUserMessage},
    ];
    final response = await _chat(
      model: _textModel,
      temperature: 0.6,
      messages: messages,
    );
    return _extract(response);
  }

  @override
  Future<String> weeklyReview({required String contextSummary}) async {
    final response = await _chat(
      model: _textModel,
      temperature: 0.5,
      messages: [
        {'role': 'system', 'content': _coachSystemPrompt},
        {
          'role': 'user',
          'content':
              'Write a short weekly review (3-5 sentences) of this user\'s week. '
                  'Acknowledge specific wins, then suggest 1-2 small, encouraging adjustments.\n\n$contextSummary',
        },
      ],
    );
    return _extract(response);
  }

  @override
  Future<List<MealSuggestion>> suggestMeals({
    required int caloriesRemaining,
    required int proteinGRemaining,
    required int carbsGRemaining,
    required int fatGRemaining,
    String? cuisineHint,
  }) async {
    final prompt = 'Suggest 3 simple meal ideas to fit roughly:\n'
        'Calories left: $caloriesRemaining kcal\n'
        'Protein left: ${proteinGRemaining}g\n'
        'Carbs left: ${carbsGRemaining}g\n'
        'Fat left: ${fatGRemaining}g\n'
        '${cuisineHint != null ? "Cuisine preference: $cuisineHint\n" : ""}'
        'Return STRICT JSON only.';
    final response = await _chat(
      model: _textModel,
      json: true,
      temperature: 0.4,
      messages: [
        {'role': 'system', 'content': _mealSuggestionPrompt},
        {'role': 'user', 'content': prompt},
      ],
    );
    final text = _extract(response);
    final cleaned = _stripFences(text);
    final json = jsonDecode(cleaned) as Map<String, dynamic>;
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

  // --- Parsing helpers ---------------------------------------------------

  FoodAnalysis _parseFoodAnalysis(String raw) {
    final cleaned = _stripFences(raw);
    final Map<String, dynamic> json;
    try {
      json = jsonDecode(cleaned) as Map<String, dynamic>;
    } catch (_) {
      throw AiException('Could not parse AI response as JSON.');
    }
    final itemsJson = (json['items'] as List?) ?? const [];
    final items = itemsJson
        .whereType<Map>()
        .map((m) => _parseFoodItem(Map<String, dynamic>.from(m)))
        .toList();
    if (items.isEmpty) throw AiException('No foods recognized.');

    final totalsJson =
        (json['totals'] as Map?)?.cast<String, dynamic>() ?? {};
    return FoodAnalysis(
      items: items,
      totalCalories: _i(totalsJson['calories']) ??
          items.fold<int>(0, (s, e) => s + e.calories),
      totalProteinG: _i(totalsJson['protein_g']) ??
          items.fold<int>(0, (s, e) => s + e.proteinG),
      totalCarbsG: _i(totalsJson['carbs_g']) ??
          items.fold<int>(0, (s, e) => s + e.carbsG),
      totalFatG: _i(totalsJson['fat_g']) ??
          items.fold<int>(0, (s, e) => s + e.fatG),
      totalFiberG: _i(totalsJson['fiber_g']) ??
          items.fold<int>(0, (s, e) => s + e.fiberG),
      totalSodiumMg: _i(totalsJson['sodium_mg']) ??
          items.fold<int>(0, (s, e) => s + e.sodiumMg),
    );
  }

  FoodItemAnalysis _parseFoodItem(Map<String, dynamic> m) {
    final c = (m['confidence'] as String?)?.toLowerCase();
    final conf = c == 'high'
        ? EstimateConfidence.high
        : c == 'low'
            ? EstimateConfidence.low
            : EstimateConfidence.medium;
    int? low, high;
    final range = m['range'];
    if (range is Map) {
      low = _i(range['calories_low']);
      high = _i(range['calories_high']);
    }
    return FoodItemAnalysis(
      name: (m['name'] as String?)?.trim() ?? 'food',
      quantity: (m['quantity'] as String?)?.trim() ?? '',
      calories: _i(m['calories']) ?? _i(m['kcal']) ?? 0,
      proteinG: _i(m['protein_g']) ?? _i(m['protein']) ?? 0,
      carbsG: _i(m['carbs_g']) ?? _i(m['carbs']) ?? _i(m['carbohydrates_g']) ?? 0,
      fatG: _i(m['fat_g']) ?? _i(m['fat']) ?? _i(m['fats_g']) ?? _i(m['total_fat_g']) ?? 0,
      fiberG: _i(m['fiber_g']) ?? _i(m['fiber']) ?? _i(m['dietary_fiber_g']) ?? 0,
      sodiumMg: _i(m['sodium_mg']) ?? _i(m['sodium']) ?? 0,
      confidence: conf,
      caloriesLow: low,
      caloriesHigh: high,
    );
  }

  RoutinePlan _parseRoutine(String raw) {
    final cleaned = _stripFences(raw);
    final Map<String, dynamic> json;
    try {
      json = jsonDecode(cleaned) as Map<String, dynamic>;
    } catch (_) {
      throw AiException('Could not parse routine JSON.');
    }
    final name = (json['name'] as String?)?.trim() ?? 'My routine';
    final daysJson = (json['days'] as List?) ?? const [];
    final days = daysJson.whereType<Map>().map((d) {
      final m = Map<String, dynamic>.from(d);
      final exJson = (m['exercises'] as List?) ?? const [];
      final exercises = exJson.whereType<Map>().map((e) {
        final em = Map<String, dynamic>.from(e);
        return RoutinePlanExercise(
          name: (em['name'] as String?)?.trim() ?? 'Exercise',
          sets: _i(em['sets']) ?? 3,
          repsLow: _i(em['reps_low']) ?? 8,
          repsHigh: _i(em['reps_high']) ?? 12,
          notes: (em['notes'] as String?)?.trim(),
        );
      }).toList();
      return RoutinePlanDay(
        name: (m['name'] as String?)?.trim() ?? 'Day',
        weekday: _i(m['weekday']) ?? 0,
        isRest: (m['is_rest'] as bool?) ?? false,
        exercises: exercises,
      );
    }).toList();
    if (days.isEmpty) throw AiException('AI returned no training days.');
    return RoutinePlan(name: name, days: days);
  }

  int? _i(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.round();
    if (v is String) return int.tryParse(v) ?? double.tryParse(v)?.round();
    return null;
  }

  String _stripFences(String s) {
    var t = s.trim();
    if (t.startsWith('```')) {
      final firstNl = t.indexOf('\n');
      if (firstNl > 0) t = t.substring(firstNl + 1);
      if (t.endsWith('```')) t = t.substring(0, t.length - 3);
    }
    return t.trim();
  }
}

class _RetryableError implements Exception {
  final int status;
  final String body;
  _RetryableError(this.status, this.body);
  @override
  String toString() => 'Retryable($status): $body';
}
