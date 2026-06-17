import 'package:isar/isar.dart';

part 'routine.g.dart';

@collection
class Routine {
  Id id = Isar.autoIncrement;

  late String name;
  String? description;

  // Only one active routine at a time — this is what powers "today's workout".
  bool isActive = false;

  List<RoutineDay> days = [];

  DateTime createdAt = DateTime.now();
  DateTime updatedAt = DateTime.now();
}

@embedded
class RoutineDay {
  String name = ''; // "Push Day", "Pull", "Legs", "Rest"
  // 1=Mon ... 7=Sun. 0 = unassigned / available any day.
  int weekday = 0;
  bool isRest = false;

  List<RoutinePlanItem> items = [];
}

@embedded
class RoutinePlanItem {
  int exerciseId = 0;
  String exerciseName = '';
  int targetSets = 3;
  int targetRepsLow = 8;
  int targetRepsHigh = 12;
  double? targetWeightKg;
  int restSeconds = 90;
  String? notes;
}
