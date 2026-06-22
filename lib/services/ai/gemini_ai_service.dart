import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:google_generative_ai/google_generative_ai.dart';

import '../../data/models/enums.dart';
import 'ai_service.dart';

const String _coachSystemInstruction = '''
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

Output: plain text, 1–3 short paragraphs. No markdown headers, no
bullet lists unless the user asks for one. No JSON.
''';

const String _mealSuggestionInstruction = '''
You are a nutrition coach helping the user fit their remaining macros for the day.

Rules:
- Suggest 3 meal ideas that approximately fit the macros provided.
- Prefer everyday, easy-to-prepare foods.
- Realistic estimates, not falsely precise.
- Return STRICT JSON only — no prose, no markdown.

JSON shape:
{
  "suggestions": [
    {
      "name": "string",
      "portion": "string (e.g. 1 bowl, 2 wraps)",
      "calories": 0,
      "protein_g": 0,
      "note": "optional short note"
    }
  ]
}
''';

const String _routineSystemInstruction = '''
You are a beginner-friendly personal trainer.
Build a safe, sensible workout split given a goal and the number of training days per week.

Rules:
- Pick 4-7 exercises per training day.
- Use standard, widely-known exercise names. Prefer the provided library names.
- Mix compound and isolation movements appropriately.
- Spread training across the week with rest days where appropriate.
- weekday: 1=Mon, 2=Tue, 3=Wed, 4=Thu, 5=Fri, 6=Sat, 7=Sun.
- Mark rest days with "is_rest": true and an empty "exercises" list.
- Sensible rep ranges: 5-8 strength, 8-12 hypertrophy, 12-20 endurance.
- Output STRICT JSON only — no prose, no markdown fences.

Required JSON shape:
{
  "name": "string (short routine name)",
  "days": [
    {
      "name": "string (e.g. Push Day, Pull, Legs, Rest)",
      "weekday": 1,
      "is_rest": false,
      "exercises": [
        {
          "name": "string",
          "sets": 3,
          "reps_low": 8,
          "reps_high": 12,
          "notes": "optional short cue"
        }
      ]
    }
  ]
}
''';

const String _systemInstruction = '''
You are a nutrition estimation assistant.
Given a food description (or list of foods) and quantity, return estimated nutrition as STRICT JSON only.
Estimate per the described quantity. If unsure, give a best estimate AND a low/high calorie range.
Be realistic, not falsely precise. Do not refuse normal foods. Do not add commentary or markdown.

Required JSON shape:
{
  "items": [
    {
      "name": "string",
      "quantity": "string (as understood)",
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
    "calories": 0,
    "protein_g": 0,
    "carbs_g": 0,
    "fat_g": 0,
    "fiber_g": 0,
    "sodium_mg": 0
  }
}

Rules:
- All numeric fields are integers (round to nearest whole number).
- If confidence is "high" or "medium", "range" may be omitted or set to the same low/high.
- Totals MUST equal the sum of items.
- Output JSON only. No prose, no markdown fences, no comments.
''';

class GeminiAiService implements AiService {
  GeminiAiService({required String apiKey, String? modelName})
      : _apiKey = apiKey,
        _modelName = modelName ?? 'gemini-2.5-flash';

  final String _apiKey;
  final String _modelName;

  GenerativeModel? _model;

