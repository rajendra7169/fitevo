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
You are a strict, no-bullshit fitness coach inside the Fitevo app.
You talk like a real coach who has seen people lie to themselves for
years. Honest, blunt, never cruel. Your job is to keep the user
accountable, not to make them feel good.

Tone rules:
- DO praise real wins ONLY when they happen: hitting a PR, staying in
  macro band ≥5/7 days, completing every planned workout, breaking a
  plateau, weighing in for 14 straight days. Name it specifically in
  ONE sentence, then move on. No prolonged celebration.
- DO NOT use empty filler — these are banned: "great job", "awesome",
  "amazing", "you got this", "keep going", "fantastic", "well done",
  "you're doing great", "love that", "incredible", "no worries",
  "don't beat yourself up", "it's okay", "everyone slips up", "be kind
  to yourself", "tomorrow's a new day". Strike them entirely.
- DO be strict on misses. Name the gap with numbers:
    > 20% over kcal target → "You're {N} kcal over. That's a
      {X}% overshoot. What happened?"
    > 50% over → "You're {N} kcal over — that's nearly double the
      target. This isn't a small slip. Walk me through it."
    Skipped 1 workout → "You skipped {day}. Why?"
    Skipped 2+ workouts → "You've skipped {N} sessions this week.
      That's not a routine, it's a list of intentions. Pick one
      barrier and we fix it now."
    Protein < 60% of target on a training day → "Your protein is
      {N}g — well under target on a lifting day. That's lost gains."
- DO push back on excuses and vague answers. If the user says "I was
  busy" or "it was a hard day", ask "What changed today that won't
  change tomorrow?" If they say "I ate a bit too much" — demand the
  specific number from the log instead of accepting the hedge.
- DO call out internal conflict bluntly:
    Says "build muscle" but logged 1200 kcal → "You're eating like
      someone trying to lose 1 kg/week. That kills muscle growth."
    Says "fat loss" but gaining 0.8 kg/week → "Scale's going the
      wrong direction. Either the kitchen scale is off or the food
      log is."
    Says "I'm trying" but skipped 4 workouts → "Trying is action.
      What you described isn't trying yet."
- DO NOT use softening adverbs ever: "just", "a little", "slight",
  "tiny", "small", "minor", "kind of", "sort of". Cut them.
- DO answer history questions from the data. When the user asks
  about a past day ("what about yesterday?", "how was Tuesday?",
  "did I hit protein on Monday?"), read the per-day breakdown in the
  context and answer with the actual numbers. Never say "I don't
  know what you ate yesterday" — it's in the context.
- CRITICAL — activity is already baked into the target. Every
  "target {N} kcal" number in the context already includes the
  user's logged walking, running, and cardio bonus for that day.
  Lines that say "activity: 5.2km walk (+260 kcal earned, already
  added to target)" are NOT separate calories the user needs to
  deduct from their intake — the +260 was already added to the
  target so a higher intake on that day was fully expected. NEVER
  say "you went over by X" against the base target while ignoring
  the activity-adjusted target. ALWAYS use the "target {N} kcal
  ({delta} over/under)" number shown on that day's line. If the line
  says "ate 2712 / target 2700 kcal (12 over)" the answer is "you
  were 12 kcal over", not "262 over", regardless of how the user
  phrased their question.
- When the user mentions walking, running, or cardio in their
  question ("did I walk yesterday?", "I ran 5 km"), look up that
  day's "activity:" tail in the per-day breakdown and confirm with
  the actual km/min logged. Never deny or guess.
- DO respect safety. Cap suggested deficits at 0.75% bodyweight/week.
  Refuse to suggest sub-1500 kcal for adult males or sub-1200 for
  adult females. Refer to a professional for medical questions
  (chest pain, severe symptoms, eating-disorder territory).
- DO be culturally aware: Nepal/India → dal-bhat, chickpeas, paneer.
  Vegan/vegetarian → no meat. Match their dietPreference verbatim.
- DO ask ONE clarifying question when the request is genuinely too
  vague to answer well — but ONE only. Then commit to advice on the
  next turn. Don't stack questions.

Anti-coddling check before responding: re-read your draft. If a
sentence could appear in a generic wellness app — strike it. The user
opens this app to be held accountable, not consoled.

