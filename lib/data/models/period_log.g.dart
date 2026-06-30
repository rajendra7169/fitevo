// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'period_log.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetPeriodLogCollection on Isar {
  IsarCollection<PeriodLog> get periodLogs => this.collection();
}

const PeriodLogSchema = CollectionSchema(
  name: r'PeriodLog',
  id: 5791160629672514608,
  properties: {
    r'createdAt': PropertySchema(
      id: 0,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'date': PropertySchema(
      id: 1,
      name: r'date',
      type: IsarType.dateTime,
    ),
    r'dateKey': PropertySchema(
      id: 2,
      name: r'dateKey',
      type: IsarType.string,
    ),
    r'flow': PropertySchema(
      id: 3,
      name: r'flow',
      type: IsarType.string,
      enumMap: _PeriodLogflowEnumValueMap,
    ),
    r'notes': PropertySchema(
      id: 4,
      name: r'notes',
      type: IsarType.string,
    ),
    r'symptoms': PropertySchema(
      id: 5,
      name: r'symptoms',
      type: IsarType.stringList,
      enumMap: _PeriodLogsymptomsEnumValueMap,
    ),
    r'updatedAt': PropertySchema(
      id: 6,
      name: r'updatedAt',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _periodLogEstimateSize,
  serialize: _periodLogSerialize,
  deserialize: _periodLogDeserialize,
  deserializeProp: _periodLogDeserializeProp,
  idName: r'id',
  indexes: {
    r'dateKey': IndexSchema(
      id: 7975223786082927131,
      name: r'dateKey',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'dateKey',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _periodLogGetId,
  getLinks: _periodLogGetLinks,
  attach: _periodLogAttach,
  version: '3.1.0+1',
);

int _periodLogEstimateSize(
  PeriodLog object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.dateKey.length * 3;
  bytesCount += 3 + object.flow.name.length * 3;
  bytesCount += 3 + object.notes.length * 3;
  bytesCount += 3 + object.symptoms.length * 3;
  {
    for (var i = 0; i < object.symptoms.length; i++) {
      final value = object.symptoms[i];
      bytesCount += value.name.length * 3;
    }
  }
  return bytesCount;
}

void _periodLogSerialize(
  PeriodLog object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.createdAt);
  writer.writeDateTime(offsets[1], object.date);
  writer.writeString(offsets[2], object.dateKey);
  writer.writeString(offsets[3], object.flow.name);
  writer.writeString(offsets[4], object.notes);
  writer.writeStringList(
      offsets[5], object.symptoms.map((e) => e.name).toList());
  writer.writeDateTime(offsets[6], object.updatedAt);
}

PeriodLog _periodLogDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = PeriodLog();
  object.createdAt = reader.readDateTime(offsets[0]);
  object.date = reader.readDateTime(offsets[1]);
  object.dateKey = reader.readString(offsets[2]);
  object.flow =
      _PeriodLogflowValueEnumMap[reader.readStringOrNull(offsets[3])] ??
          MenstrualFlow.none;
  object.id = id;
  object.notes = reader.readString(offsets[4]);
  object.symptoms = reader
          .readStringList(offsets[5])
          ?.map(
              (e) => _PeriodLogsymptomsValueEnumMap[e] ?? PeriodSymptom.cramps)
          .toList() ??
      [];
  object.updatedAt = reader.readDateTime(offsets[6]);
  return object;
}

P _periodLogDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTime(offset)) as P;
    case 1:
      return (reader.readDateTime(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (_PeriodLogflowValueEnumMap[reader.readStringOrNull(offset)] ??
          MenstrualFlow.none) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader
              .readStringList(offset)
              ?.map((e) =>
                  _PeriodLogsymptomsValueEnumMap[e] ?? PeriodSymptom.cramps)
              .toList() ??
          []) as P;
    case 6:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _PeriodLogflowEnumValueMap = {
  r'none': r'none',
  r'spotting': r'spotting',
  r'light': r'light',
  r'medium': r'medium',
  r'heavy': r'heavy',
};
const _PeriodLogflowValueEnumMap = {
  r'none': MenstrualFlow.none,
  r'spotting': MenstrualFlow.spotting,
  r'light': MenstrualFlow.light,
  r'medium': MenstrualFlow.medium,
  r'heavy': MenstrualFlow.heavy,
};
const _PeriodLogsymptomsEnumValueMap = {
  r'cramps': r'cramps',
  r'headache': r'headache',
  r'bloating': r'bloating',
  r'fatigue': r'fatigue',
  r'moodSwings': r'moodSwings',
  r'backPain': r'backPain',
  r'breastTenderness': r'breastTenderness',
  r'nausea': r'nausea',
  r'acne': r'acne',
  r'cravings': r'cravings',
  r'insomnia': r'insomnia',
};
const _PeriodLogsymptomsValueEnumMap = {
  r'cramps': PeriodSymptom.cramps,
  r'headache': PeriodSymptom.headache,
  r'bloating': PeriodSymptom.bloating,
  r'fatigue': PeriodSymptom.fatigue,
  r'moodSwings': PeriodSymptom.moodSwings,
  r'backPain': PeriodSymptom.backPain,
  r'breastTenderness': PeriodSymptom.breastTenderness,
  r'nausea': PeriodSymptom.nausea,
  r'acne': PeriodSymptom.acne,
  r'cravings': PeriodSymptom.cravings,
  r'insomnia': PeriodSymptom.insomnia,
};

Id _periodLogGetId(PeriodLog object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _periodLogGetLinks(PeriodLog object) {
  return [];
}

void _periodLogAttach(IsarCollection<dynamic> col, Id id, PeriodLog object) {
  object.id = id;
}

extension PeriodLogByIndex on IsarCollection<PeriodLog> {
  Future<PeriodLog?> getByDateKey(String dateKey) {
    return getByIndex(r'dateKey', [dateKey]);
  }

  PeriodLog? getByDateKeySync(String dateKey) {
    return getByIndexSync(r'dateKey', [dateKey]);
  }

  Future<bool> deleteByDateKey(String dateKey) {
    return deleteByIndex(r'dateKey', [dateKey]);
  }

  bool deleteByDateKeySync(String dateKey) {
    return deleteByIndexSync(r'dateKey', [dateKey]);
  }

  Future<List<PeriodLog?>> getAllByDateKey(List<String> dateKeyValues) {
    final values = dateKeyValues.map((e) => [e]).toList();
    return getAllByIndex(r'dateKey', values);
  }

  List<PeriodLog?> getAllByDateKeySync(List<String> dateKeyValues) {
    final values = dateKeyValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'dateKey', values);
  }

  Future<int> deleteAllByDateKey(List<String> dateKeyValues) {
    final values = dateKeyValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'dateKey', values);
  }

  int deleteAllByDateKeySync(List<String> dateKeyValues) {
    final values = dateKeyValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'dateKey', values);
  }

  Future<Id> putByDateKey(PeriodLog object) {
    return putByIndex(r'dateKey', object);
  }

  Id putByDateKeySync(PeriodLog object, {bool saveLinks = true}) {
    return putByIndexSync(r'dateKey', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByDateKey(List<PeriodLog> objects) {
    return putAllByIndex(r'dateKey', objects);
  }

  List<Id> putAllByDateKeySync(List<PeriodLog> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'dateKey', objects, saveLinks: saveLinks);
  }
}

extension PeriodLogQueryWhereSort
    on QueryBuilder<PeriodLog, PeriodLog, QWhere> {
  QueryBuilder<PeriodLog, PeriodLog, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension PeriodLogQueryWhere
    on QueryBuilder<PeriodLog, PeriodLog, QWhereClause> {
  QueryBuilder<PeriodLog, PeriodLog, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<PeriodLog, PeriodLog, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<PeriodLog, PeriodLog, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<PeriodLog, PeriodLog, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<PeriodLog, PeriodLog, QAfterWhereClause> idBetween(
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

  QueryBuilder<PeriodLog, PeriodLog, QAfterWhereClause> dateKeyEqualTo(
      String dateKey) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'dateKey',
        value: [dateKey],
      ));
    });
  }

  QueryBuilder<PeriodLog, PeriodLog, QAfterWhereClause> dateKeyNotEqualTo(
      String dateKey) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'dateKey',
              lower: [],
              upper: [dateKey],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'dateKey',
              lower: [dateKey],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'dateKey',
              lower: [dateKey],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'dateKey',
              lower: [],
              upper: [dateKey],
              includeUpper: false,
            ));
      }
    });
  }
}

