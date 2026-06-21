// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetProfileCollection on Isar {
  IsarCollection<Profile> get profiles => this.collection();
}

const ProfileSchema = CollectionSchema(
  name: r'Profile',
  id: 1266279811925214857,
  properties: {
    r'activityLevel': PropertySchema(
      id: 0,
      name: r'activityLevel',
      type: IsarType.string,
      enumMap: _ProfileactivityLevelEnumValueMap,
    ),
    r'age': PropertySchema(
      id: 1,
      name: r'age',
      type: IsarType.long,
    ),
    r'bmi': PropertySchema(
      id: 2,
      name: r'bmi',
      type: IsarType.double,
    ),
    r'bmr': PropertySchema(
      id: 3,
      name: r'bmr',
      type: IsarType.double,
    ),
    r'bodyFatPct': PropertySchema(
      id: 4,
      name: r'bodyFatPct',
      type: IsarType.double,
    ),
    r'bodyFocusNotes': PropertySchema(
      id: 5,
      name: r'bodyFocusNotes',
      type: IsarType.string,
    ),
    r'calorieOverride': PropertySchema(
      id: 6,
      name: r'calorieOverride',
      type: IsarType.long,
    ),
    r'calorieTarget': PropertySchema(
      id: 7,
      name: r'calorieTarget',
      type: IsarType.long,
    ),
    r'carbOverride': PropertySchema(
      id: 8,
      name: r'carbOverride',
      type: IsarType.long,
    ),
    r'carbTargetG': PropertySchema(
      id: 9,
      name: r'carbTargetG',
      type: IsarType.long,
    ),
    r'cardioSessionsPerWeek': PropertySchema(
      id: 10,
      name: r'cardioSessionsPerWeek',
      type: IsarType.long,
    ),
    r'createdAt': PropertySchema(
      id: 11,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'creatineGramsPerDay': PropertySchema(
      id: 12,
      name: r'creatineGramsPerDay',
      type: IsarType.long,
    ),
    r'cyclePhase': PropertySchema(
      id: 13,
      name: r'cyclePhase',
      type: IsarType.string,
      enumMap: _ProfilecyclePhaseEnumValueMap,
    ),
    r'displayName': PropertySchema(
      id: 14,
      name: r'displayName',
      type: IsarType.string,
    ),
    r'effectiveCalorieTarget': PropertySchema(
      id: 15,
      name: r'effectiveCalorieTarget',
      type: IsarType.long,
    ),
    r'effectiveCarbTarget': PropertySchema(
      id: 16,
      name: r'effectiveCarbTarget',
      type: IsarType.long,
    ),
    r'effectiveFatTarget': PropertySchema(
      id: 17,
      name: r'effectiveFatTarget',
      type: IsarType.long,
    ),
    r'effectiveFiberTarget': PropertySchema(
      id: 18,
      name: r'effectiveFiberTarget',
      type: IsarType.long,
    ),
    r'effectiveProteinTarget': PropertySchema(
      id: 19,
      name: r'effectiveProteinTarget',
      type: IsarType.long,
    ),
    r'effectiveWaterTarget': PropertySchema(
      id: 20,
      name: r'effectiveWaterTarget',
      type: IsarType.long,
    ),
    r'fatOverride': PropertySchema(
      id: 21,
      name: r'fatOverride',
      type: IsarType.long,
    ),
    r'fatTargetG': PropertySchema(
      id: 22,
      name: r'fatTargetG',
      type: IsarType.long,
    ),
    r'fiberOverride': PropertySchema(
      id: 23,
      name: r'fiberOverride',
      type: IsarType.long,
    ),
    r'fiberTargetG': PropertySchema(
      id: 24,
      name: r'fiberTargetG',
      type: IsarType.long,
    ),
    r'gender': PropertySchema(
      id: 25,
      name: r'gender',
      type: IsarType.string,
      enumMap: _ProfilegenderEnumValueMap,
    ),
    r'goal': PropertySchema(
      id: 26,
      name: r'goal',
      type: IsarType.string,
      enumMap: _ProfilegoalEnumValueMap,
    ),
    r'goesGym': PropertySchema(
      id: 27,
      name: r'goesGym',
      type: IsarType.bool,
    ),
    r'gymMinutesPerSession': PropertySchema(
      id: 28,
      name: r'gymMinutesPerSession',
      type: IsarType.long,
    ),
    r'gymStartDate': PropertySchema(
      id: 29,
      name: r'gymStartDate',
      type: IsarType.dateTime,
    ),
    r'healthFlags': PropertySchema(
      id: 30,
      name: r'healthFlags',
      type: IsarType.stringList,
      enumMap: _ProfilehealthFlagsEnumValueMap,
    ),
    r'heightCm': PropertySchema(
      id: 31,
      name: r'heightCm',
      type: IsarType.double,
    ),
    r'multivitamin': PropertySchema(
      id: 32,
      name: r'multivitamin',
      type: IsarType.bool,
    ),
    r'otherSupplementsNote': PropertySchema(
      id: 33,
      name: r'otherSupplementsNote',
      type: IsarType.string,
    ),
    r'proteinOverride': PropertySchema(
      id: 34,
      name: r'proteinOverride',
      type: IsarType.long,
    ),
    r'proteinScoopsPerDay': PropertySchema(
      id: 35,
      name: r'proteinScoopsPerDay',
      type: IsarType.long,
    ),
    r'proteinTargetG': PropertySchema(
      id: 36,
      name: r'proteinTargetG',
      type: IsarType.long,
    ),
    r'restDays': PropertySchema(
      id: 37,
      name: r'restDays',
      type: IsarType.longList,
    ),
    r'runningKmPerWeek': PropertySchema(
      id: 38,
      name: r'runningKmPerWeek',
      type: IsarType.double,
    ),
    r'sleepTimeMin': PropertySchema(
      id: 39,
      name: r'sleepTimeMin',
      type: IsarType.long,
    ),
    r'tdee': PropertySchema(
      id: 40,
      name: r'tdee',
      type: IsarType.double,
    ),
    r'trainingDaysPerWeek': PropertySchema(
      id: 41,
      name: r'trainingDaysPerWeek',
      type: IsarType.long,
    ),
    r'updatedAt': PropertySchema(
      id: 42,
      name: r'updatedAt',
      type: IsarType.dateTime,
    ),
    r'wakeTimeMin': PropertySchema(
      id: 43,
      name: r'wakeTimeMin',
      type: IsarType.long,
    ),
    r'walkingKmPerDay': PropertySchema(
      id: 44,
      name: r'walkingKmPerDay',
      type: IsarType.double,
    ),
    r'waterOverride': PropertySchema(
      id: 45,
      name: r'waterOverride',
      type: IsarType.long,
    ),
    r'waterTargetMl': PropertySchema(
      id: 46,
      name: r'waterTargetMl',
      type: IsarType.long,
    ),
    r'weighInCadence': PropertySchema(
      id: 47,
      name: r'weighInCadence',
      type: IsarType.string,
      enumMap: _ProfileweighInCadenceEnumValueMap,
    ),
    r'weighInWeekday': PropertySchema(
      id: 48,
      name: r'weighInWeekday',
      type: IsarType.long,
    ),
    r'weightKg': PropertySchema(
      id: 49,
      name: r'weightKg',
      type: IsarType.double,
    )
  },
  estimateSize: _profileEstimateSize,
  serialize: _profileSerialize,
  deserialize: _profileDeserialize,
  deserializeProp: _profileDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _profileGetId,
  getLinks: _profileGetLinks,
  attach: _profileAttach,
  version: '3.1.0+1',
);

int _profileEstimateSize(
  Profile object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.activityLevel.name.length * 3;
  bytesCount += 3 + object.bodyFocusNotes.length * 3;
  bytesCount += 3 + object.cyclePhase.name.length * 3;
  bytesCount += 3 + object.displayName.length * 3;
  bytesCount += 3 + object.gender.name.length * 3;
  bytesCount += 3 + object.goal.name.length * 3;
  bytesCount += 3 + object.healthFlags.length * 3;
  {
    for (var i = 0; i < object.healthFlags.length; i++) {
      final value = object.healthFlags[i];
      bytesCount += value.name.length * 3;
    }
  }
  bytesCount += 3 + object.otherSupplementsNote.length * 3;
  bytesCount += 3 + object.restDays.length * 8;
  bytesCount += 3 + object.weighInCadence.name.length * 3;
  return bytesCount;
}

void _profileSerialize(
  Profile object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.activityLevel.name);
  writer.writeLong(offsets[1], object.age);
  writer.writeDouble(offsets[2], object.bmi);
  writer.writeDouble(offsets[3], object.bmr);
  writer.writeDouble(offsets[4], object.bodyFatPct);
  writer.writeString(offsets[5], object.bodyFocusNotes);
  writer.writeLong(offsets[6], object.calorieOverride);
  writer.writeLong(offsets[7], object.calorieTarget);
  writer.writeLong(offsets[8], object.carbOverride);
  writer.writeLong(offsets[9], object.carbTargetG);
  writer.writeLong(offsets[10], object.cardioSessionsPerWeek);
  writer.writeDateTime(offsets[11], object.createdAt);
  writer.writeLong(offsets[12], object.creatineGramsPerDay);
  writer.writeString(offsets[13], object.cyclePhase.name);
  writer.writeString(offsets[14], object.displayName);
  writer.writeLong(offsets[15], object.effectiveCalorieTarget);
  writer.writeLong(offsets[16], object.effectiveCarbTarget);
  writer.writeLong(offsets[17], object.effectiveFatTarget);
  writer.writeLong(offsets[18], object.effectiveFiberTarget);
  writer.writeLong(offsets[19], object.effectiveProteinTarget);
  writer.writeLong(offsets[20], object.effectiveWaterTarget);
  writer.writeLong(offsets[21], object.fatOverride);
  writer.writeLong(offsets[22], object.fatTargetG);
  writer.writeLong(offsets[23], object.fiberOverride);
  writer.writeLong(offsets[24], object.fiberTargetG);
  writer.writeString(offsets[25], object.gender.name);
  writer.writeString(offsets[26], object.goal.name);
  writer.writeBool(offsets[27], object.goesGym);
  writer.writeLong(offsets[28], object.gymMinutesPerSession);
  writer.writeDateTime(offsets[29], object.gymStartDate);
  writer.writeStringList(
      offsets[30], object.healthFlags.map((e) => e.name).toList());
  writer.writeDouble(offsets[31], object.heightCm);
  writer.writeBool(offsets[32], object.multivitamin);
  writer.writeString(offsets[33], object.otherSupplementsNote);
  writer.writeLong(offsets[34], object.proteinOverride);
  writer.writeLong(offsets[35], object.proteinScoopsPerDay);
  writer.writeLong(offsets[36], object.proteinTargetG);
  writer.writeLongList(offsets[37], object.restDays);
  writer.writeDouble(offsets[38], object.runningKmPerWeek);
  writer.writeLong(offsets[39], object.sleepTimeMin);
  writer.writeDouble(offsets[40], object.tdee);
  writer.writeLong(offsets[41], object.trainingDaysPerWeek);
  writer.writeDateTime(offsets[42], object.updatedAt);
  writer.writeLong(offsets[43], object.wakeTimeMin);
  writer.writeDouble(offsets[44], object.walkingKmPerDay);
  writer.writeLong(offsets[45], object.waterOverride);
  writer.writeLong(offsets[46], object.waterTargetMl);
  writer.writeString(offsets[47], object.weighInCadence.name);
  writer.writeLong(offsets[48], object.weighInWeekday);
  writer.writeDouble(offsets[49], object.weightKg);
}

