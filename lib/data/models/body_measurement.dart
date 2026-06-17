import 'package:isar/isar.dart';

part 'body_measurement.g.dart';

@collection
class BodyMeasurement {
  Id id = Isar.autoIncrement;

  @Index()
  late DateTime date;

  late double weightKg;

  double? bodyFatPct;
  double? waistCm;
  double? chestCm;
  double? hipsCm;
  double? thighCm;
  double? armCm;
  double? neckCm;

  // ON-DEVICE ONLY: this path is intentionally excluded from the cloud
  // sync service so progress photos never leave the user's phone.
  String? photoPath;

  String? note;

  DateTime createdAt = DateTime.now();
}
