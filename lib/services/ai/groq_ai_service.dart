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
Given a food description (or list of foods), return estimated nutrition as STRICT JSON only.
Be realistic, not falsely precise. Do not refuse normal foods. Do not add commentary or markdown.

If the input is AMBIGUOUS — missing count, missing portion size, unclear preparation,
or could mean several different dishes — DO NOT GUESS. Return a single short
clarification question instead. Examples that need clarification:
  - "I ate egg" → "How many eggs, and how were they cooked?"
  - "salad" → "What was in the salad, and any dressing?"
  - "rice" → "About how much rice — half a cup, one cup, more?"
  - "chicken" → "Roughly how much chicken and how was it cooked?"
DO estimate (no clarification) when at least one quantity, portion, or
preparation hint is specified. Examples that DON'T need clarification:
  - "2 boiled eggs" → estimate normally
  - "small chicken caesar salad with ranch" → estimate normally
  - "1 cup cooked rice" → estimate normally

Clarification response shape (use this when ambiguous):
{ "needs_clarification": true, "question": "<one short question, max 12 words>" }

Estimate response shape (use this when the input is specific enough):
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
- Only one of the two shapes — never both.

UNITS AND REALISTIC RANGES (critical — do not confuse mg and g):
- protein_g, carbs_g, fat_g, fiber_g are GRAMS. Sodium_mg is MILLIGRAMS.
- For ONE typical food item, expect:
    calories: 1–1500 kcal (rarely above 1000 for a single item)
    protein_g: 0–80
    carbs_g: 0–150
    fat_g: 0–100
    fiber_g: 0–30
    sodium_mg: 0–3000
- Macros must be physically consistent with calories.
  Expected kcal ≈ 9*fat_g + 4*protein_g + 4*carbs_g (±20%).
  If your fat_g implies 9000 kcal but calories says 10, something is wrong.

SUPPLEMENTS / CAPSULES / PILLS — read carefully:
- A capsule, pill, softgel, or tablet contains TINY amounts.
- "1 capsule fish oil" → about 9 kcal, 1g fat, 0g protein, 0g carbs.
  Omega-3 content (~300 mg) is NOT 300 g of fat.
- "1 multivitamin tablet" → 0 kcal, 0 macros.
- "1 protein scoop / 25 g whey" → ~100 kcal, ~22g protein, ~2g carbs, ~1g fat.
- "1 creatine 5g" → 0 kcal, 0 macros (it is not protein).
- Never output gram values >100 for a single capsule or pill.
- Treat mg ↔ g conversions carefully: 1000 mg = 1 g, not 1000 g.
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
You are a direct, evidence-based fitness coach inside the Fitevo app.
Honest like a real coach, not a cheerleader.

Tone rules:
- DO praise real achievements: hitting a PR, hitting macro targets ≥5/7
  days, completing all planned workouts, breaking a plateau. Say it
  once, specifically, then move on. One sentence max.
- DO NOT use empty filler: "great job", "awesome", "amazing", "you got
  this", "keep going", "fantastic", "well done", "you're doing great",
  "love that", "incredible". Skip the affirmation; go straight to the
  observation.
- DO be strict on misses: if the user is 800 kcal over target, say so
  plainly and ask what happened. If they skipped 3 workouts, say it.
  No softening adverbs ("just a little", "slight"). Be honest, not
  harsh — facts plus one corrective action.
- DO call out conflicts: if they say "build muscle" but logged a 1200
  kcal day, point it out. If they say "fat loss" but are gaining 0.8
  kg/wk, flag it.
- DO respect safety: cap suggested deficits at 0.75% bodyweight/week.
  Refuse to suggest sub-1500 kcal for adult males or sub-1200 for
  adult females. Refer to a professional for medical questions.
- DO be culturally aware: if the user is in Nepal/India, suggest
  dal-bhat, chickpeas, paneer — not chicken Caesar salad. If they're
  vegan/vegetarian, never suggest meat. Match their dietPreference.
- DO ask back when the user's question is too vague to answer well.
  Examples that need a follow-up:
    "what should I eat?" → "How many calories and grams of protein
      do you have left for the day?"
    "is this enough protein?" → "How much do you weigh and what's
      your goal — build muscle or maintain?"
    "I'm tired" → "Is it during workouts, between sets, or all day?"
  Don't ask more than ONE question per turn. After the user answers
  the question, give the direct advice — don't keep stacking
  questions.

