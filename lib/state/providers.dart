import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db.dart';
import '../data/models/custom_food.dart';
import '../data/models/daily_log.dart';
import '../data/models/food_entry.dart';
import '../data/models/profile.dart';
import '../data/models/body_measurement.dart';
import '../data/models/exercise.dart';
import '../data/models/routine.dart';
import '../data/models/workout_session.dart';
import '../data/repositories/exercise_repo.dart';
import '../data/repositories/measurement_repo.dart';
import '../data/repositories/nutrition_repo.dart';
import '../data/repositories/profile_repo.dart';
import '../data/repositories/workout_repo.dart';
import '../services/data/data_export_service.dart';
import '../services/progress/adaptive_targets.dart';
import '../services/ai/ai_service.dart';
import '../services/ai/food_logger.dart';
import '../services/ai/gemini_ai_service.dart';
import '../services/ai/groq_ai_service.dart';
import '../services/ai/proxy_ai_service.dart';
import '../services/workout/routine_generator.dart';
import '../services/auth/auth_service.dart';
import '../services/nutrition/usda_service.dart';
import '../services/settings/app_settings.dart';
import '../services/sync/sync_service.dart';

const String _kGeminiApiKey =
    String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
const String _kGroqApiKey =
    String.fromEnvironment('GROQ_API_KEY', defaultValue: '');
const String _kUsdaApiKey =
    String.fromEnvironment('USDA_API_KEY', defaultValue: '');
const String _kAiProxyUrl =
    String.fromEnvironment('AI_PROXY_URL', defaultValue: '');

final dbProvider = Provider<Db>((ref) {
  throw UnimplementedError('dbProvider must be overridden at app start');
});

final appSettingsProvider = Provider<AppSettings>((ref) {
  throw UnimplementedError(
      'appSettingsProvider must be overridden at app start');
});

final themeModeProvider = StateProvider<ThemeMode>((ref) {
  return ref.watch(appSettingsProvider).themeMode;
});

final unitsProvider = StateProvider<UnitSystem>((ref) {
  return ref.watch(appSettingsProvider).units;
});

final profileRepoProvider = Provider<ProfileRepo>((ref) {
  return ProfileRepo(ref.watch(dbProvider));
});

final nutritionRepoProvider = Provider<NutritionRepo>((ref) {
  return NutritionRepo(ref.watch(dbProvider));
});

final profileStreamProvider = StreamProvider<Profile?>((ref) {
  return ref.watch(profileRepoProvider).watch();
});

final todayProvider = Provider<DateTime>((ref) {
  final n = DateTime.now();
  return DateTime(n.year, n.month, n.day);
});

final todayEntriesProvider = StreamProvider<List<FoodEntry>>((ref) {
  final repo = ref.watch(nutritionRepoProvider);
  return repo.watchEntriesForDate(ref.watch(todayProvider));
});

final todayLogProvider = StreamProvider<DailyLog?>((ref) {
  final repo = ref.watch(nutritionRepoProvider);
  return repo.watchDailyLog(ref.watch(todayProvider));
});

final todayTotalsProvider = Provider<DailyTotals>((ref) {
  final entries = ref.watch(todayEntriesProvider).valueOrNull ?? const [];
  final log = ref.watch(todayLogProvider).valueOrNull;
  return NutritionRepo.sumEntries(entries, waterMl: log?.waterMl ?? 0);
});

final customFoodsProvider = StreamProvider<List<CustomFood>>((ref) {
  return ref.watch(nutritionRepoProvider).watchCustomFoods();
});

final exerciseRepoProvider = Provider<ExerciseRepo>((ref) {
  return ExerciseRepo(ref.watch(dbProvider));
});

final workoutRepoProvider = Provider<WorkoutRepo>((ref) {
  return WorkoutRepo(ref.watch(dbProvider));
});

final exercisesProvider = StreamProvider<List<Exercise>>((ref) {
  return ref.watch(exerciseRepoProvider).watchAll();
});

final activeRoutineProvider = StreamProvider<Routine?>((ref) {
  return ref.watch(workoutRepoProvider).watchActiveRoutine();
});

final recentSessionsProvider = StreamProvider<List<WorkoutSession>>((ref) {
  return ref.watch(workoutRepoProvider).watchRecentSessions();
});

final allSessionsProvider = StreamProvider<List<WorkoutSession>>((ref) {
  return ref.watch(workoutRepoProvider).watchAllSessions();
});

final measurementRepoProvider = Provider<MeasurementRepo>((ref) {
  return MeasurementRepo(ref.watch(dbProvider));
});

final measurementsProvider = StreamProvider<List<BodyMeasurement>>((ref) {
  return ref.watch(measurementRepoProvider).watchAll();
});

final adaptiveTargetsProvider = Provider<AdaptiveTargets>((ref) {
  return AdaptiveTargets(
    profileRepo: ref.watch(profileRepoProvider),
    measurementRepo: ref.watch(measurementRepoProvider),
  );
});

final dataExportServiceProvider = Provider<DataExportService>((ref) {
  return DataExportService(ref.watch(dbProvider));
});

/// All food entries across all dates — used for trend charts and streak.
final allFoodEntriesProvider = StreamProvider<List<FoodEntry>>((ref) {
  return ref.watch(nutritionRepoProvider).watchAllEntries();
});

final todaysRoutineDayProvider =
    FutureProvider.autoDispose<RoutineDay?>((ref) async {
  ref.watch(activeRoutineProvider);
  final today = ref.watch(todayProvider);
  return ref.read(workoutRepoProvider).resolveTodaysDay(today);
});

final routineGeneratorProvider = Provider<RoutineGenerator>((ref) {
  return RoutineGenerator(
    ai: ref.watch(aiServiceProvider),
    exercises: ref.watch(exerciseRepoProvider),
    workouts: ref.watch(workoutRepoProvider),
  );
});

final aiServiceProvider = Provider<AiService>((ref) {
  // Priority: Proxy → Groq → Gemini. Whichever is configured wins.
  if (_kAiProxyUrl.isNotEmpty) {
    return ProxyAiService(baseUrl: _kAiProxyUrl);
  }
  if (_kGroqApiKey.isNotEmpty) {
    return GroqAiService(apiKey: _kGroqApiKey);
  }
  return GeminiAiService(apiKey: _kGeminiApiKey);
});

final usdaServiceProvider = Provider<UsdaService>((ref) {
  return UsdaService(apiKey: _kUsdaApiKey);
});

final foodLoggerProvider = Provider<FoodLogger>((ref) {
  return FoodLogger(
    ai: ref.watch(aiServiceProvider),
    nutrition: ref.watch(nutritionRepoProvider),
    usda: ref.watch(usdaServiceProvider),
  );
});

bool get isAiConfigured =>
    _kGroqApiKey.isNotEmpty ||
    _kGeminiApiKey.isNotEmpty ||
    _kAiProxyUrl.isNotEmpty;

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).userChanges;
});

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(db: ref.watch(dbProvider));
});

/// Runs once per uid on sign-in: pulls cloud → local if local is empty,
/// pushes local → cloud if cloud is empty.
final initialSyncProvider = FutureProvider.family<void, String>((ref, uid) async {
  final sync = ref.watch(syncServiceProvider);
  final hasLocal = await sync.localHasData();
  final hasCloud = await sync.cloudHasData();
  if (!hasLocal && hasCloud) {
    await sync.pullAll();
  } else if (hasLocal && !hasCloud) {
    await sync.pushAll();
  }
});
