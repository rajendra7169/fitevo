import 'package:isar/isar.dart';
import 'enums.dart';

part 'exercise.g.dart';

@collection
class Exercise {
  Id id = Isar.autoIncrement;

  @Index(caseSensitive: false)
  late String name;

  @Enumerated(EnumType.name)
  List<MuscleGroup> muscleGroups = [];

  @Enumerated(EnumType.name)
  Equipment equipment = Equipment.bodyweight;

  bool isBeginnerFriendly = true;

  List<String> formCues = [];
  List<String> commonMistakes = [];
  String? illustrationAsset;

  int defaultRestSeconds = 90;

  // True for app-bundled exercises (seeded on first run), false for
  // user-added or AI-suggested ones that weren't in the seed list.
  bool isSeeded = true;

  DateTime createdAt = DateTime.now();
}
