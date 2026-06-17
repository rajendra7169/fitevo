# FitTrack — Full App Specification & Build Brief

> **How to use this file:** This is the master spec for an AI coding assistant (GitHub Copilot, Cursor, Claude Code, etc.) in VS Code. Keep it at the project root (e.g. `SPEC.md` or `CLAUDE.md`). Point the assistant at it and build phase by phase. Every feature, constraint, and design rule discussed is captured here — treat it as the source of truth.

---

## 0. Project summary

A personal fitness, nutrition, and workout tracking app for a beginner gym-goer.

- **Platform:** Flutter (Dart). **Mobile-first** (Android + iOS). **Web build planned for later** — architecture must not block it.
- **Hard constraint:** 100% free. **No credit card** for any API, service, or integration. Every dependency below has a genuine no-card free tier.
- **Single-user, local-first.** No mandatory accounts. Data lives on-device.
- **Design north star:** *Log in one sentence, see everything in one glance, big readable numbers.* The #1 reason people quit tracking apps is logging friction — kill it.

---

## 1. Core design principles (apply everywhere)

1. **Low-friction logging.** Logging a meal should take one sentence of natural language, or one tap to repeat a previous meal. Never make the user search a database item-by-item.
2. **One-glance dashboard.** Calories, protein, carbs, fat, water, and key extras all visible on the home screen without scrolling or tapping. Big, readable numbers.
3. **Adequacy model ("fill the bar, then stop nagging").** Each nutrient is a target you fill toward. Once a target is met, its bar reads *done*, greys out, and drops out of the "what's left today" list. The app emphasizes what you still need, not what you've "used up." Framing is about *getting enough*, never about restriction or guilt.
4. **No shaming.** Never use red "you went over / bad" framing. Going over a target is shown neutrally. No judgmental colors, no guilt copy.
5. **Honest estimates.** AI nutrition numbers are estimates (~±10–15%, similar to any food database). When the AI is unsure, show a range, not fake precision. Surface a quiet "estimates may vary" note rather than implying lab accuracy.
6. **Healthy-by-default guardrails (build these into the math):**
   - Enforce a **calorie floor** — the app never sets or recommends a daily target below a safe minimum (commonly ~1200 for women / ~1500 for men as conservative floors; make these constants, configurable).
   - Cap **weight-change pacing** at a sane rate (e.g. ≤ ~0.75–1% bodyweight/week) so goals never push aggressive deficits.
   - Treat protein, fiber, water as *minimums to reach*; treat calories as a target band, not a hard limit.
7. **Everything is editable.** Every auto-calculated target can be overridden in Settings.

---

## 2. Tech stack (all free, no credit card)

| Need | Package / Service | Notes |
|---|---|---|
| Framework | **Flutter / Dart** | Mobile-first; web later |
| AI (food logging, coach, photo analysis) | **Gemini API** via `google_generative_ai` | Google AI Studio key — **no credit card, no expiration**. Use a **Flash** model (e.g. Gemini Flash) for speed + free quota (~1,500 req/day, 15 req/min). Multimodal → powers photo logging too. |
| Verified nutrition cross-check | **USDA FoodData Central API** | Free API key, no card. Used to validate / refine AI estimates for common foods. |
| Local storage | **Isar** (preferred) or **Drift** (SQLite) | On-device, offline-first |
| Charts | **fl_chart** | All progress/analytics charts |
| Reminders + snooze | **flutter_local_notifications** | Scheduled local notifications, works when app is closed. **Mobile only** (no web). |
| Animations | **rive** and/or **lottie** | Engaging dashboard, ring/bar fills |
| Health data (Android) | **health** package → Health Connect | Best-effort band data; see §9 |
| (Later) AI key proxy | **Cloudflare Workers** or **Supabase Edge Functions** | Both have no-card free tiers; see §3 |

### Free-tier caveats to handle in code
- **Gemini 429s:** free quota is rate-limited and region/model-specific. Implement **retry-with-exponential-backoff** on all AI calls. Show a graceful "try again in a moment" state.
- **Privacy:** Gemini free-tier requests may be used by Google to improve their products. Only send food descriptions / images through it — never anything you'd consider private.

---

## 3. Architecture decisions (do these from day one)

