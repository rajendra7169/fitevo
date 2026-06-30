import 'package:isar/isar.dart';
import 'enums.dart';

part 'profile.g.dart';

@collection
class Profile {
  Id id = 0;

  String displayName = '';

  late int age;

  @Enumerated(EnumType.name)
  late Gender gender;

  late double heightCm;
  late double weightKg;

  @Enumerated(EnumType.name)
  late ActivityLevel activityLevel;

  @Enumerated(EnumType.name)
  late FitnessGoal goal;

  late int trainingDaysPerWeek;

  // Cardio sessions per week (running / cycling / HIIT etc.), separate
  // from strength training days. Used to lift TDEE more accurately.
  int cardioSessionsPerWeek = 0;

  // More precise activity inputs — used for km-based calorie math when
  // > 0, otherwise we fall back to session counts above.
  double walkingKmPerDay = 0;
  double runningKmPerWeek = 0;
  int gymMinutesPerSession = 60;

  // Schedule — used both as context and to bound water reminders.
  // Stored as minutes-of-day (0..1439). Defaults: wake 7:00, sleep 23:00.
  int wakeTimeMin = 420;
  int sleepTimeMin = 1380;

  // Optional per-day override. When non-empty, must be length 7 with
  // entries indexed by weekday (0 = Monday … 6 = Sunday). The single
  // [wakeTimeMin] / [sleepTimeMin] above stay as the "applies to all"
  // fallback for users who haven't opted into per-day scheduling.
  List<int> wakeMinByDay = [];
  List<int> sleepMinByDay = [];

  // Supplements — affects water target (creatine especially) and gives
  // the coach context to make better recommendations.
  int creatineGramsPerDay = 0;
  int proteinScoopsPerDay = 0;
  bool multivitamin = false;
  String otherSupplementsNote = '';

  // Free-text body composition / focus areas (e.g. "skinny arms, belly
  // fat, average legs"). Surfaced to the AI coach for better suggestions.
  String bodyFocusNotes = '';

  // When the user started training. Used to detect the "newbie gains"
  // window (< 6 months) and soften the calorie deficit so muscle growth
  // isn't sabotaged. Null = unknown / never trained.
  DateTime? gymStartDate;

  // Health context — high-risk flags (pregnant, breastfeeding, eating
  // disorder, T1 diabetes) trigger a warning card and softer math;
  // others tune defaults and feed the AI advisory.
  @Enumerated(EnumType.name)
  List<HealthFlag> healthFlags = [];

  // Optional body-fat percentage. When set, BMR switches from
  // Mifflin-St Jeor to Katch-McArdle which is more accurate for lean
  // / muscular users.
  double? bodyFatPct;

  // Rest days (1=Mon..7=Sun). Used to compute a "training day vs rest
  // day" calorie split and to anchor weigh-in reminders.
  List<int> restDays = [];

  // How often the user wants weigh-in nudges.
  @Enumerated(EnumType.name)
  WeighInCadence weighInCadence = WeighInCadence.weekly;

  // Preferred weekday for weigh-ins (1=Mon..7=Sun). Null = derive from
  // restDays (day before the first rest day, default Sunday).
  int? weighInWeekday;

  // False when the user doesn't train at a gym (just walks / runs).
  // Hides gym fields in onboarding & profile edit and zeros out
  // strength-day / gym-minute math.
  bool goesGym = true;

  // 2-letter ISO country code (e.g. "NP", "IN", "US"). When set, the
  // AI coach surfaces region-appropriate food suggestions instead of
  // defaulting to generic Western meals.
  String country = '';

  // Dietary preference — drives meal suggestions and protein-source
  // recommendations.
  @Enumerated(EnumType.name)
  DietPreference dietPreference = DietPreference.omnivore;

  // Optional menstrual-cycle context (female users). When set, the
  // luteal phase bumps calories slightly (hormonal hunger), AI advisory
  // gains context, and water target rises in the late luteal week.
  @Enumerated(EnumType.name)
  CyclePhase cyclePhase = CyclePhase.unknown;

  // Derived & cached
  late double bmr;
  late double tdee;
  late int calorieTarget;
  late int proteinTargetG;
  late int carbTargetG;
  late int fatTargetG;
  late int fiberTargetG;
  late int waterTargetMl;
  late double bmi;

  // User overrides (nullable — null means use derived value)
  int? calorieOverride;
  int? proteinOverride;
  int? carbOverride;
  int? fatOverride;
  int? fiberOverride;
  int? waterOverride;

  DateTime createdAt = DateTime.now();
  DateTime updatedAt = DateTime.now();

  /// Wake time for a given DateTime weekday (1 = Mon … 7 = Sun). Falls
  /// back to [wakeTimeMin] when [wakeMinByDay] isn't a length-7 list.
  int wakeMinFor(int weekday) {
    if (wakeMinByDay.length == 7) return wakeMinByDay[weekday - 1];
    return wakeTimeMin;
  }

  /// Sleep time for a given DateTime weekday (1 = Mon … 7 = Sun). Falls
  /// back to [sleepTimeMin] when [sleepMinByDay] isn't a length-7 list.
  int sleepMinFor(int weekday) {
    if (sleepMinByDay.length == 7) return sleepMinByDay[weekday - 1];
    return sleepTimeMin;
  }

  int get effectiveCalorieTarget => calorieOverride ?? calorieTarget;
  int get effectiveProteinTarget => proteinOverride ?? proteinTargetG;
  int get effectiveCarbTarget => carbOverride ?? carbTargetG;
  int get effectiveFatTarget => fatOverride ?? fatTargetG;
  int get effectiveFiberTarget => fiberOverride ?? fiberTargetG;
  int get effectiveWaterTarget => waterOverride ?? waterTargetMl;
}