Profile _profileDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = Profile();
  object.activityLevel =
      _ProfileactivityLevelValueEnumMap[reader.readStringOrNull(offsets[0])] ??
          ActivityLevel.sedentary;
  object.age = reader.readLong(offsets[1]);
  object.bmi = reader.readDouble(offsets[2]);
  object.bmr = reader.readDouble(offsets[3]);
  object.bodyFatPct = reader.readDoubleOrNull(offsets[4]);
  object.bodyFocusNotes = reader.readString(offsets[5]);
  object.calorieOverride = reader.readLongOrNull(offsets[6]);
  object.calorieTarget = reader.readLong(offsets[7]);
  object.carbOverride = reader.readLongOrNull(offsets[8]);
  object.carbTargetG = reader.readLong(offsets[9]);
  object.cardioSessionsPerWeek = reader.readLong(offsets[10]);
  object.createdAt = reader.readDateTime(offsets[11]);
  object.creatineGramsPerDay = reader.readLong(offsets[12]);
  object.cyclePhase =
      _ProfilecyclePhaseValueEnumMap[reader.readStringOrNull(offsets[13])] ??
          CyclePhase.unknown;
  object.displayName = reader.readString(offsets[14]);
  object.fatOverride = reader.readLongOrNull(offsets[21]);
  object.fatTargetG = reader.readLong(offsets[22]);
  object.fiberOverride = reader.readLongOrNull(offsets[23]);
  object.fiberTargetG = reader.readLong(offsets[24]);
  object.gender =
      _ProfilegenderValueEnumMap[reader.readStringOrNull(offsets[25])] ??
          Gender.male;
  object.goal =
      _ProfilegoalValueEnumMap[reader.readStringOrNull(offsets[26])] ??
          FitnessGoal.buildMuscle;
  object.goesGym = reader.readBool(offsets[27]);
  object.gymMinutesPerSession = reader.readLong(offsets[28]);
  object.gymStartDate = reader.readDateTimeOrNull(offsets[29]);
  object.healthFlags = reader
          .readStringList(offsets[30])
          ?.map(
              (e) => _ProfilehealthFlagsValueEnumMap[e] ?? HealthFlag.pregnant)
          .toList() ??
      [];
  object.heightCm = reader.readDouble(offsets[31]);
  object.id = id;
  object.multivitamin = reader.readBool(offsets[32]);
  object.otherSupplementsNote = reader.readString(offsets[33]);
  object.proteinOverride = reader.readLongOrNull(offsets[34]);
  object.proteinScoopsPerDay = reader.readLong(offsets[35]);
  object.proteinTargetG = reader.readLong(offsets[36]);
  object.restDays = reader.readLongList(offsets[37]) ?? [];
  object.runningKmPerWeek = reader.readDouble(offsets[38]);
  object.sleepTimeMin = reader.readLong(offsets[39]);
  object.tdee = reader.readDouble(offsets[40]);
  object.trainingDaysPerWeek = reader.readLong(offsets[41]);
  object.updatedAt = reader.readDateTime(offsets[42]);
  object.wakeTimeMin = reader.readLong(offsets[43]);
  object.walkingKmPerDay = reader.readDouble(offsets[44]);
  object.waterOverride = reader.readLongOrNull(offsets[45]);
  object.waterTargetMl = reader.readLong(offsets[46]);
  object.weighInCadence = _ProfileweighInCadenceValueEnumMap[
          reader.readStringOrNull(offsets[47])] ??
      WeighInCadence.daily;
  object.weighInWeekday = reader.readLongOrNull(offsets[48]);
  object.weightKg = reader.readDouble(offsets[49]);
  return object;
}

