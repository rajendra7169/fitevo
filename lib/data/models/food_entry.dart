import 'package:isar/isar.dart';
import 'enums.dart';

part 'food_entry.g.dart';

@collection
class FoodEntry {
  Id id = Isar.autoIncrement;

  late DateTime timestamp;

  @Index()
  late String dateKey;

  late String rawInput;
  late String description;
  String quantity = '';
  String unit = '';

  int calories = 0;
  int proteinG = 0;
  int carbsG = 0;
  int fatG = 0;
  int fiberG = 0;
  int sodiumMg = 0;

  @Enumerated(EnumType.name)
  FoodSource source = FoodSource.aiText;

  @Enumerated(EnumType.name)
  EstimateConfidence confidence = EstimateConfidence.medium;

  int? caloriesLow;
  int? caloriesHigh;

  bool isFavorite = false;
  String? photoPath;
}
