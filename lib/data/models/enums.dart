enum Gender { male, female, other }

enum ActivityLevel { sedentary, light, moderate, active, veryActive }

enum FitnessGoal { buildMuscle, loseFat, recomp, generalFitness }

enum FoodSource { aiText, aiPhoto, usdaVerified, custom, favorite }

enum EstimateConfidence { high, medium, low }

enum MuscleGroup {
  chest,
  back,
  shoulders,
  biceps,
  triceps,
  forearms,
  quads,
  hamstrings,
  glutes,
  calves,
  core,
  cardio,
  fullBody,
}

/// Health & medical context. Some of these (pregnant, breastfeeding,
/// eating-disorder history, T1 diabetes) trigger a "talk to a pro" card
/// during onboarding and soften the math. Others (PCOS, hypothyroid, T2
/// diabetes) just adjust calorie / macro defaults and feed the AI coach.
enum HealthFlag {
  pregnant,
  breastfeeding,
  eatingDisorderHistory,
  recoveringFromInjury,
  t1Diabetes,
  t2Diabetes,
  pcos,
  hypothyroid,
}

/// How often the app should nudge the user to log weight. Stored
/// alongside an optional preferred weekday (1 = Mon … 7 = Sun) so the
/// reminder lands on a specific day each cycle.
enum WeighInCadence { daily, everyOtherDay, twiceAWeek, weekly }

/// Menstrual-cycle phase (female users only). Affects water retention,
/// hunger, and lifting performance. Tracked manually for now via a quick
/// picker; could be derived from a logged period start date later.
enum CyclePhase {
  unknown,
  menstrual, // days 1-5
  follicular, // days 6-14
  ovulation, // days 14-16
  luteal, // days 17-28
}

enum Equipment {
  bodyweight,
  dumbbell,
  barbell,
  machine,
  cable,
  kettlebell,
  band,
  smith,
  other,
}
