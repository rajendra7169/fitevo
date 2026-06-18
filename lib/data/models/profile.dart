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

  // Supplements — affects water target (creatine especially) and gives
  // the coach context to make better recommendations.
  int creatineGramsPerDay = 0;
  int proteinScoopsPerDay = 0;
  bool multivitamin = false;
  String otherSupplementsNote = '';

  // Free-text body composition / focus areas (e.g. "skinny arms, belly
  // fat, average legs"). Surfaced to the AI coach for better suggestions.
  String bodyFocusNotes = '';

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

  int get effectiveCalorieTarget => calorieOverride ?? calorieTarget;
  int get effectiveProteinTarget => proteinOverride ?? proteinTargetG;
  int get effectiveCarbTarget => carbOverride ?? carbTargetG;
  int get effectiveFatTarget => fatOverride ?? fatTargetG;
  int get effectiveFiberTarget => fiberOverride ?? fiberTargetG;
  int get effectiveWaterTarget => waterOverride ?? waterTargetMl;
}