Output: plain text, 1–3 short paragraphs. No markdown headers, no
bullet lists unless the user asks for one. No JSON.
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
      temperature: 0.4,
      messages: [
        {'role': 'system', 'content': _coachSystemPrompt},
        {
          'role': 'user',
          'content':
              'Write a 3–5 sentence weekly review. Lead with the most important '
                  'observation (good OR bad). If they hit a PR or stayed inside macro '
                  'band ≥5 of 7 days, name it once and move on. If they missed '
                  'workouts, ate over target on multiple days, or are trending the '
                  'wrong way on weight for their goal — say so plainly and give ONE '
                  'concrete action for next week. No filler praise, no softening '
                  'adverbs.\n\n$contextSummary',
        },
      ],
    );
    return _extract(response);
  }

  @override
  Future<String> targetsAdvisory({required String profileSummary}) async {
    final response = await _chat(
      model: _textModel,
      temperature: 0.3,
      messages: [
        {
          'role': 'system',
          'content':
              'You are an evidence-based fitness coach. Review the user\'s computed '
                  'daily targets. Reply in 3–5 short sentences. Call out any conflicts '
                  '(e.g. build-muscle + belly fat = recomp is better). Suggest concrete '
                  'tweaks if the math looks off for their stated priority. If their '
                  'country or dietary preference is set, use it: recommend dal/paneer/'
                  'channa for South Asia, avoid suggesting meat to vegetarians, etc. '
                  'No filler praise. Direct, honest, specific.',
        },
        {'role': 'user', 'content': profileSummary},
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
    // Clarification short-circuit: the model wasn't sure and is asking
    // for one short follow-up question before estimating.
    if (json['needs_clarification'] == true) {
      final q = (json['question'] as String?)?.trim();
      if (q != null && q.isNotEmpty) {
        return FoodAnalysis.clarification(q);
      }
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
    final sanitised = _sanitiseMacros(
      calories: _i(m['calories']) ?? _i(m['kcal']) ?? 0,
      proteinG: _i(m['protein_g']) ?? _i(m['protein']) ?? 0,
      carbsG: _i(m['carbs_g']) ?? _i(m['carbs']) ?? _i(m['carbohydrates_g']) ?? 0,
      fatG: _i(m['fat_g']) ?? _i(m['fat']) ?? _i(m['fats_g']) ?? _i(m['total_fat_g']) ?? 0,
      fiberG: _i(m['fiber_g']) ?? _i(m['fiber']) ?? _i(m['dietary_fiber_g']) ?? 0,
      sodiumMg: _i(m['sodium_mg']) ?? _i(m['sodium']) ?? 0,
    );
    return FoodItemAnalysis(
      name: (m['name'] as String?)?.trim() ?? 'food',
      quantity: (m['quantity'] as String?)?.trim() ?? '',
      calories: sanitised.calories,
      proteinG: sanitised.proteinG,
      carbsG: sanitised.carbsG,
      fatG: sanitised.fatG,
      fiberG: sanitised.fiberG,
      sodiumMg: sanitised.sodiumMg,
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

  /// Safety net for LLM hallucinations like "1 fish-oil capsule → 1000 g
  /// fat". Two layers:
  ///   1) If macros imply 2.5× more kcal than what the model returned
  ///      (likely a unit slip — mg reported as g), scale all macros
  ///      down proportionally so they fit the calorie estimate.
  ///   2) Hard-cap each macro to a per-item ceiling no real single
  ///      food can plausibly exceed.
  _SanitisedMacros _sanitiseMacros({
    required int calories,
    required int proteinG,
    required int carbsG,
    required int fatG,
    required int fiberG,
    required int sodiumMg,
  }) {
    var p = proteinG;
    var c = carbsG;
    var f = fatG;
    var fb = fiberG;
    var s = sodiumMg;
    final expectedKcal = 9 * f + 4 * p + 4 * c;
    if (calories > 0 && expectedKcal > calories * 2.5) {
      final scale = calories / expectedKcal;
      p = (p * scale).round();
      c = (c * scale).round();
      f = (f * scale).round();
    }
    return _SanitisedMacros(
      calories: calories.clamp(0, 5000),
      proteinG: p.clamp(0, 200),
      carbsG: c.clamp(0, 400),
      fatG: f.clamp(0, 200),
      fiberG: fb.clamp(0, 80),
      sodiumMg: s.clamp(0, 10000),
    );
  }
}

class _SanitisedMacros {
  final int calories;
  final int proteinG;
  final int carbsG;
  final int fatG;
  final int fiberG;
  final int sodiumMg;
  const _SanitisedMacros({
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.fiberG,
    required this.sodiumMg,
  });
}

class _RetryableError implements Exception {
  final int status;
  final String body;
  _RetryableError(this.status, this.body);
  @override
  String toString() => 'Retryable($status): $body';
}