P _profileDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (_ProfileactivityLevelValueEnumMap[
              reader.readStringOrNull(offset)] ??
          ActivityLevel.sedentary) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    case 2:
      return (reader.readDouble(offset)) as P;
    case 3:
      return (reader.readDouble(offset)) as P;
    case 4:
      return (reader.readDoubleOrNull(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readLongOrNull(offset)) as P;
    case 7:
      return (reader.readLong(offset)) as P;
    case 8:
      return (reader.readLongOrNull(offset)) as P;
    case 9:
      return (reader.readLong(offset)) as P;
    case 10:
      return (reader.readLong(offset)) as P;
    case 11:
      return (reader.readDateTime(offset)) as P;
    case 12:
      return (reader.readLong(offset)) as P;
    case 13:
      return (_ProfilecyclePhaseValueEnumMap[reader.readStringOrNull(offset)] ??
          CyclePhase.unknown) as P;
    case 14:
      return (reader.readString(offset)) as P;
    case 15:
      return (reader.readLong(offset)) as P;
    case 16:
      return (reader.readLong(offset)) as P;
    case 17:
      return (reader.readLong(offset)) as P;
    case 18:
      return (reader.readLong(offset)) as P;
    case 19:
      return (reader.readLong(offset)) as P;
    case 20:
      return (reader.readLong(offset)) as P;
    case 21:
      return (reader.readLongOrNull(offset)) as P;
    case 22:
      return (reader.readLong(offset)) as P;
    case 23:
      return (reader.readLongOrNull(offset)) as P;
    case 24:
      return (reader.readLong(offset)) as P;
    case 25:
      return (_ProfilegenderValueEnumMap[reader.readStringOrNull(offset)] ??
          Gender.male) as P;
    case 26:
      return (_ProfilegoalValueEnumMap[reader.readStringOrNull(offset)] ??
          FitnessGoal.buildMuscle) as P;
    case 27:
      return (reader.readBool(offset)) as P;
    case 28:
      return (reader.readLong(offset)) as P;
    case 29:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 30:
      return (reader
              .readStringList(offset)
              ?.map((e) =>
                  _ProfilehealthFlagsValueEnumMap[e] ?? HealthFlag.pregnant)
              .toList() ??
          []) as P;
    case 31:
      return (reader.readDouble(offset)) as P;
    case 32:
      return (reader.readBool(offset)) as P;
    case 33:
      return (reader.readString(offset)) as P;
    case 34:
      return (reader.readLongOrNull(offset)) as P;
    case 35:
      return (reader.readLong(offset)) as P;
    case 36:
      return (reader.readLong(offset)) as P;
    case 37:
      return (reader.readLongList(offset) ?? []) as P;
    case 38:
      return (reader.readDouble(offset)) as P;
    case 39:
      return (reader.readLong(offset)) as P;
    case 40:
      return (reader.readDouble(offset)) as P;
    case 41:
      return (reader.readLong(offset)) as P;
    case 42:
      return (reader.readDateTime(offset)) as P;
    case 43:
      return (reader.readLong(offset)) as P;
    case 44:
      return (reader.readDouble(offset)) as P;
    case 45:
      return (reader.readLongOrNull(offset)) as P;
    case 46:
      return (reader.readLong(offset)) as P;
    case 47:
      return (_ProfileweighInCadenceValueEnumMap[
              reader.readStringOrNull(offset)] ??
          WeighInCadence.daily) as P;
    case 48:
      return (reader.readLongOrNull(offset)) as P;
    case 49:
      return (reader.readDouble(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _ProfileactivityLevelEnumValueMap = {
  r'sedentary': r'sedentary',
  r'light': r'light',
  r'moderate': r'moderate',
  r'active': r'active',
  r'veryActive': r'veryActive',
};
const _ProfileactivityLevelValueEnumMap = {
  r'sedentary': ActivityLevel.sedentary,
  r'light': ActivityLevel.light,
  r'moderate': ActivityLevel.moderate,
  r'active': ActivityLevel.active,
  r'veryActive': ActivityLevel.veryActive,
};
const _ProfilecyclePhaseEnumValueMap = {
  r'unknown': r'unknown',
  r'menstrual': r'menstrual',
  r'follicular': r'follicular',
  r'ovulation': r'ovulation',
  r'luteal': r'luteal',
};
const _ProfilecyclePhaseValueEnumMap = {
  r'unknown': CyclePhase.unknown,
  r'menstrual': CyclePhase.menstrual,
  r'follicular': CyclePhase.follicular,
  r'ovulation': CyclePhase.ovulation,
  r'luteal': CyclePhase.luteal,
};
const _ProfilegenderEnumValueMap = {
  r'male': r'male',
  r'female': r'female',
  r'other': r'other',
};
const _ProfilegenderValueEnumMap = {
  r'male': Gender.male,
  r'female': Gender.female,
  r'other': Gender.other,
};
const _ProfilegoalEnumValueMap = {
  r'buildMuscle': r'buildMuscle',
  r'loseFat': r'loseFat',
  r'recomp': r'recomp',
  r'generalFitness': r'generalFitness',
};
const _ProfilegoalValueEnumMap = {
  r'buildMuscle': FitnessGoal.buildMuscle,
  r'loseFat': FitnessGoal.loseFat,
  r'recomp': FitnessGoal.recomp,
  r'generalFitness': FitnessGoal.generalFitness,
};
const _ProfilehealthFlagsEnumValueMap = {
  r'pregnant': r'pregnant',
  r'breastfeeding': r'breastfeeding',
  r'eatingDisorderHistory': r'eatingDisorderHistory',
  r'recoveringFromInjury': r'recoveringFromInjury',
  r't1Diabetes': r't1Diabetes',
  r't2Diabetes': r't2Diabetes',
  r'pcos': r'pcos',
  r'hypothyroid': r'hypothyroid',
};
const _ProfilehealthFlagsValueEnumMap = {
  r'pregnant': HealthFlag.pregnant,
  r'breastfeeding': HealthFlag.breastfeeding,
  r'eatingDisorderHistory': HealthFlag.eatingDisorderHistory,
  r'recoveringFromInjury': HealthFlag.recoveringFromInjury,
  r't1Diabetes': HealthFlag.t1Diabetes,
  r't2Diabetes': HealthFlag.t2Diabetes,
  r'pcos': HealthFlag.pcos,
  r'hypothyroid': HealthFlag.hypothyroid,
};
const _ProfileweighInCadenceEnumValueMap = {
  r'daily': r'daily',
  r'everyOtherDay': r'everyOtherDay',
  r'twiceAWeek': r'twiceAWeek',
  r'weekly': r'weekly',
};
const _ProfileweighInCadenceValueEnumMap = {
  r'daily': WeighInCadence.daily,
  r'everyOtherDay': WeighInCadence.everyOtherDay,
  r'twiceAWeek': WeighInCadence.twiceAWeek,
  r'weekly': WeighInCadence.weekly,
};

Id _profileGetId(Profile object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _profileGetLinks(Profile object) {
  return [];
}

void _profileAttach(IsarCollection<dynamic> col, Id id, Profile object) {
  object.id = id;
}

extension ProfileQueryWhereSort on QueryBuilder<Profile, Profile, QWhere> {
  QueryBuilder<Profile, Profile, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension ProfileQueryWhere on QueryBuilder<Profile, Profile, QWhereClause> {
  QueryBuilder<Profile, Profile, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterWhereClause> idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<Profile, Profile, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<Profile, Profile, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<Profile, Profile, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension ProfileQueryFilter
    on QueryBuilder<Profile, Profile, QFilterCondition> {
  QueryBuilder<Profile, Profile, QAfterFilterCondition> activityLevelEqualTo(
    ActivityLevel value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'activityLevel',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition>
      activityLevelGreaterThan(
    ActivityLevel value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'activityLevel',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> activityLevelLessThan(
    ActivityLevel value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'activityLevel',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> activityLevelBetween(
    ActivityLevel lower,
    ActivityLevel upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'activityLevel',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> activityLevelStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'activityLevel',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> activityLevelEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'activityLevel',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> activityLevelContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'activityLevel',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> activityLevelMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'activityLevel',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> activityLevelIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'activityLevel',
        value: '',
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition>
      activityLevelIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'activityLevel',
        value: '',
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> ageEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'age',
        value: value,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> ageGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'age',
        value: value,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> ageLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'age',
        value: value,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> ageBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'age',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> bmiEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'bmi',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> bmiGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'bmi',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> bmiLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'bmi',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> bmiBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'bmi',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> bmrEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'bmr',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> bmrGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'bmr',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> bmrLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'bmr',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> bmrBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'bmr',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> bodyFatPctIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'bodyFatPct',
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> bodyFatPctIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'bodyFatPct',
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> bodyFatPctEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'bodyFatPct',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> bodyFatPctGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'bodyFatPct',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> bodyFatPctLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'bodyFatPct',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> bodyFatPctBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'bodyFatPct',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> bodyFocusNotesEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'bodyFocusNotes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition>
      bodyFocusNotesGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'bodyFocusNotes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> bodyFocusNotesLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'bodyFocusNotes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> bodyFocusNotesBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'bodyFocusNotes',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition>
      bodyFocusNotesStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'bodyFocusNotes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> bodyFocusNotesEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'bodyFocusNotes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> bodyFocusNotesContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'bodyFocusNotes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> bodyFocusNotesMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'bodyFocusNotes',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition>
      bodyFocusNotesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'bodyFocusNotes',
        value: '',
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition>
      bodyFocusNotesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'bodyFocusNotes',
        value: '',
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition>
      calorieOverrideIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'calorieOverride',
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition>
      calorieOverrideIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'calorieOverride',
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> calorieOverrideEqualTo(
      int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'calorieOverride',
        value: value,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition>
      calorieOverrideGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'calorieOverride',
        value: value,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> calorieOverrideLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'calorieOverride',
        value: value,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> calorieOverrideBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'calorieOverride',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> calorieTargetEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'calorieTarget',
        value: value,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition>
      calorieTargetGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'calorieTarget',
        value: value,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> calorieTargetLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'calorieTarget',
        value: value,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> calorieTargetBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'calorieTarget',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> carbOverrideIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'carbOverride',
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition>
      carbOverrideIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'carbOverride',
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> carbOverrideEqualTo(
      int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'carbOverride',
        value: value,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> carbOverrideGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'carbOverride',
        value: value,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> carbOverrideLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'carbOverride',
        value: value,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> carbOverrideBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'carbOverride',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> carbTargetGEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'carbTargetG',
        value: value,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> carbTargetGGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'carbTargetG',
        value: value,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> carbTargetGLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'carbTargetG',
        value: value,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> carbTargetGBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'carbTargetG',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition>
      cardioSessionsPerWeekEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cardioSessionsPerWeek',
        value: value,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition>
      cardioSessionsPerWeekGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'cardioSessionsPerWeek',
        value: value,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition>
      cardioSessionsPerWeekLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'cardioSessionsPerWeek',
        value: value,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition>
      cardioSessionsPerWeekBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'cardioSessionsPerWeek',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> createdAtEqualTo(
      DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> createdAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> createdAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> createdAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'createdAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition>
      creatineGramsPerDayEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'creatineGramsPerDay',
        value: value,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition>
      creatineGramsPerDayGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'creatineGramsPerDay',
        value: value,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition>
      creatineGramsPerDayLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'creatineGramsPerDay',
        value: value,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition>
      creatineGramsPerDayBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'creatineGramsPerDay',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> cyclePhaseEqualTo(
    CyclePhase value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cyclePhase',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> cyclePhaseGreaterThan(
    CyclePhase value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'cyclePhase',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> cyclePhaseLessThan(
    CyclePhase value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'cyclePhase',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> cyclePhaseBetween(
    CyclePhase lower,
    CyclePhase upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'cyclePhase',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> cyclePhaseStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'cyclePhase',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> cyclePhaseEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'cyclePhase',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> cyclePhaseContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'cyclePhase',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> cyclePhaseMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'cyclePhase',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> cyclePhaseIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cyclePhase',
        value: '',
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> cyclePhaseIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'cyclePhase',
        value: '',
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> displayNameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'displayName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> displayNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'displayName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> displayNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'displayName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> displayNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'displayName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> displayNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'displayName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> displayNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'displayName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> displayNameContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'displayName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> displayNameMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'displayName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> displayNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'displayName',
        value: '',
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition>
      displayNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'displayName',
        value: '',
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition>
      effectiveCalorieTargetEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'effectiveCalorieTarget',
        value: value,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition>
      effectiveCalorieTargetGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'effectiveCalorieTarget',
        value: value,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition>
      effectiveCalorieTargetLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'effectiveCalorieTarget',
        value: value,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition>
      effectiveCalorieTargetBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'effectiveCalorieTarget',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition>
      effectiveCarbTargetEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'effectiveCarbTarget',
        value: value,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition>
      effectiveCarbTargetGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'effectiveCarbTarget',
        value: value,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition>
      effectiveCarbTargetLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'effectiveCarbTarget',
        value: value,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition>
      effectiveCarbTargetBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'effectiveCarbTarget',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition>
      effectiveFatTargetEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'effectiveFatTarget',
        value: value,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition>
      effectiveFatTargetGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'effectiveFatTarget',
        value: value,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition>
      effectiveFatTargetLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'effectiveFatTarget',
        value: value,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition>
      effectiveFatTargetBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'effectiveFatTarget',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition>
      effectiveFiberTargetEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'effectiveFiberTarget',
        value: value,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition>
      effectiveFiberTargetGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'effectiveFiberTarget',
        value: value,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition>
      effectiveFiberTargetLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'effectiveFiberTarget',
        value: value,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition>
      effectiveFiberTargetBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'effectiveFiberTarget',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition>
      effectiveProteinTargetEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'effectiveProteinTarget',
        value: value,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition>
      effectiveProteinTargetGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'effectiveProteinTarget',
        value: value,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition>
      effectiveProteinTargetLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'effectiveProteinTarget',
        value: value,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition>
      effectiveProteinTargetBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'effectiveProteinTarget',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition>
      effectiveWaterTargetEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'effectiveWaterTarget',
        value: value,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition>
      effectiveWaterTargetGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'effectiveWaterTarget',
        value: value,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition>
      effectiveWaterTargetLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'effectiveWaterTarget',
        value: value,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition>
      effectiveWaterTargetBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'effectiveWaterTarget',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> fatOverrideIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'fatOverride',
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> fatOverrideIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'fatOverride',
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> fatOverrideEqualTo(
      int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fatOverride',
        value: value,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> fatOverrideGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'fatOverride',
        value: value,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> fatOverrideLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'fatOverride',
        value: value,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> fatOverrideBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'fatOverride',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> fatTargetGEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fatTargetG',
        value: value,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> fatTargetGGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'fatTargetG',
        value: value,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> fatTargetGLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'fatTargetG',
        value: value,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> fatTargetGBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'fatTargetG',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> fiberOverrideIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'fiberOverride',
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition>
      fiberOverrideIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'fiberOverride',
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> fiberOverrideEqualTo(
      int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fiberOverride',
        value: value,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition>
      fiberOverrideGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'fiberOverride',
        value: value,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> fiberOverrideLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'fiberOverride',
        value: value,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> fiberOverrideBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'fiberOverride',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> fiberTargetGEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fiberTargetG',
        value: value,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> fiberTargetGGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'fiberTargetG',
        value: value,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> fiberTargetGLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'fiberTargetG',
        value: value,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> fiberTargetGBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'fiberTargetG',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> genderEqualTo(
    Gender value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'gender',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> genderGreaterThan(
    Gender value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'gender',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> genderLessThan(
    Gender value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'gender',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> genderBetween(
    Gender lower,
    Gender upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'gender',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> genderStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'gender',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> genderEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'gender',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> genderContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'gender',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> genderMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'gender',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> genderIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'gender',
        value: '',
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> genderIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'gender',
        value: '',
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> goalEqualTo(
    FitnessGoal value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'goal',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> goalGreaterThan(
    FitnessGoal value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'goal',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> goalLessThan(
    FitnessGoal value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'goal',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> goalBetween(
    FitnessGoal lower,
    FitnessGoal upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'goal',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> goalStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'goal',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> goalEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'goal',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> goalContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'goal',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> goalMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'goal',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> goalIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'goal',
        value: '',
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> goalIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'goal',
        value: '',
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> goesGymEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'goesGym',
        value: value,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition>
      gymMinutesPerSessionEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'gymMinutesPerSession',
        value: value,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition>
      gymMinutesPerSessionGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'gymMinutesPerSession',
        value: value,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition>
      gymMinutesPerSessionLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'gymMinutesPerSession',
        value: value,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition>
      gymMinutesPerSessionBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'gymMinutesPerSession',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> gymStartDateIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'gymStartDate',
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition>
      gymStartDateIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'gymStartDate',
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> gymStartDateEqualTo(
      DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'gymStartDate',
        value: value,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> gymStartDateGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'gymStartDate',
        value: value,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> gymStartDateLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'gymStartDate',
        value: value,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> gymStartDateBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'gymStartDate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition>
      healthFlagsElementEqualTo(
    HealthFlag value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'healthFlags',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition>
      healthFlagsElementGreaterThan(
    HealthFlag value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'healthFlags',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition>
      healthFlagsElementLessThan(
    HealthFlag value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'healthFlags',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition>
      healthFlagsElementBetween(
    HealthFlag lower,
    HealthFlag upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'healthFlags',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition>
      healthFlagsElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'healthFlags',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition>
      healthFlagsElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'healthFlags',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition>
      healthFlagsElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'healthFlags',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition>
      healthFlagsElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'healthFlags',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition>
      healthFlagsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'healthFlags',
        value: '',
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition>
      healthFlagsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'healthFlags',
        value: '',
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition>
      healthFlagsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'healthFlags',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> healthFlagsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'healthFlags',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition>
      healthFlagsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'healthFlags',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition>
      healthFlagsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'healthFlags',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition>
      healthFlagsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'healthFlags',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition>
      healthFlagsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'healthFlags',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> heightCmEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'heightCm',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> heightCmGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'heightCm',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> heightCmLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'heightCm',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> heightCmBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'heightCm',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> multivitaminEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'multivitamin',
        value: value,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition>
      otherSupplementsNoteEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'otherSupplementsNote',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition>
      otherSupplementsNoteGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'otherSupplementsNote',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition>
      otherSupplementsNoteLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'otherSupplementsNote',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition>
      otherSupplementsNoteBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'otherSupplementsNote',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition>
      otherSupplementsNoteStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'otherSupplementsNote',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition>
      otherSupplementsNoteEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'otherSupplementsNote',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition>
      otherSupplementsNoteContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'otherSupplementsNote',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition>
      otherSupplementsNoteMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'otherSupplementsNote',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition>
      otherSupplementsNoteIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'otherSupplementsNote',
        value: '',
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition>
      otherSupplementsNoteIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'otherSupplementsNote',
        value: '',
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition>
      proteinOverrideIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'proteinOverride',
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition>
      proteinOverrideIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'proteinOverride',
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> proteinOverrideEqualTo(
      int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'proteinOverride',
        value: value,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition>
      proteinOverrideGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'proteinOverride',
        value: value,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> proteinOverrideLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'proteinOverride',
        value: value,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> proteinOverrideBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'proteinOverride',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition>
      proteinScoopsPerDayEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'proteinScoopsPerDay',
        value: value,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition>
      proteinScoopsPerDayGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'proteinScoopsPerDay',
        value: value,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition>
      proteinScoopsPerDayLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'proteinScoopsPerDay',
        value: value,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition>
      proteinScoopsPerDayBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'proteinScoopsPerDay',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> proteinTargetGEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'proteinTargetG',
        value: value,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition>
      proteinTargetGGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'proteinTargetG',
        value: value,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> proteinTargetGLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'proteinTargetG',
        value: value,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> proteinTargetGBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'proteinTargetG',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> restDaysElementEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'restDays',
        value: value,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition>
      restDaysElementGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'restDays',
        value: value,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> restDaysElementLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'restDays',
        value: value,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> restDaysElementBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'restDays',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> restDaysLengthEqualTo(
      int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'restDays',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> restDaysIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'restDays',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> restDaysIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'restDays',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> restDaysLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'restDays',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition>
      restDaysLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'restDays',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> restDaysLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'restDays',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> runningKmPerWeekEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'runningKmPerWeek',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition>
      runningKmPerWeekGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'runningKmPerWeek',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition>
      runningKmPerWeekLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'runningKmPerWeek',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> runningKmPerWeekBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'runningKmPerWeek',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> sleepTimeMinEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sleepTimeMin',
        value: value,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> sleepTimeMinGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'sleepTimeMin',
        value: value,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> sleepTimeMinLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'sleepTimeMin',
        value: value,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> sleepTimeMinBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'sleepTimeMin',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> tdeeEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'tdee',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> tdeeGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'tdee',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> tdeeLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'tdee',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> tdeeBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'tdee',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition>
      trainingDaysPerWeekEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'trainingDaysPerWeek',
        value: value,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition>
      trainingDaysPerWeekGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'trainingDaysPerWeek',
        value: value,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition>
      trainingDaysPerWeekLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'trainingDaysPerWeek',
        value: value,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition>
      trainingDaysPerWeekBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'trainingDaysPerWeek',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> updatedAtEqualTo(
      DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> updatedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> updatedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> updatedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'updatedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> wakeTimeMinEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'wakeTimeMin',
        value: value,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> wakeTimeMinGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'wakeTimeMin',
        value: value,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> wakeTimeMinLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'wakeTimeMin',
        value: value,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> wakeTimeMinBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'wakeTimeMin',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> walkingKmPerDayEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'walkingKmPerDay',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition>
      walkingKmPerDayGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'walkingKmPerDay',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> walkingKmPerDayLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'walkingKmPerDay',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> walkingKmPerDayBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'walkingKmPerDay',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> waterOverrideIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'waterOverride',
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition>
      waterOverrideIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'waterOverride',
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> waterOverrideEqualTo(
      int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'waterOverride',
        value: value,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition>
      waterOverrideGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'waterOverride',
        value: value,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> waterOverrideLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'waterOverride',
        value: value,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> waterOverrideBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'waterOverride',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> waterTargetMlEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'waterTargetMl',
        value: value,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition>
      waterTargetMlGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'waterTargetMl',
        value: value,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> waterTargetMlLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'waterTargetMl',
        value: value,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> waterTargetMlBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'waterTargetMl',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> weighInCadenceEqualTo(
    WeighInCadence value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'weighInCadence',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition>
      weighInCadenceGreaterThan(
    WeighInCadence value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'weighInCadence',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> weighInCadenceLessThan(
    WeighInCadence value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'weighInCadence',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> weighInCadenceBetween(
    WeighInCadence lower,
    WeighInCadence upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'weighInCadence',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition>
      weighInCadenceStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'weighInCadence',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> weighInCadenceEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'weighInCadence',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> weighInCadenceContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'weighInCadence',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> weighInCadenceMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'weighInCadence',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition>
      weighInCadenceIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'weighInCadence',
        value: '',
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition>
      weighInCadenceIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'weighInCadence',
        value: '',
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> weighInWeekdayIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'weighInWeekday',
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition>
      weighInWeekdayIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'weighInWeekday',
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> weighInWeekdayEqualTo(
      int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'weighInWeekday',
        value: value,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition>
      weighInWeekdayGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'weighInWeekday',
        value: value,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> weighInWeekdayLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'weighInWeekday',
        value: value,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> weighInWeekdayBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'weighInWeekday',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> weightKgEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'weightKg',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> weightKgGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'weightKg',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> weightKgLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'weightKg',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Profile, Profile, QAfterFilterCondition> weightKgBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'weightKg',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }
}

extension ProfileQueryObject
    on QueryBuilder<Profile, Profile, QFilterCondition> {}

extension ProfileQueryLinks
    on QueryBuilder<Profile, Profile, QFilterCondition> {}

extension ProfileQuerySortBy on QueryBuilder<Profile, Profile, QSortBy> {
  QueryBuilder<Profile, Profile, QAfterSortBy> sortByActivityLevel() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'activityLevel', Sort.asc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> sortByActivityLevelDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'activityLevel', Sort.desc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> sortByAge() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'age', Sort.asc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> sortByAgeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'age', Sort.desc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> sortByBmi() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bmi', Sort.asc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> sortByBmiDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bmi', Sort.desc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> sortByBmr() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bmr', Sort.asc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> sortByBmrDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bmr', Sort.desc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> sortByBodyFatPct() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bodyFatPct', Sort.asc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> sortByBodyFatPctDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bodyFatPct', Sort.desc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> sortByBodyFocusNotes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bodyFocusNotes', Sort.asc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> sortByBodyFocusNotesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bodyFocusNotes', Sort.desc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> sortByCalorieOverride() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'calorieOverride', Sort.asc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> sortByCalorieOverrideDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'calorieOverride', Sort.desc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> sortByCalorieTarget() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'calorieTarget', Sort.asc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> sortByCalorieTargetDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'calorieTarget', Sort.desc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> sortByCarbOverride() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'carbOverride', Sort.asc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> sortByCarbOverrideDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'carbOverride', Sort.desc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> sortByCarbTargetG() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'carbTargetG', Sort.asc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> sortByCarbTargetGDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'carbTargetG', Sort.desc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> sortByCardioSessionsPerWeek() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cardioSessionsPerWeek', Sort.asc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy>
      sortByCardioSessionsPerWeekDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cardioSessionsPerWeek', Sort.desc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> sortByCreatineGramsPerDay() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'creatineGramsPerDay', Sort.asc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> sortByCreatineGramsPerDayDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'creatineGramsPerDay', Sort.desc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> sortByCyclePhase() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cyclePhase', Sort.asc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> sortByCyclePhaseDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cyclePhase', Sort.desc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> sortByDisplayName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'displayName', Sort.asc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> sortByDisplayNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'displayName', Sort.desc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> sortByEffectiveCalorieTarget() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'effectiveCalorieTarget', Sort.asc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy>
      sortByEffectiveCalorieTargetDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'effectiveCalorieTarget', Sort.desc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> sortByEffectiveCarbTarget() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'effectiveCarbTarget', Sort.asc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> sortByEffectiveCarbTargetDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'effectiveCarbTarget', Sort.desc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> sortByEffectiveFatTarget() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'effectiveFatTarget', Sort.asc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> sortByEffectiveFatTargetDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'effectiveFatTarget', Sort.desc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> sortByEffectiveFiberTarget() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'effectiveFiberTarget', Sort.asc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy>
      sortByEffectiveFiberTargetDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'effectiveFiberTarget', Sort.desc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> sortByEffectiveProteinTarget() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'effectiveProteinTarget', Sort.asc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy>
      sortByEffectiveProteinTargetDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'effectiveProteinTarget', Sort.desc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> sortByEffectiveWaterTarget() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'effectiveWaterTarget', Sort.asc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy>
      sortByEffectiveWaterTargetDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'effectiveWaterTarget', Sort.desc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> sortByFatOverride() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fatOverride', Sort.asc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> sortByFatOverrideDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fatOverride', Sort.desc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> sortByFatTargetG() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fatTargetG', Sort.asc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> sortByFatTargetGDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fatTargetG', Sort.desc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> sortByFiberOverride() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fiberOverride', Sort.asc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> sortByFiberOverrideDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fiberOverride', Sort.desc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> sortByFiberTargetG() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fiberTargetG', Sort.asc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> sortByFiberTargetGDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fiberTargetG', Sort.desc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> sortByGender() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gender', Sort.asc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> sortByGenderDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gender', Sort.desc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> sortByGoal() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'goal', Sort.asc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> sortByGoalDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'goal', Sort.desc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> sortByGoesGym() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'goesGym', Sort.asc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> sortByGoesGymDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'goesGym', Sort.desc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> sortByGymMinutesPerSession() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gymMinutesPerSession', Sort.asc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy>
      sortByGymMinutesPerSessionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gymMinutesPerSession', Sort.desc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> sortByGymStartDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gymStartDate', Sort.asc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> sortByGymStartDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gymStartDate', Sort.desc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> sortByHeightCm() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'heightCm', Sort.asc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> sortByHeightCmDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'heightCm', Sort.desc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> sortByMultivitamin() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'multivitamin', Sort.asc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> sortByMultivitaminDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'multivitamin', Sort.desc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> sortByOtherSupplementsNote() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'otherSupplementsNote', Sort.asc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy>
      sortByOtherSupplementsNoteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'otherSupplementsNote', Sort.desc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> sortByProteinOverride() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'proteinOverride', Sort.asc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> sortByProteinOverrideDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'proteinOverride', Sort.desc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> sortByProteinScoopsPerDay() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'proteinScoopsPerDay', Sort.asc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> sortByProteinScoopsPerDayDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'proteinScoopsPerDay', Sort.desc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> sortByProteinTargetG() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'proteinTargetG', Sort.asc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> sortByProteinTargetGDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'proteinTargetG', Sort.desc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> sortByRunningKmPerWeek() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'runningKmPerWeek', Sort.asc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> sortByRunningKmPerWeekDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'runningKmPerWeek', Sort.desc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> sortBySleepTimeMin() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sleepTimeMin', Sort.asc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> sortBySleepTimeMinDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sleepTimeMin', Sort.desc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> sortByTdee() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tdee', Sort.asc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> sortByTdeeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tdee', Sort.desc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> sortByTrainingDaysPerWeek() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'trainingDaysPerWeek', Sort.asc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> sortByTrainingDaysPerWeekDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'trainingDaysPerWeek', Sort.desc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> sortByWakeTimeMin() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'wakeTimeMin', Sort.asc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> sortByWakeTimeMinDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'wakeTimeMin', Sort.desc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> sortByWalkingKmPerDay() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'walkingKmPerDay', Sort.asc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> sortByWalkingKmPerDayDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'walkingKmPerDay', Sort.desc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> sortByWaterOverride() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'waterOverride', Sort.asc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> sortByWaterOverrideDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'waterOverride', Sort.desc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> sortByWaterTargetMl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'waterTargetMl', Sort.asc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> sortByWaterTargetMlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'waterTargetMl', Sort.desc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> sortByWeighInCadence() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weighInCadence', Sort.asc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> sortByWeighInCadenceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weighInCadence', Sort.desc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> sortByWeighInWeekday() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weighInWeekday', Sort.asc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> sortByWeighInWeekdayDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weighInWeekday', Sort.desc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> sortByWeightKg() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weightKg', Sort.asc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> sortByWeightKgDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weightKg', Sort.desc);
    });
  }
}

extension ProfileQuerySortThenBy
    on QueryBuilder<Profile, Profile, QSortThenBy> {
  QueryBuilder<Profile, Profile, QAfterSortBy> thenByActivityLevel() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'activityLevel', Sort.asc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> thenByActivityLevelDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'activityLevel', Sort.desc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> thenByAge() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'age', Sort.asc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> thenByAgeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'age', Sort.desc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> thenByBmi() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bmi', Sort.asc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> thenByBmiDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bmi', Sort.desc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> thenByBmr() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bmr', Sort.asc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> thenByBmrDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bmr', Sort.desc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> thenByBodyFatPct() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bodyFatPct', Sort.asc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> thenByBodyFatPctDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bodyFatPct', Sort.desc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> thenByBodyFocusNotes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bodyFocusNotes', Sort.asc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> thenByBodyFocusNotesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bodyFocusNotes', Sort.desc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> thenByCalorieOverride() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'calorieOverride', Sort.asc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> thenByCalorieOverrideDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'calorieOverride', Sort.desc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> thenByCalorieTarget() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'calorieTarget', Sort.asc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> thenByCalorieTargetDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'calorieTarget', Sort.desc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> thenByCarbOverride() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'carbOverride', Sort.asc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> thenByCarbOverrideDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'carbOverride', Sort.desc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> thenByCarbTargetG() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'carbTargetG', Sort.asc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> thenByCarbTargetGDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'carbTargetG', Sort.desc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> thenByCardioSessionsPerWeek() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cardioSessionsPerWeek', Sort.asc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy>
      thenByCardioSessionsPerWeekDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cardioSessionsPerWeek', Sort.desc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> thenByCreatineGramsPerDay() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'creatineGramsPerDay', Sort.asc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> thenByCreatineGramsPerDayDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'creatineGramsPerDay', Sort.desc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> thenByCyclePhase() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cyclePhase', Sort.asc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> thenByCyclePhaseDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cyclePhase', Sort.desc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> thenByDisplayName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'displayName', Sort.asc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> thenByDisplayNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'displayName', Sort.desc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> thenByEffectiveCalorieTarget() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'effectiveCalorieTarget', Sort.asc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy>
      thenByEffectiveCalorieTargetDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'effectiveCalorieTarget', Sort.desc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> thenByEffectiveCarbTarget() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'effectiveCarbTarget', Sort.asc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> thenByEffectiveCarbTargetDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'effectiveCarbTarget', Sort.desc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> thenByEffectiveFatTarget() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'effectiveFatTarget', Sort.asc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> thenByEffectiveFatTargetDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'effectiveFatTarget', Sort.desc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> thenByEffectiveFiberTarget() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'effectiveFiberTarget', Sort.asc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy>
      thenByEffectiveFiberTargetDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'effectiveFiberTarget', Sort.desc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> thenByEffectiveProteinTarget() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'effectiveProteinTarget', Sort.asc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy>
      thenByEffectiveProteinTargetDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'effectiveProteinTarget', Sort.desc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> thenByEffectiveWaterTarget() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'effectiveWaterTarget', Sort.asc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy>
      thenByEffectiveWaterTargetDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'effectiveWaterTarget', Sort.desc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> thenByFatOverride() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fatOverride', Sort.asc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> thenByFatOverrideDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fatOverride', Sort.desc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> thenByFatTargetG() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fatTargetG', Sort.asc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> thenByFatTargetGDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fatTargetG', Sort.desc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> thenByFiberOverride() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fiberOverride', Sort.asc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> thenByFiberOverrideDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fiberOverride', Sort.desc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> thenByFiberTargetG() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fiberTargetG', Sort.asc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> thenByFiberTargetGDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fiberTargetG', Sort.desc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> thenByGender() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gender', Sort.asc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> thenByGenderDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gender', Sort.desc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> thenByGoal() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'goal', Sort.asc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> thenByGoalDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'goal', Sort.desc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> thenByGoesGym() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'goesGym', Sort.asc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> thenByGoesGymDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'goesGym', Sort.desc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> thenByGymMinutesPerSession() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gymMinutesPerSession', Sort.asc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy>
      thenByGymMinutesPerSessionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gymMinutesPerSession', Sort.desc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> thenByGymStartDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gymStartDate', Sort.asc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> thenByGymStartDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gymStartDate', Sort.desc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> thenByHeightCm() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'heightCm', Sort.asc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> thenByHeightCmDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'heightCm', Sort.desc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> thenByMultivitamin() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'multivitamin', Sort.asc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> thenByMultivitaminDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'multivitamin', Sort.desc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> thenByOtherSupplementsNote() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'otherSupplementsNote', Sort.asc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy>
      thenByOtherSupplementsNoteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'otherSupplementsNote', Sort.desc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> thenByProteinOverride() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'proteinOverride', Sort.asc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> thenByProteinOverrideDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'proteinOverride', Sort.desc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> thenByProteinScoopsPerDay() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'proteinScoopsPerDay', Sort.asc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> thenByProteinScoopsPerDayDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'proteinScoopsPerDay', Sort.desc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> thenByProteinTargetG() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'proteinTargetG', Sort.asc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> thenByProteinTargetGDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'proteinTargetG', Sort.desc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> thenByRunningKmPerWeek() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'runningKmPerWeek', Sort.asc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> thenByRunningKmPerWeekDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'runningKmPerWeek', Sort.desc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> thenBySleepTimeMin() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sleepTimeMin', Sort.asc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> thenBySleepTimeMinDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sleepTimeMin', Sort.desc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> thenByTdee() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tdee', Sort.asc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> thenByTdeeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tdee', Sort.desc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> thenByTrainingDaysPerWeek() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'trainingDaysPerWeek', Sort.asc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> thenByTrainingDaysPerWeekDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'trainingDaysPerWeek', Sort.desc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> thenByWakeTimeMin() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'wakeTimeMin', Sort.asc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> thenByWakeTimeMinDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'wakeTimeMin', Sort.desc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> thenByWalkingKmPerDay() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'walkingKmPerDay', Sort.asc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> thenByWalkingKmPerDayDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'walkingKmPerDay', Sort.desc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> thenByWaterOverride() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'waterOverride', Sort.asc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> thenByWaterOverrideDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'waterOverride', Sort.desc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> thenByWaterTargetMl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'waterTargetMl', Sort.asc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> thenByWaterTargetMlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'waterTargetMl', Sort.desc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> thenByWeighInCadence() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weighInCadence', Sort.asc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> thenByWeighInCadenceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weighInCadence', Sort.desc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> thenByWeighInWeekday() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weighInWeekday', Sort.asc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> thenByWeighInWeekdayDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weighInWeekday', Sort.desc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> thenByWeightKg() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weightKg', Sort.asc);
    });
  }

  QueryBuilder<Profile, Profile, QAfterSortBy> thenByWeightKgDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weightKg', Sort.desc);
    });
  }
}

extension ProfileQueryWhereDistinct
    on QueryBuilder<Profile, Profile, QDistinct> {
  QueryBuilder<Profile, Profile, QDistinct> distinctByActivityLevel(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'activityLevel',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Profile, Profile, QDistinct> distinctByAge() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'age');
    });
  }

  QueryBuilder<Profile, Profile, QDistinct> distinctByBmi() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'bmi');
    });
  }

  QueryBuilder<Profile, Profile, QDistinct> distinctByBmr() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'bmr');
    });
  }

  QueryBuilder<Profile, Profile, QDistinct> distinctByBodyFatPct() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'bodyFatPct');
    });
  }

  QueryBuilder<Profile, Profile, QDistinct> distinctByBodyFocusNotes(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'bodyFocusNotes',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Profile, Profile, QDistinct> distinctByCalorieOverride() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'calorieOverride');
    });
  }

  QueryBuilder<Profile, Profile, QDistinct> distinctByCalorieTarget() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'calorieTarget');
    });
  }

  QueryBuilder<Profile, Profile, QDistinct> distinctByCarbOverride() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'carbOverride');
    });
  }

  QueryBuilder<Profile, Profile, QDistinct> distinctByCarbTargetG() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'carbTargetG');
    });
  }

  QueryBuilder<Profile, Profile, QDistinct> distinctByCardioSessionsPerWeek() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'cardioSessionsPerWeek');
    });
  }

  QueryBuilder<Profile, Profile, QDistinct> distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<Profile, Profile, QDistinct> distinctByCreatineGramsPerDay() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'creatineGramsPerDay');
    });
  }

  QueryBuilder<Profile, Profile, QDistinct> distinctByCyclePhase(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'cyclePhase', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Profile, Profile, QDistinct> distinctByDisplayName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'displayName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Profile, Profile, QDistinct> distinctByEffectiveCalorieTarget() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'effectiveCalorieTarget');
    });
  }

  QueryBuilder<Profile, Profile, QDistinct> distinctByEffectiveCarbTarget() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'effectiveCarbTarget');
    });
  }

  QueryBuilder<Profile, Profile, QDistinct> distinctByEffectiveFatTarget() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'effectiveFatTarget');
    });
  }

  QueryBuilder<Profile, Profile, QDistinct> distinctByEffectiveFiberTarget() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'effectiveFiberTarget');
    });
  }

  QueryBuilder<Profile, Profile, QDistinct> distinctByEffectiveProteinTarget() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'effectiveProteinTarget');
    });
  }

  QueryBuilder<Profile, Profile, QDistinct> distinctByEffectiveWaterTarget() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'effectiveWaterTarget');
    });
  }

  QueryBuilder<Profile, Profile, QDistinct> distinctByFatOverride() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'fatOverride');
    });
  }

  QueryBuilder<Profile, Profile, QDistinct> distinctByFatTargetG() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'fatTargetG');
    });
  }

  QueryBuilder<Profile, Profile, QDistinct> distinctByFiberOverride() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'fiberOverride');
    });
  }

  QueryBuilder<Profile, Profile, QDistinct> distinctByFiberTargetG() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'fiberTargetG');
    });
  }

  QueryBuilder<Profile, Profile, QDistinct> distinctByGender(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'gender', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Profile, Profile, QDistinct> distinctByGoal(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'goal', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Profile, Profile, QDistinct> distinctByGoesGym() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'goesGym');
    });
  }

  QueryBuilder<Profile, Profile, QDistinct> distinctByGymMinutesPerSession() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'gymMinutesPerSession');
    });
  }

  QueryBuilder<Profile, Profile, QDistinct> distinctByGymStartDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'gymStartDate');
    });
  }

  QueryBuilder<Profile, Profile, QDistinct> distinctByHealthFlags() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'healthFlags');
    });
  }

  QueryBuilder<Profile, Profile, QDistinct> distinctByHeightCm() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'heightCm');
    });
  }

  QueryBuilder<Profile, Profile, QDistinct> distinctByMultivitamin() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'multivitamin');
    });
  }

  QueryBuilder<Profile, Profile, QDistinct> distinctByOtherSupplementsNote(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'otherSupplementsNote',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Profile, Profile, QDistinct> distinctByProteinOverride() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'proteinOverride');
    });
  }

  QueryBuilder<Profile, Profile, QDistinct> distinctByProteinScoopsPerDay() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'proteinScoopsPerDay');
    });
  }

  QueryBuilder<Profile, Profile, QDistinct> distinctByProteinTargetG() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'proteinTargetG');
    });
  }

  QueryBuilder<Profile, Profile, QDistinct> distinctByRestDays() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'restDays');
    });
  }

  QueryBuilder<Profile, Profile, QDistinct> distinctByRunningKmPerWeek() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'runningKmPerWeek');
    });
  }

  QueryBuilder<Profile, Profile, QDistinct> distinctBySleepTimeMin() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sleepTimeMin');
    });
  }

  QueryBuilder<Profile, Profile, QDistinct> distinctByTdee() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'tdee');
    });
  }

  QueryBuilder<Profile, Profile, QDistinct> distinctByTrainingDaysPerWeek() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'trainingDaysPerWeek');
    });
  }

  QueryBuilder<Profile, Profile, QDistinct> distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }

  QueryBuilder<Profile, Profile, QDistinct> distinctByWakeTimeMin() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'wakeTimeMin');
    });
  }

  QueryBuilder<Profile, Profile, QDistinct> distinctByWalkingKmPerDay() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'walkingKmPerDay');
    });
  }

  QueryBuilder<Profile, Profile, QDistinct> distinctByWaterOverride() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'waterOverride');
    });
  }

  QueryBuilder<Profile, Profile, QDistinct> distinctByWaterTargetMl() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'waterTargetMl');
    });
  }

  QueryBuilder<Profile, Profile, QDistinct> distinctByWeighInCadence(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'weighInCadence',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Profile, Profile, QDistinct> distinctByWeighInWeekday() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'weighInWeekday');
    });
  }

  QueryBuilder<Profile, Profile, QDistinct> distinctByWeightKg() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'weightKg');
    });
  }
}

