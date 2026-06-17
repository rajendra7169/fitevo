import 'package:isar/isar.dart';

part 'workout_session.g.dart';

@collection
class WorkoutSession {
  Id id = Isar.autoIncrement;

  @Index()
  late String dateKey;

  DateTime startedAt = DateTime.now();
  DateTime? completedAt;

  String routineName = '';
  String routineDayName = '';

  List<SetEntry> sets = [];

  int? perceivedDifficulty; // 1-10 (RPE-like) for the session as a whole
  String? note;

  @ignore
  Duration get duration {
    final end = completedAt ?? DateTime.now();
    return end.difference(startedAt);
  }

  static String keyFor(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

@embedded
class SetEntry {
  int exerciseId = 0;
  String exerciseName = '';
  int setNumber = 1;
  double weightKg = 0;
  int reps = 0;
  double? rpe;
  bool isWarmup = false;
  DateTime completedAt = DateTime.now();
}