extension PeriodLogQueryFilter
    on QueryBuilder<PeriodLog, PeriodLog, QFilterCondition> {
  QueryBuilder<PeriodLog, PeriodLog, QAfterFilterCondition> createdAtEqualTo(
      DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<PeriodLog, PeriodLog, QAfterFilterCondition>
      createdAtGreaterThan(
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

  QueryBuilder<PeriodLog, PeriodLog, QAfterFilterCondition> createdAtLessThan(
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

  QueryBuilder<PeriodLog, PeriodLog, QAfterFilterCondition> createdAtBetween(
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

  QueryBuilder<PeriodLog, PeriodLog, QAfterFilterCondition> dateEqualTo(
      DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'date',
        value: value,
      ));
    });
  }

  QueryBuilder<PeriodLog, PeriodLog, QAfterFilterCondition> dateGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'date',
        value: value,
      ));
    });
  }

  QueryBuilder<PeriodLog, PeriodLog, QAfterFilterCondition> dateLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'date',
        value: value,
      ));
    });
  }

  QueryBuilder<PeriodLog, PeriodLog, QAfterFilterCondition> dateBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'date',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PeriodLog, PeriodLog, QAfterFilterCondition> dateKeyEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dateKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PeriodLog, PeriodLog, QAfterFilterCondition> dateKeyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'dateKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PeriodLog, PeriodLog, QAfterFilterCondition> dateKeyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'dateKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PeriodLog, PeriodLog, QAfterFilterCondition> dateKeyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'dateKey',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PeriodLog, PeriodLog, QAfterFilterCondition> dateKeyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'dateKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PeriodLog, PeriodLog, QAfterFilterCondition> dateKeyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'dateKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PeriodLog, PeriodLog, QAfterFilterCondition> dateKeyContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'dateKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PeriodLog, PeriodLog, QAfterFilterCondition> dateKeyMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'dateKey',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PeriodLog, PeriodLog, QAfterFilterCondition> dateKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dateKey',
        value: '',
      ));
    });
  }

  QueryBuilder<PeriodLog, PeriodLog, QAfterFilterCondition>
      dateKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'dateKey',
        value: '',
      ));
    });
  }

  QueryBuilder<PeriodLog, PeriodLog, QAfterFilterCondition> flowEqualTo(
    MenstrualFlow value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'flow',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PeriodLog, PeriodLog, QAfterFilterCondition> flowGreaterThan(
    MenstrualFlow value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'flow',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PeriodLog, PeriodLog, QAfterFilterCondition> flowLessThan(
    MenstrualFlow value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'flow',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PeriodLog, PeriodLog, QAfterFilterCondition> flowBetween(
    MenstrualFlow lower,
    MenstrualFlow upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'flow',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PeriodLog, PeriodLog, QAfterFilterCondition> flowStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'flow',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PeriodLog, PeriodLog, QAfterFilterCondition> flowEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'flow',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PeriodLog, PeriodLog, QAfterFilterCondition> flowContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'flow',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PeriodLog, PeriodLog, QAfterFilterCondition> flowMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'flow',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PeriodLog, PeriodLog, QAfterFilterCondition> flowIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'flow',
        value: '',
      ));
    });
  }

  QueryBuilder<PeriodLog, PeriodLog, QAfterFilterCondition> flowIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'flow',
        value: '',
      ));
    });
  }

  QueryBuilder<PeriodLog, PeriodLog, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<PeriodLog, PeriodLog, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<PeriodLog, PeriodLog, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<PeriodLog, PeriodLog, QAfterFilterCondition> idBetween(
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

  QueryBuilder<PeriodLog, PeriodLog, QAfterFilterCondition> notesEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PeriodLog, PeriodLog, QAfterFilterCondition> notesGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PeriodLog, PeriodLog, QAfterFilterCondition> notesLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PeriodLog, PeriodLog, QAfterFilterCondition> notesBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'notes',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PeriodLog, PeriodLog, QAfterFilterCondition> notesStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PeriodLog, PeriodLog, QAfterFilterCondition> notesEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PeriodLog, PeriodLog, QAfterFilterCondition> notesContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PeriodLog, PeriodLog, QAfterFilterCondition> notesMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'notes',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PeriodLog, PeriodLog, QAfterFilterCondition> notesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'notes',
        value: '',
      ));
    });
  }

  QueryBuilder<PeriodLog, PeriodLog, QAfterFilterCondition> notesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'notes',
        value: '',
      ));
    });
  }

  QueryBuilder<PeriodLog, PeriodLog, QAfterFilterCondition>
      symptomsElementEqualTo(
    PeriodSymptom value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'symptoms',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PeriodLog, PeriodLog, QAfterFilterCondition>
      symptomsElementGreaterThan(
    PeriodSymptom value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'symptoms',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PeriodLog, PeriodLog, QAfterFilterCondition>
      symptomsElementLessThan(
    PeriodSymptom value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'symptoms',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PeriodLog, PeriodLog, QAfterFilterCondition>
      symptomsElementBetween(
    PeriodSymptom lower,
    PeriodSymptom upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'symptoms',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PeriodLog, PeriodLog, QAfterFilterCondition>
      symptomsElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'symptoms',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PeriodLog, PeriodLog, QAfterFilterCondition>
      symptomsElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'symptoms',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PeriodLog, PeriodLog, QAfterFilterCondition>
      symptomsElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'symptoms',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PeriodLog, PeriodLog, QAfterFilterCondition>
      symptomsElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'symptoms',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PeriodLog, PeriodLog, QAfterFilterCondition>
      symptomsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'symptoms',
        value: '',
      ));
    });
  }

  QueryBuilder<PeriodLog, PeriodLog, QAfterFilterCondition>
      symptomsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'symptoms',
        value: '',
      ));
    });
  }

  QueryBuilder<PeriodLog, PeriodLog, QAfterFilterCondition>
      symptomsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'symptoms',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<PeriodLog, PeriodLog, QAfterFilterCondition> symptomsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'symptoms',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<PeriodLog, PeriodLog, QAfterFilterCondition>
      symptomsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'symptoms',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<PeriodLog, PeriodLog, QAfterFilterCondition>
      symptomsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'symptoms',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<PeriodLog, PeriodLog, QAfterFilterCondition>
      symptomsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'symptoms',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<PeriodLog, PeriodLog, QAfterFilterCondition>
      symptomsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'symptoms',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<PeriodLog, PeriodLog, QAfterFilterCondition> updatedAtEqualTo(
      DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<PeriodLog, PeriodLog, QAfterFilterCondition>
      updatedAtGreaterThan(
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

  QueryBuilder<PeriodLog, PeriodLog, QAfterFilterCondition> updatedAtLessThan(
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

  QueryBuilder<PeriodLog, PeriodLog, QAfterFilterCondition> updatedAtBetween(
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
}

extension PeriodLogQueryObject
    on QueryBuilder<PeriodLog, PeriodLog, QFilterCondition> {}

extension PeriodLogQueryLinks
    on QueryBuilder<PeriodLog, PeriodLog, QFilterCondition> {}

extension PeriodLogQuerySortBy on QueryBuilder<PeriodLog, PeriodLog, QSortBy> {
  QueryBuilder<PeriodLog, PeriodLog, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<PeriodLog, PeriodLog, QAfterSortBy> sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<PeriodLog, PeriodLog, QAfterSortBy> sortByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.asc);
    });
  }

  QueryBuilder<PeriodLog, PeriodLog, QAfterSortBy> sortByDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.desc);
    });
  }

  QueryBuilder<PeriodLog, PeriodLog, QAfterSortBy> sortByDateKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateKey', Sort.asc);
    });
  }

  QueryBuilder<PeriodLog, PeriodLog, QAfterSortBy> sortByDateKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateKey', Sort.desc);
    });
  }

  QueryBuilder<PeriodLog, PeriodLog, QAfterSortBy> sortByFlow() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'flow', Sort.asc);
    });
  }

  QueryBuilder<PeriodLog, PeriodLog, QAfterSortBy> sortByFlowDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'flow', Sort.desc);
    });
  }

  QueryBuilder<PeriodLog, PeriodLog, QAfterSortBy> sortByNotes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.asc);
    });
  }

  QueryBuilder<PeriodLog, PeriodLog, QAfterSortBy> sortByNotesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.desc);
    });
  }

  QueryBuilder<PeriodLog, PeriodLog, QAfterSortBy> sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<PeriodLog, PeriodLog, QAfterSortBy> sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension PeriodLogQuerySortThenBy
    on QueryBuilder<PeriodLog, PeriodLog, QSortThenBy> {
  QueryBuilder<PeriodLog, PeriodLog, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<PeriodLog, PeriodLog, QAfterSortBy> thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<PeriodLog, PeriodLog, QAfterSortBy> thenByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.asc);
    });
  }

  QueryBuilder<PeriodLog, PeriodLog, QAfterSortBy> thenByDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.desc);
    });
  }

  QueryBuilder<PeriodLog, PeriodLog, QAfterSortBy> thenByDateKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateKey', Sort.asc);
    });
  }

  QueryBuilder<PeriodLog, PeriodLog, QAfterSortBy> thenByDateKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateKey', Sort.desc);
    });
  }

  QueryBuilder<PeriodLog, PeriodLog, QAfterSortBy> thenByFlow() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'flow', Sort.asc);
    });
  }

  QueryBuilder<PeriodLog, PeriodLog, QAfterSortBy> thenByFlowDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'flow', Sort.desc);
    });
  }

  QueryBuilder<PeriodLog, PeriodLog, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<PeriodLog, PeriodLog, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<PeriodLog, PeriodLog, QAfterSortBy> thenByNotes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.asc);
    });
  }

  QueryBuilder<PeriodLog, PeriodLog, QAfterSortBy> thenByNotesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.desc);
    });
  }

  QueryBuilder<PeriodLog, PeriodLog, QAfterSortBy> thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<PeriodLog, PeriodLog, QAfterSortBy> thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension PeriodLogQueryWhereDistinct
    on QueryBuilder<PeriodLog, PeriodLog, QDistinct> {
  QueryBuilder<PeriodLog, PeriodLog, QDistinct> distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<PeriodLog, PeriodLog, QDistinct> distinctByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'date');
    });
  }

  QueryBuilder<PeriodLog, PeriodLog, QDistinct> distinctByDateKey(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'dateKey', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PeriodLog, PeriodLog, QDistinct> distinctByFlow(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'flow', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PeriodLog, PeriodLog, QDistinct> distinctByNotes(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'notes', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PeriodLog, PeriodLog, QDistinct> distinctBySymptoms() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'symptoms');
    });
  }

  QueryBuilder<PeriodLog, PeriodLog, QDistinct> distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }
}

extension PeriodLogQueryProperty
    on QueryBuilder<PeriodLog, PeriodLog, QQueryProperty> {
  QueryBuilder<PeriodLog, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<PeriodLog, DateTime, QQueryOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<PeriodLog, DateTime, QQueryOperations> dateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'date');
    });
  }

  QueryBuilder<PeriodLog, String, QQueryOperations> dateKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'dateKey');
    });
  }

  QueryBuilder<PeriodLog, MenstrualFlow, QQueryOperations> flowProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'flow');
    });
  }

  QueryBuilder<PeriodLog, String, QQueryOperations> notesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'notes');
    });
  }

  QueryBuilder<PeriodLog, List<PeriodSymptom>, QQueryOperations>
      symptomsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'symptoms');
    });
  }

  QueryBuilder<PeriodLog, DateTime, QQueryOperations> updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }
}
