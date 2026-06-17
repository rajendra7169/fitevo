<div align="center">

<img src="assets/logo/logo.png" alt="Fitevo logo" width="140" />

# Fitevo

**A free, local-first fitness, nutrition, and workout tracking app for beginner gym-goers.**

Log a meal in one sentence. See everything in one glance.
Built with Flutter, Firebase, and Groq / Gemini AI.

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](#license)

</div>

---

## Why Fitevo

Most fitness trackers paywall the things that matter and bury you in friction. Fitevo flips that:

- **Logging takes one sentence.** Type *"2 rotis and a bowl of dal"* — AI parses it, estimates nutrition, updates your rings.
- **Everything visible in one glance.** Calories, macros, water, fiber, sodium — no scrolling, no tabs.
- **Adequacy model, not restriction.** Fill bars *toward* a target. No red "you went over", no shaming.
- **Honest estimates.** AI uncertainty is shown as a range, not fake precision.
- **Safety guardrails baked into the math.** Calorie floor + weight-change pacing cap enforced everywhere.
- **Local-first.** Your data lives on your phone in Isar. Cloud sync to Firestore is optional.
- **100% free, no credit card** for any service — Gemini, Groq, USDA, Firebase free tiers only.

---

## Features

### Nutrition
- AI natural-language food logging (one-sentence input → structured entry)
- AI photo logging from camera or gallery (multimodal Llama / Gemini)
- Adequacy rings + bars for calories, protein, carbs, fat, fiber, water, sodium
- "What should I eat?" — AI suggests meals that fit your *remaining* macros
- Custom foods / recipes with one-tap re-logging
- Favourites and tap-to-relog from recent meals
- Quick portion scaling (`0.5× / 1× / 1.5× / 2×`) on any logged item
- USDA FoodData Central cross-check for low-confidence AI estimates

### Workouts
- AI-generated starter routines from your goal and training-days-per-week
- Manual routine builder with exercise picker (library search + custom names)
- "What to train today" resolver based on weekday or longest-rested split
- Set logger with **live previous-session numbers** per set
- Rest timer with countdown + progress bar + haptic
- Auto **PR detection** (Epley 1-RM) with celebratory toast
- Personal records page sorted by recency
- Progressive overload hints per exercise
- Weekly muscle-group volume chips
- MET-based per-session calorie estimate
- Discard-workout safety menu
- Beginner-friendly exercise guides — form cues + common-mistake warnings

### Progress
- Body measurement entry (weight, body fat %, waist / chest / arm / thigh) + private on-device progress photos
- Weight line chart with 7-day rolling average and trend delta
- **Adaptive targets** — daily targets recompute from the rolling-average weight, capped by sane pacing limits
- 14-day calorie bar chart with target line
- Per-exercise strength progression chart (estimated 1-RM over time)
- Streak counter (food log or workout counts as a day)
- Six unlockable badges
- Progress photos in a private gallery, full-screen zoom

### Coach
- AI chat coach, beginner-aware, supportive, guardrail-respecting
- Weekly AI review summarising wins + 1–2 small adjustments
- Meal suggestion generator from remaining macros

### Reminders & Sync
- Water nudges on a 1 / 2 / 3 / 4-hour interval during waking hours
- Meal nudges at editable breakfast / lunch / dinner times
- Manual band sync screen for steps / heart rate / sleep (Huawei Health, Mi Fit, etc.)

### Privacy & Data
- Local-first storage in Isar — works fully offline
- Optional Firebase Auth (Google sign-in, email/password, or anonymous + later upgrade)
- Optional Firestore cloud backup
- **Progress photos and body measurements never sync** — they stay on device
- JSON export of all on-device data with one tap
- Full reset wipes the local DB cleanly

### Polish
- Dark + light mode with one-tap toggle
- Metric / imperial unit toggle
- Custom page transitions (fade + slide)
- Smooth bottom-nav pill that slides between tabs
- Staggered entry animations on the dashboard
- Calorie ring with `TweenAnimationBuilder` + radial glow + shader-mask gradient text

---

## Tech stack

| Layer | Choice |
|---|---|
| Framework | Flutter (Dart 3.x) |
| Local DB | Isar 3 |
| State | Riverpod 2 |
| Auth & cloud backup | Firebase Auth, Cloud Firestore |
| AI (food, coach, routine) | **Groq** (Llama 3.3 70B + Llama 4 Scout vision) — fallback to Gemini Flash |
| Verified nutrition cross-check | USDA FoodData Central |
| Charts | fl_chart |
| Notifications | flutter_local_notifications + timezone |
| Image picking | image_picker |
| Animations | flutter_animate + TweenAnimationBuilder + custom page transitions |
| Typography | Plus Jakarta Sans (via `google_fonts`) |
| Logo + splash | flutter_launcher_icons + flutter_native_splash |

---

## Architecture

```
lib/
├── core/                      # Health math, constants
├── data/
│   ├── models/                # Isar collections + embedded types
│   ├── repositories/          # Profile, nutrition, measurement, exercise, workout
│   ├── seed/                  # Bundled exercise library
│   └── db.dart                # Isar.open + schemas
├── services/
│   ├── ai/                    # AiService interface + Gemini / Groq / Proxy impls
│   ├── auth/                  # Google / email / anonymous + linking
│   ├── data/                  # JSON export
│   ├── notifications/         # flutter_local_notifications wrapper
│   ├── nutrition/             # USDA cross-check client
│   ├── progress/              # Adaptive targets, streak, badges
│   ├── settings/              # SharedPreferences-backed app settings
│   ├── sync/                  # Firestore mirror layer
│   └── workout/               # Routine generator, PR tracker, overload advisor, volume calc
├── features/
│   ├── account/               # Account + privacy view
│   ├── auth/                  # Login + signup + skip-as-anonymous
│   ├── coach/                 # Chat + weekly review
│   ├── food/                  # Meal actions sheet, suggestions, custom foods
│   ├── onboarding/            # 5-step profile + target compute
│   ├── progress/              # Charts, streak, badges, photos
│   ├── settings/              # Profile editor, reminders, units, health sync
│   └── workout/               # Routine builder, logger, PRs, exercise guide
├── home/                      # Dashboard + bottom-nav shell
├── state/                     # Riverpod providers
├── widgets/                   # Shared widgets (PressScale, etc.)
├── theme.dart                 # AppPalette, AppText, page-transition builder
├── firebase_options.dart      # Generated by `flutterfire configure`
└── main.dart                  # Init Firebase, Isar, AppSettings, notifications
```

### Key design rules

- **One `AiService` interface, three implementations** (Gemini, Groq, Proxy). The provider picks whichever is configured. Swapping providers is a one-line change.
- **Local-first repositories.** UI → Riverpod → repository → Isar. AI and USDA are *enrichment* sources, never blockers; the app works fully offline for everything except live AI calls.
- **Calorie floor + pacing cap** applied inside `HealthMath.compute` — every target ever shown to the user respects them.
- **Sync schema explicitly excludes progress photos and body measurements** so they never leave the device.

---

## Getting started

### 1. Prerequisites
- Flutter 3.x (`flutter doctor` should be green)
- A Firebase project (free tier) — for auth + cloud backup
- A Groq API key (free, no card) — for AI features

### 2. Clone

```bash
git clone https://github.com/<your-username>/fitevo.git
cd fitevo
flutter pub get
```

### 3. Configure Firebase

```bash
npm install -g firebase-tools
dart pub global activate flutterfire_cli
firebase login
flutterfire configure
```

Enable in the Firebase console:
- **Authentication** → Email/Password, Google, and Anonymous
- **Firestore Database** (in production mode)

Deploy the Firestore security rules:

```bash
firebase deploy --only firestore:rules
```

### 4. Add your API keys

Create `env.json` at the project root (this file is **gitignored**):

```json
{
  "GROQ_API_KEY": "gsk_...",
  "GEMINI_API_KEY": "...optional fallback...",
  "USDA_API_KEY": "...optional cross-check..."
}
```

Get keys for free:
- **Groq**: [console.groq.com](https://console.groq.com) → API Keys
- **Gemini**: [aistudio.google.com](https://aistudio.google.com) → Get API key
- **USDA**: [fdc.nal.usda.gov/api-key-signup](https://fdc.nal.usda.gov/api-key-signup)

### 5. Run

```bash
flutter run --dart-define-from-file=env.json
```

Or use **VS Code F5** — `.vscode/launch.json` (also gitignored) is preconfigured to pass `env.json`.

---

## Build phases

- **Phase 1** — Core: onboarding, dashboard, AI text logging, local DB, basic workout logger ✅
- **Phase 2** — Expand: photo logging, routine builder, PRs, weekly volume, progress charts, reminders, custom foods, manual band sync, weekly review ✅
- **Phase 3** — Hardening: proxy AI service (skeleton ready), web build with platform fallbacks, full UI polish pass ✅ *(in progress)*

---

## License

[MIT](LICENSE) — do whatever you want, attribution appreciated.

---

<div align="center">

Built solo over coffee. Issues and PRs welcome.

</div>