  GenerativeModel _ensureModel() {
    if (_apiKey.isEmpty) throw AiNotConfiguredException();
    return _model ??= GenerativeModel(
      model: _modelName,
      apiKey: _apiKey,
      systemInstruction: Content.system(_systemInstruction),
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        temperature: 0.2,
      ),
    );
  }

  GenerativeModel _ensureRoutineModel() {
    if (_apiKey.isEmpty) throw AiNotConfiguredException();
    return GenerativeModel(
      model: _modelName,
      apiKey: _apiKey,
      systemInstruction: Content.system(_routineSystemInstruction),
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        temperature: 0.3,
      ),
    );
  }

  GenerativeModel _ensureCoachModel() {
    if (_apiKey.isEmpty) throw AiNotConfiguredException();
    return GenerativeModel(
      model: _modelName,
      apiKey: _apiKey,
      systemInstruction: Content.system(_coachSystemInstruction),
      generationConfig: GenerationConfig(
        temperature: 0.6,
      ),
    );
  }

  GenerativeModel _ensureMealSuggestionModel() {
    if (_apiKey.isEmpty) throw AiNotConfiguredException();
    return GenerativeModel(
      model: _modelName,
      apiKey: _apiKey,
      systemInstruction: Content.system(_mealSuggestionInstruction),
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        temperature: 0.4,
      ),
    );
  }

  @override
  Future<String> coachChat({
    required String userContext,
    required List<CoachMessage> history,
    required String latestUserMessage,
  }) async {
    final model = _ensureCoachModel();
    final parts = <Content>[
      Content.text('User profile and recent context:\n$userContext'),
    ];
    for (final m in history) {
      parts.add(m.fromUser
          ? Content.text(m.text)
          : Content.model([TextPart(m.text)]));
    }
    parts.add(Content.text(latestUserMessage));
    try {
      final res = await model.generateContent(parts);
      final text = res.text;
      if (text == null || text.trim().isEmpty) {
        throw AiException('Coach is quiet right now.');
      }
      return text.trim();
    } on AiException {
      rethrow;
    } catch (e) {
      throw AiException('Coach request failed: $e');
    }
  }

  @override
  Future<String> weeklyReview({required String contextSummary}) async {
    final model = _ensureCoachModel();
    final prompt =
        'Write a 3–5 sentence weekly review. Lead with the most important '
        'observation (good OR bad). If they hit a PR or stayed inside macro '
        'band ≥5 of 7 days, name it once and move on. If they missed workouts, '
        'ate over target on multiple days, or are trending the wrong way on '
        'weight for their goal — say so plainly and give ONE concrete action '
        'for next week. No filler praise, no softening adverbs.\n\n'
        '$contextSummary';
    try {
      final res = await model.generateContent([Content.text(prompt)]);
      final text = res.text;
      if (text == null || text.trim().isEmpty) {
        throw AiException('Empty review.');
      }
      return text.trim();
    } catch (e) {
      throw AiException('Weekly review failed: $e');
    }
  }

  @override
  Future<String> targetsAdvisory({required String profileSummary}) async {
    final model = _ensureCoachModel();
    final prompt =
        'You are an evidence-based fitness coach. Review the user\'s computed '
        'daily targets. Reply in 3–5 short sentences. Call out any conflicts '
        '(e.g. build-muscle + belly fat = recomp is better). Suggest concrete '
        'tweaks if the math looks off for their stated priority. If their '
        'country or dietary preference is set, use it: dal/paneer/channa for '
        'South Asia, never meat to vegetarians, etc. No filler praise. Direct, '
        'honest, specific.\n\n'
        '$profileSummary';
    try {
      final res = await model.generateContent([Content.text(prompt)]);
      final text = res.text;
      if (text == null || text.trim().isEmpty) {
        throw AiException('Empty advisory.');
      }
      return text.trim();
    } catch (e) {
      throw AiException('Targets advisory failed: $e');
    }
  }

  @override
  Future<List<MealSuggestion>> suggestMeals({
    required int caloriesRemaining,
    required int proteinGRemaining,
    required int carbsGRemaining,
    required int fatGRemaining,
    String? cuisineHint,
  }) async {
    final model = _ensureMealSuggestionModel();
    final prompt =
        'Suggest 3 simple meal ideas to fit roughly:\n'
        'Calories left: $caloriesRemaining kcal\n'
        'Protein left: ${proteinGRemaining}g\n'
        'Carbs left: ${carbsGRemaining}g\n'
        'Fat left: ${fatGRemaining}g\n'
        '${cuisineHint != null ? "Cuisine preference: $cuisineHint\n" : ""}'
        'Return STRICT JSON only.';
    try {
      final res = await model.generateContent([Content.text(prompt)]);
      final text = res.text;
      if (text == null || text.trim().isEmpty) {
        throw AiException('No suggestions.');
      }
      final cleaned = _stripFences(text.trim());
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
    } catch (e) {
      throw AiException('Meal suggestions failed: $e');
    }
  }

  @override
  Future<RoutinePlan> generateStarterRoutine({
    required FitnessGoal goal,
    required int trainingDaysPerWeek,
    required List<String> libraryExerciseNames,
  }) async {
    final model = _ensureRoutineModel();
    final goalLabel = switch (goal) {
      FitnessGoal.buildMuscle => 'build muscle (modest surplus)',
      FitnessGoal.loseFat => 'lose fat while preserving muscle',
      FitnessGoal.recomp => 'body recomposition (slow change)',
      FitnessGoal.generalFitness => 'general fitness and strength',
    };
    final prompt =
        'Build a beginner-friendly $trainingDaysPerWeek-day-per-week routine for someone whose goal is $goalLabel.\n'
        'Prefer exercises from this library when they fit:\n${libraryExerciseNames.join(', ')}.\n'
        'For exercises not in the library, use widely-known names.\n'
        'Spread training across the week sensibly with rest days. Return JSON only.';
    const maxAttempts = 3;
    Object? lastError;
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      try {
        final res = await model.generateContent([Content.text(prompt)]);
        final text = res.text;
        if (text == null || text.trim().isEmpty) {
          throw AiException('Empty response from AI.');
        }
        return _parseRoutine(text);
      } on AiException {
        rethrow;
      } catch (e) {
        lastError = e;
        if (attempt == maxAttempts - 1) break;
        await Future.delayed(Duration(milliseconds: 400 * (attempt + 1)));
      }
    }
    throw AiException('Routine generation failed: $lastError');
  }

  RoutinePlan _parseRoutine(String raw) {
    final cleaned = _stripFences(raw.trim());
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

  @override
  Future<FoodAnalysis> analyzeFoodText(String input) async {
    final trimmed = input.trim();
    if (trimmed.isEmpty) throw AiException('Empty input.');
    return _generateWithRetry([Content.text(trimmed)]);
  }

  @override
  Future<FoodAnalysis> analyzeFoodPhoto(List<int> imageBytes,
      {String? hint}) async {
    if (imageBytes.isEmpty) throw AiException('Empty photo.');
    final parts = <Part>[
      DataPart('image/jpeg', Uint8List.fromList(imageBytes)),
      TextPart(
          'Identify each food in this photo and estimate nutrition per visible portion. ${hint ?? ''}'
              .trim()),
    ];
    return _generateWithRetry([Content.multi(parts)]);
  }

  Future<FoodAnalysis> _generateWithRetry(List<Content> content) async {
    final model = _ensureModel();
    const maxAttempts = 3;
    Object? lastError;
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      try {
        final res = await model.generateContent(content);
        final text = res.text;
        if (text == null || text.trim().isEmpty) {
          throw AiException('Empty response from AI.');
        }
        return _parse(text);
      } on AiException {
        rethrow;
      } catch (e) {
        lastError = e;
        final msg = e.toString();
        final isQuota =
            msg.contains('429') || msg.toLowerCase().contains('quota');
        if (attempt == maxAttempts - 1) break;
        final backoffMs = isQuota
            ? (1200 * pow(2, attempt)).toInt()
            : (400 * pow(2, attempt)).toInt();
        await Future.delayed(Duration(milliseconds: backoffMs));
      }
    }
    throw AiException('AI request failed: $lastError');
  }

  FoodAnalysis _parse(String raw) {
    final cleaned = _stripFences(raw.trim());
    final Map<String, dynamic> json;
    try {
      json = jsonDecode(cleaned) as Map<String, dynamic>;
    } catch (e) {
      throw AiException('Could not parse AI response as JSON.');
    }

    final itemsJson = (json['items'] as List?) ?? const [];
    final items = itemsJson
        .whereType<Map>()
        .map((m) => _parseItem(Map<String, dynamic>.from(m)))
        .toList();

    if (items.isEmpty) {
      throw AiException('No foods recognized.');
    }

    final totalsJson = (json['totals'] as Map?)?.cast<String, dynamic>() ?? {};
    final tCal = _i(totalsJson['calories']) ??
        items.fold<int>(0, (s, e) => s + e.calories);
    final tP = _i(totalsJson['protein_g']) ??
        items.fold<int>(0, (s, e) => s + e.proteinG);
    final tC = _i(totalsJson['carbs_g']) ??
        items.fold<int>(0, (s, e) => s + e.carbsG);
    final tF = _i(totalsJson['fat_g']) ??
        items.fold<int>(0, (s, e) => s + e.fatG);
    final tFb = _i(totalsJson['fiber_g']) ??
        items.fold<int>(0, (s, e) => s + e.fiberG);
    final tS = _i(totalsJson['sodium_mg']) ??
        items.fold<int>(0, (s, e) => s + e.sodiumMg);

    return FoodAnalysis(
      items: items,
      totalCalories: tCal,
      totalProteinG: tP,
      totalCarbsG: tC,
      totalFatG: tF,
      totalFiberG: tFb,
      totalSodiumMg: tS,
    );
  }

  FoodItemAnalysis _parseItem(Map<String, dynamic> m) {
    EstimateConfidence conf = EstimateConfidence.medium;
    final c = (m['confidence'] as String?)?.toLowerCase();
    if (c == 'high') conf = EstimateConfidence.high;
    if (c == 'low') conf = EstimateConfidence.low;

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

  int? _i(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.round();
    if (v is String) return int.tryParse(v) ?? double.tryParse(v)?.round();
    return null;
  }

  String _stripFences(String s) {
    var t = s;
    if (t.startsWith('```')) {
      final firstNl = t.indexOf('\n');
      if (firstNl > 0) t = t.substring(firstNl + 1);
      if (t.endsWith('```')) t = t.substring(0, t.length - 3);
    }
    return t.trim();
  }
}