1. **AISer­vice abstraction.** All Gemini calls go through a single `AiService` interface (e.g. `analyzeFoodText`, `analyzeFoodPhoto`, `coachChat`, `weeklyReview`, `generateRoutine`). Today it calls Gemini directly with the key in the app. Later, swap the implementation to call a **proxy** (Cloudflare Worker / Supabase Edge Function) that holds the key server-side — a one-file change. (Embedding the key client-side is fine for personal use, but it's exposed; the proxy is required before sharing the app or going web.)
2. **Platform abstraction for web degradation.** Wrap platform-specific capabilities behind interfaces with mobile + web implementations:
   - `NotificationService` — real on mobile, no-op/banner on web.
   - `HealthSyncService` — Health Connect on Android, manual-entry on web/iOS.
   This way the web build degrades gracefully instead of failing to compile.
3. **Local-first repositories.** UI → Repository → local DB (Isar/Drift). AI and USDA are *enrichment* sources, never blockers; the app must fully work offline for everything except live AI calls.
4. **State management:** Riverpod (or Bloc) — pick one and keep it consistent.
5. **Folder layout:**
```
lib/
  core/            # theme, constants (calorie floors, etc.), utils, result types
  data/
    models/        # Profile, DailyLog, FoodEntry, Exercise, WorkoutSession, ...
    db/            # Isar/Drift setup + DAOs
    repositories/  # ProfileRepo, NutritionRepo, WorkoutRepo, ProgressRepo
  services/
    ai/            # AiService interface + GeminiAiService (+ later ProxyAiService)
    nutrition/     # UsdaService
    notifications/ # NotificationService (mobile/web impls)
    health/        # HealthSyncService (android/other impls)
  features/
    onboarding/    # profile setup + target calculation
    dashboard/     # home: rings/bars, "remaining today"
    food/          # AI logging, history, custom foods, "what should I eat?"
    workout/       # routine, logger, exercise guides, rest timer
    progress/      # charts, measurements, photos, streaks
    coach/         # AI chat + weekly review
    settings/      # edit targets, reminders, units, profile
  app.dart
  main.dart
```

---

## 4. Data models (minimum fields)

> Each nutrient is stored as `{ target, consumed }`; the UI computes `remaining = max(0, target - consumed)`. When `remaining == 0`, mark the bar **done** and drop it from "what's left today."

**Profile**
- age, gender, heightCm, weightKg, activityLevel (sedentary→very active), goal (build muscle / lose fat / recomp / general fitness), trainingDaysPerWeek
- derived & cached: bmr, tdee, calorieTarget, proteinTarget, carbTarget, fatTarget, fiberTarget, waterTargetMl, bmi
- `overrides` map so any target can be manually set

**DailyLog** (one per day)
- date
- totals: calories, protein, carbs, fat, fiber, water, plus micros (sodium, key vitamins/minerals)
- list of FoodEntry ids; list of completed reminders; steps/HR/sleep (from sync)

**FoodEntry**
- timestamp, rawInput (the sentence the user typed), description, quantity, unit
- calories, protein, carbs, fat, fiber, + micros
- source enum: `aiText | aiPhoto | usdaVerified | custom | favorite`
- `estimateConfidence` + optional `range` (low/high) for uncertain AI results
- `isFavorite`, `photoPath?`

**CustomFood / Recipe** (great for home-cooked & local dishes the database misses)
- name, servingSize, per-serving nutrition, optional ingredient list

**Exercise** (library entry)
- name, targetMuscleGroup(s), equipment/machine, isBeginnerFriendly
- formGuide: ordered steps, cues, **common-mistake warnings**, illustration asset (SVG)

**WorkoutSession**
- date, routineDay, list of SetEntry(exerciseId, weight, reps, rpe?)
- computed: totalVolume, perMuscleVolume, caloriesBurnedEstimate, newPRs[]

**Routine / Split**
- name, days[] → each day = list of exercises (+ target sets/reps)
- "what to train today" resolves from current weekday

**BodyMeasurement**
- date, weightKg, bodyFat?%, circumferences (waist/chest/arm/etc.), optional progress photo path (private, on-device only)

**Reminder**
- type (water / meal), scheduledTime, intervalMinutes, snoozeMinutes, enabled

---

## 5. Health calculations (the math)

- **BMR:** Mifflin-St Jeor.
  - Men: `10*kg + 6.25*cm − 5*age + 5`
  - Women: `10*kg + 6.25*cm − 5*age − 161`
- **TDEE:** BMR × activity factor (sedentary 1.2 → very active 1.9).
- **Calorie target from goal:** apply a modest surplus/deficit to TDEE based on goal, **clamped by the calorie floor and the weight-change pacing cap** (§1.6). Lose fat = moderate deficit; build muscle = modest surplus; recomp = ~maintenance; general = maintenance.
- **Protein target:** ~1.6–2.2 g/kg bodyweight (higher end for muscle building / fat loss to preserve muscle).
- **Fat target:** ~0.8–1.0 g/kg (floor for hormones), remainder of calories → carbs.
- **Carb target:** fills remaining calories after protein + fat.
- **Fiber target:** ~14 g per 1000 kcal.
- **Water target:** baseline by bodyweight (~30–35 ml/kg), nudged up on workout days.
- **BMI:** `kg / (m^2)`, shown **with context** (it's a rough population metric, not a judgment) — never as pass/fail.
- **Adaptive targets:** recompute periodically from logged bodyweight trend (rolling average, not single weigh-ins) so targets evolve as weight changes. This is the "set it and it keeps up with you" behavior.

---

## 6. Feature list (build every item; behavior noted)

### 6.1 Nutrition & food logging
- **AI natural-language logging** — user types e.g. "2 rotis and a bowl of dal" → `AiService.analyzeFoodText` returns structured nutrition JSON (§8) → creates FoodEntry, updates DailyLog totals and bars instantly.
- **Adequacy rings/bars** — animated fill per nutrient; done state greys out and leaves the "remaining" list.
- **One-glance dashboard** — all key nutrients + water on home, no scrolling, big numbers.
- **"Remaining today" view** — what's still needed, sorted by how far from target; done items hidden.
- **Micronutrients** — fiber, sodium, key vitamins/minerals tracked and shown (kept free; commonly paywalled elsewhere).
- **Recent / favorite / "log again"** — one tap to repeat a prior meal.
- **AI photo logging** — snap a plate → `analyzeFoodPhoto` (Gemini multimodal) → estimate with confidence/range.
- **Quick portion edit** — adjust servings ("make it 1.5×") and totals recompute.
- **"What should I eat?"** — `AiService` suggests foods that fit the *remaining* macros for the day.
- **Custom foods & saved recipes** — for home-cooked / local dishes.
- **Meal scheduling + reminders** — scheduled meal nudges (mobile notifications).

### 6.2 Workouts
- **Routine builder / weekly split** + **"what to train today."**
- **Set/rep/weight logger** with full history.
- **Previous-session numbers shown live** during the current set (the single most effective progressive-overload aid).
- **Exercise / machine guides** — per exercise: SVG form illustration, step cues, **common-mistake warnings**, beginner-safety notes ("don't ego lift," start light).
- **Progressive overload hints** — e.g. "last week 3×10 @ 30 kg → try 32.5 kg," derived from history.
- **Auto PR detection** + personal-records page.
- **Rest timer** between sets.
- **Weekly volume per muscle group** — surface under-trained muscles.
- **Calories-burned estimate** per session (MET-based estimate; clearly an estimate).

### 6.3 Progress & analytics
- **Weight + body-measurement trends** with charts (use rolling average for weight).
- **Daily / weekly / monthly nutrition records** + charts.
- **Progress photos** — private, stored on-device only, never uploaded.
- **Strength progression charts** — estimated 1RM, volume over time.
- **Streaks + achievement badges** — reward consistency, not perfection; missing a day doesn't punish.
- **AI weekly review** — `weeklyReview` produces a short written summary + 1–2 specific, encouraging adjustments.

### 6.4 AI coach & smart features
- **AI coach chat** — free-form Q&A ("why am I not seeing progress?", "swap my leg-day exercise"). Coach is supportive, beginner-aware, and never promotes extreme restriction or aggressive deficits — it respects the §1.6 guardrails.
- **Beginner mode** — safety-first cues, realistic timeline expectations, form-over-weight emphasis.
- **AI-generated starter routine** — from goal + training days, produce a sensible split.

### 6.5 Reminders, sync, design
- **Water & meal reminders with snooze** — snoozing reschedules a later reminder (store `snoozeMinutes`, re-arm the notification). Mobile only.
- **Manual band sync screen** — see §9.
- **Engaging animated home** — Rive/Lottie ring & bar fills, smooth transitions. (True 3D is heavy on mobile — fake the premium feel with animation; save real 3D for the web build if still wanted.)

---

## 7. Screen-by-screen

1. **Onboarding** — collect age, gender, height, weight, activity level, goal, training days → compute & show targets (with the calorie floor / pacing guardrails applied) → let user tweak.
2. **Dashboard (Home)** — adequacy rings/bars for calories + macros + water, "remaining today" list, quick "log food" entry, today's workout summary, streak. Animated, premium feel.
3. **Food** — natural-language log box, camera/photo log, today's entries, recent/favorites, custom foods/recipes, "what should I eat?" button, daily/weekly/monthly history.
4. **Workout** — today's plan, logger with live previous numbers + rest timer, exercise guide viewer (SVG + cues + mistakes), routine builder, PRs, weekly muscle-group volume.
5. **Progress** — weight & measurement charts, strength charts, nutrition trend charts, progress photos, streaks/badges.
6. **Coach** — AI chat + weekly review card.
7. **Settings** — edit any target, manage reminders (intervals, snooze), units (metric/imperial), profile, data export, reset.

---

## 8. Gemini food-logging prompt (structured JSON contract)

`AiService.analyzeFoodText(input)` and `analyzeFoodPhoto(image)` must return **strict JSON only** (no prose, no markdown fences). Parse defensively; on failure, retry once then show a manual-entry fallback.

**System instruction (summary to encode):**
- You are a nutrition estimation assistant. Given a food description (or image) and quantity, return estimated nutrition as JSON.
- Estimate per the described quantity. If unsure, give a best estimate **and** a low/high range.
- Be realistic, not falsely precise. Do not refuse normal foods. Do not add commentary.

**Required JSON shape:**
```json
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
  "totals": { "calories": 0, "protein_g": 0, "carbs_g": 0, "fat_g": 0, "fiber_g": 0, "sodium_mg": 0 }
}
```
- After parsing, optionally cross-check common single foods against **USDA FoodData Central** and prefer the verified value when confidence is `low`.
- Map `confidence: "low"` → show the range in the UI.

---

## 9. Huawei Band integration (set expectations honestly)

- **No direct sync.** Huawei Health Kit needs an approved developer account, and a Flutter app can't talk to the band over Huawei's proprietary Bluetooth protocol.
- **Android best-effort:** if the Huawei Health app writes to **Health Connect**, the `health` package can read steps / heart rate / sleep / calories from there. Attempt this path on Android; if no data is available, fall back to manual.
- **Manual sync screen (always available):** a ~20-second screen where the user copies steps / HR / calories / sleep from the Huawei Health app; the app stores them in the DailyLog and uses them in burn estimates and trends.
- **iOS / web:** manual entry only.

---

## 10. Build phases

**Phase 1 — Core v1 (build first):**
- Onboarding + target calculation (with guardrails)
- One-glance dashboard with adequacy rings/bars + "remaining today"
- AI natural-language food logging → updates totals
- Local storage (Isar/Drift) wired through repositories
- Basic workout logger with live previous numbers + a few exercise guides
- Basic progress charts (weight + calories/macros over time)
- AI coach chat
- Settings (edit targets, units)

**Phase 2 — Expand:**
- AI photo logging, "what should I eat?", custom foods/recipes
- Routine builder, rest timer, PR detection, weekly muscle-group volume, full exercise-guide library
- Body measurements, progress photos, strength charts, streaks/badges
- AI weekly review
- Water/meal reminders + snooze (mobile)
- Manual band sync + Health Connect read (Android)

**Phase 3 — Web + hardening:**
- Move AI key behind a Cloudflare Worker / Supabase Edge Function proxy
- Flutter web build with platform fallbacks (notifications/band become no-ops)
- Optional real 3D on web home
- Adaptive targets from weight trend; polish animations

---

## 11. Non-negotiable constraints (repeat to the assistant)

- **Free / no credit card** for every service. If a step would require payment, stop and flag it instead.
- **Offline-first**; AI/USDA are enrichment, never blockers.
- **Mobile-first, web-later**; keep platform-specific code behind interfaces.
- **Calorie floor + sane pacing always enforced** in target math.
- **No shaming UI, neutral over-target framing, estimates shown as ranges when uncertain.**
- **Progress photos and personal data never leave the device** (until/unless the user explicitly opts into a backup feature you build later).