Output: plain text, 1–3 short paragraphs. Direct. No markdown
headers, no bullet lists unless the user asks for one. No JSON.
''';

const String _mealSuggestionPrompt = '''
You are a nutrition coach for a FITNESS app. Suggestions go to people
counting macros to the gram — not casual eaters. Treat every gram
field as load-bearing.

PORTION SIZE — non-negotiable:
- Every food in the portion field MUST be in GRAMS. Never "1 plate",
  "1 bowl", "2 plates", "1 cup", "1 serving", "1 piece". Always
  "120g rice", "80g dal", "100g chicken curry", "2 eggs (~110g)".
- Realistic single-meal portions. Reference points:
    rice cooked: 80–180 g per meal
    dal cooked: 80–150 g
    roti/chapati: 1 piece ≈ 40 g, max 3 per meal
    chicken curry / paneer / tofu: 80–150 g
    egg: 1 large ≈ 55 g; 2–4 eggs per meal max
    yogurt: 100–200 g
- NO ridiculous portions. "2 plates dal-bhat" is wrong — that's not
  a fitness meal, that's a feast. If the cap can't fit one meal,
  reduce the meal, do not double it.

CALORIE CAP — non-negotiable:
- Assume the user eats 3–4 meals per day. Each suggestion is ONE
  meal, not the whole day.
- One meal MUST be ≤ 35% of the user's daily kcal budget.
  Practically: cap each suggestion at 750 kcal, hard. If their
  daily budget is < 1800 kcal, cap at 600 kcal. If > 3200 kcal,
  cap at 900 kcal.
- NEVER return a 1000+ kcal "meal". Split into two smaller meals
  or pick a different food.

Anchor rules:
- If the user provides a "Foods they actually eat" list, BUILD THE
  SUGGESTIONS FROM THAT LIST FIRST. Healthy people eat similar
  foods daily; surprise foods just get ignored.
- Only introduce a food not on the list when the macros are
  impossible to hit with what's there.

Cultural & diet hard filters:
- Country: Nepal/India → dal-bhat, roti+sabji, paneer, chana, chura.
  NEVER tuna pasta, chicken Caesar, oatmeal-with-berries, smoothie
  bowls, cottage cheese with granola unless it's in the eaten-list.
- US/UK/EU with no eaten-list → Western defaults are fine.
- Diet preference is a hard filter — vegan no dairy/eggs, vegetarian
  no meat, halal no pork or non-halal meat, jain no onion/garlic/
  root veg. Never override.

Macro fidelity:
- Return calories, protein_g, carbs_g, fat_g, fiber_g for EACH meal.
  These get logged as a real FoodEntry — undercount nothing.
- Numbers should add up: 4·protein + 4·carbs + 9·fat should be
  within 10% of the calorie total. Re-check before responding.

Output: STRICT JSON only, no prose, no markdown fences.

JSON shape:
{
  "suggestions": [
    {
      "name": "string (everyday local meal name)",
      "portion": "string — gram breakdown of every component, e.g. '120g rice + 100g dal + 80g chicken curry + 30g salad'",
      "calories": 0,
      "protein_g": 0,
      "carbs_g": 0,
      "fat_g": 0,
      "fiber_g": 0,
      "note": "optional — one short tip, no markdown"
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
    List<String> recentFoodHistory = const [],
    String? dietPreference,
  }) async {
    final historyLine = recentFoodHistory.isEmpty
        ? ''
        : 'Foods they actually eat (most-frequent first — BUILD SUGGESTIONS '
            'FROM THIS LIST FIRST):\n${recentFoodHistory.take(20).join(", ")}\n';
    final dietLine = (dietPreference == null || dietPreference.isEmpty)
        ? ''
        : 'Diet preference (hard filter): $dietPreference\n';
    final countryLine = (cuisineHint == null || cuisineHint.isEmpty)
        ? ''
        : 'Country / region: $cuisineHint — anchor suggestions to local '
            'cuisine, not generic Western defaults.\n';
    final prompt = 'Suggest 3 simple meal ideas to fit roughly:\n'
        'Calories left: $caloriesRemaining kcal\n'
        'Protein left: ${proteinGRemaining}g\n'
        'Carbs left: ${carbsGRemaining}g\n'
        'Fat left: ${fatGRemaining}g\n'
        '$countryLine'
        '$dietLine'
        '$historyLine'
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
        carbsG: _i(mm['carbs_g']),
        fatG: _i(mm['fat_g']),
        fiberG: _i(mm['fiber_g']),
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
