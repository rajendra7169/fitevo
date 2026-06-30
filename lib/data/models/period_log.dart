import 'package:isar/isar.dart';
import 'enums.dart';

part 'period_log.g.dart';

/// Per-day cycle entry. Sparse — only days the user actively logged a
/// flow or symptoms have a row. Cycle-length estimation, "where in the
/// cycle am I today?", and the home card all read from this collection.
@collection
class PeriodLog {
  Id id = Isar.autoIncrement;

  /// YYYY-MM-DD key so we can upsert by date in O(1).
  @Index(unique: true, replace: true)
  late String dateKey;

  /// When this entry is anchored (start-of-day local time). Kept
  /// alongside [dateKey] so timestamp-sorted queries don't need to
  /// reparse the string.
  late DateTime date;

  @Enumerated(EnumType.name)
  MenstrualFlow flow = MenstrualFlow.none;

  @Enumerated(EnumType.name)
  List<PeriodSymptom> symptoms = const [];

  String notes = '';

  DateTime createdAt = DateTime.now();
  DateTime updatedAt = DateTime.now();

  static String keyFor(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