extension ProfileQueryProperty
    on QueryBuilder<Profile, Profile, QQueryProperty> {
  QueryBuilder<Profile, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<Profile, ActivityLevel, QQueryOperations>
      activityLevelProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'activityLevel');
    });
  }

  QueryBuilder<Profile, int, QQueryOperations> ageProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'age');
    });
  }

  QueryBuilder<Profile, double, QQueryOperations> bmiProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'bmi');
    });
  }

  QueryBuilder<Profile, double, QQueryOperations> bmrProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'bmr');
    });
  }

  QueryBuilder<Profile, double?, QQueryOperations> bodyFatPctProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'bodyFatPct');
    });
  }

  QueryBuilder<Profile, String, QQueryOperations> bodyFocusNotesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'bodyFocusNotes');
    });
  }

  QueryBuilder<Profile, int?, QQueryOperations> calorieOverrideProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'calorieOverride');
    });
  }

  QueryBuilder<Profile, int, QQueryOperations> calorieTargetProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'calorieTarget');
    });
  }

  QueryBuilder<Profile, int?, QQueryOperations> carbOverrideProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'carbOverride');
    });
  }

  QueryBuilder<Profile, int, QQueryOperations> carbTargetGProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'carbTargetG');
    });
  }

  QueryBuilder<Profile, int, QQueryOperations> cardioSessionsPerWeekProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'cardioSessionsPerWeek');
    });
  }

  QueryBuilder<Profile, DateTime, QQueryOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<Profile, int, QQueryOperations> creatineGramsPerDayProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'creatineGramsPerDay');
    });
  }

  QueryBuilder<Profile, CyclePhase, QQueryOperations> cyclePhaseProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'cyclePhase');
    });
  }

  QueryBuilder<Profile, String, QQueryOperations> displayNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'displayName');
    });
  }

  QueryBuilder<Profile, int, QQueryOperations>
      effectiveCalorieTargetProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'effectiveCalorieTarget');
    });
  }

  QueryBuilder<Profile, int, QQueryOperations> effectiveCarbTargetProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'effectiveCarbTarget');
    });
  }

  QueryBuilder<Profile, int, QQueryOperations> effectiveFatTargetProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'effectiveFatTarget');
    });
  }

  QueryBuilder<Profile, int, QQueryOperations> effectiveFiberTargetProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'effectiveFiberTarget');
    });
  }

  QueryBuilder<Profile, int, QQueryOperations>
      effectiveProteinTargetProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'effectiveProteinTarget');
    });
  }

  QueryBuilder<Profile, int, QQueryOperations> effectiveWaterTargetProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'effectiveWaterTarget');
    });
  }

  QueryBuilder<Profile, int?, QQueryOperations> fatOverrideProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'fatOverride');
    });
  }

  QueryBuilder<Profile, int, QQueryOperations> fatTargetGProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'fatTargetG');
    });
  }

  QueryBuilder<Profile, int?, QQueryOperations> fiberOverrideProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'fiberOverride');
    });
  }

  QueryBuilder<Profile, int, QQueryOperations> fiberTargetGProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'fiberTargetG');
    });
  }

  QueryBuilder<Profile, Gender, QQueryOperations> genderProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'gender');
    });
  }

  QueryBuilder<Profile, FitnessGoal, QQueryOperations> goalProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'goal');
    });
  }

  QueryBuilder<Profile, bool, QQueryOperations> goesGymProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'goesGym');
    });
  }

  QueryBuilder<Profile, int, QQueryOperations> gymMinutesPerSessionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'gymMinutesPerSession');
    });
  }

  QueryBuilder<Profile, DateTime?, QQueryOperations> gymStartDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'gymStartDate');
    });
  }

  QueryBuilder<Profile, List<HealthFlag>, QQueryOperations>
      healthFlagsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'healthFlags');
    });
  }

  QueryBuilder<Profile, double, QQueryOperations> heightCmProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'heightCm');
    });
  }

  QueryBuilder<Profile, bool, QQueryOperations> multivitaminProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'multivitamin');
    });
  }

  QueryBuilder<Profile, String, QQueryOperations>
      otherSupplementsNoteProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'otherSupplementsNote');
    });
  }

  QueryBuilder<Profile, int?, QQueryOperations> proteinOverrideProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'proteinOverride');
    });
  }

  QueryBuilder<Profile, int, QQueryOperations> proteinScoopsPerDayProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'proteinScoopsPerDay');
    });
  }

  QueryBuilder<Profile, int, QQueryOperations> proteinTargetGProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'proteinTargetG');
    });
  }

  QueryBuilder<Profile, List<int>, QQueryOperations> restDaysProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'restDays');
    });
  }

  QueryBuilder<Profile, double, QQueryOperations> runningKmPerWeekProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'runningKmPerWeek');
    });
  }

  QueryBuilder<Profile, int, QQueryOperations> sleepTimeMinProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sleepTimeMin');
    });
  }

  QueryBuilder<Profile, double, QQueryOperations> tdeeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'tdee');
    });
  }

  QueryBuilder<Profile, int, QQueryOperations> trainingDaysPerWeekProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'trainingDaysPerWeek');
    });
  }

  QueryBuilder<Profile, DateTime, QQueryOperations> updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }

  QueryBuilder<Profile, int, QQueryOperations> wakeTimeMinProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'wakeTimeMin');
    });
  }

  QueryBuilder<Profile, double, QQueryOperations> walkingKmPerDayProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'walkingKmPerDay');
    });
  }

  QueryBuilder<Profile, int?, QQueryOperations> waterOverrideProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'waterOverride');
    });
  }

  QueryBuilder<Profile, int, QQueryOperations> waterTargetMlProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'waterTargetMl');
    });
  }

  QueryBuilder<Profile, WeighInCadence, QQueryOperations>
      weighInCadenceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'weighInCadence');
    });
  }

  QueryBuilder<Profile, int?, QQueryOperations> weighInWeekdayProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'weighInWeekday');
    });
  }

  QueryBuilder<Profile, double, QQueryOperations> weightKgProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'weightKg');
    });
  }
}
