import '../../data/models/enums.dart';
import '../../data/models/exercise.dart';
import '../../data/models/routine.dart';
import '../../data/repositories/exercise_repo.dart';
import '../../data/repositories/workout_repo.dart';
import '../ai/ai_service.dart';

class RoutineGenerator {
  RoutineGenerator({
    required this.ai,
    required this.exercises,
    required this.workouts,
  });

  final AiService ai;
  final ExerciseRepo exercises;
  final WorkoutRepo workouts;

  /// Generates a routine via AI, persists it to the database, marks it
  /// active, and returns the saved Routine.
  Future<Routine> generateAndActivate({
    required FitnessGoal goal,
    required int trainingDaysPerWeek,
  }) async {
    final library = await exercises.all();
    final libraryNames = library.map((e) => e.name).toList();

    final plan = await ai.generateStarterRoutine(
      goal: goal,
      trainingDaysPerWeek: trainingDaysPerWeek,
      libraryExerciseNames: libraryNames,
    );

    final routine = Routine()
      ..name = plan.name
      ..description = _goalDescription(goal, trainingDaysPerWeek);

    final libByName = {
      for (final e in library) e.name.toLowerCase().trim(): e,
    };

    for (final d in plan.days) {
      final day = RoutineDay()
        ..name = d.name
        ..weekday = d.weekday
        ..isRest = d.isRest;
      for (final ex in d.exercises) {
        final lookup = ex.name.toLowerCase().trim();
        Exercise match = libByName[lookup] ??
            (await _resolveOrCreate(ex.name, libByName));
        final item = RoutinePlanItem()
          ..exerciseId = match.id
          ..exerciseName = match.name
          ..targetSets = ex.sets.clamp(1, 10)
          ..targetRepsLow = ex.repsLow.clamp(1, 50)
          ..targetRepsHigh = ex.repsHigh.clamp(ex.repsLow, 60)
          ..restSeconds = match.defaultRestSeconds
          ..notes = ex.notes;
        day.items.add(item);
      }
      routine.days.add(day);
    }

    final saved = await workouts.saveRoutine(routine);
    await workouts.activateRoutine(saved.id);
    return saved;
  }

  Future<Exercise> _resolveOrCreate(
      String name, Map<String, Exercise> libByName) async {
    final lookup = name.toLowerCase().trim();
    final existing = libByName[lookup];
    if (existing != null) return existing;
    final created = Exercise()
      ..name = _titleCase(name)
      ..isSeeded = false
      ..equipment = Equipment.other;
    await exercises.save(created);
    libByName[lookup] = created;
    return created;
  }

  String _goalDescription(FitnessGoal goal, int days) {
    final label = switch (goal) {
      FitnessGoal.buildMuscle => 'Build muscle',
      FitnessGoal.loseFat => 'Lose fat',
      FitnessGoal.recomp => 'Recomp',
      FitnessGoal.generalFitness => 'General fitness',
    };
    return '$label · $days days/week';
  }

  String _titleCase(String s) {
    return s
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
        .join(' ');
  }
}
