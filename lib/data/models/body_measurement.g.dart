// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'body_measurement.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetBodyMeasurementCollection on Isar {
  IsarCollection<BodyMeasurement> get bodyMeasurements => this.collection();
}

const BodyMeasurementSchema = CollectionSchema(
  name: r'BodyMeasurement',
  id: -9058319788105540477,
  properties: {
    r'armCm': PropertySchema(
      id: 0,
      name: r'armCm',
      type: IsarType.double,
    ),
    r'bodyFatPct': PropertySchema(
      id: 1,
      name: r'bodyFatPct',
      type: IsarType.double,
    ),
    r'chestCm': PropertySchema(
      id: 2,
      name: r'chestCm',
      type: IsarType.double,
    ),
    r'createdAt': PropertySchema(
      id: 3,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'date': PropertySchema(
      id: 4,
      name: r'date',
      type: IsarType.dateTime,
    ),
    r'hipsCm': PropertySchema(
      id: 5,
      name: r'hipsCm',
      type: IsarType.double,
    ),
    r'neckCm': PropertySchema(
      id: 6,
      name: r'neckCm',
      type: IsarType.double,
    ),
    r'note': PropertySchema(
      id: 7,
      name: r'note',
      type: IsarType.string,
    ),
    r'photoPath': PropertySchema(
      id: 8,
      name: r'photoPath',
      type: IsarType.string,
    ),
    r'thighCm': PropertySchema(
      id: 9,
      name: r'thighCm',
      type: IsarType.double,
    ),
    r'waistCm': PropertySchema(
      id: 10,
      name: r'waistCm',
      type: IsarType.double,
    ),
    r'weightKg': PropertySchema(
      id: 11,
      name: r'weightKg',
      type: IsarType.double,
    )
  },
  estimateSize: _bodyMeasurementEstimateSize,
  serialize: _bodyMeasurementSerialize,
  deserialize: _bodyMeasurementDeserialize,
  deserializeProp: _bodyMeasurementDeserializeProp,
  idName: r'id',
  indexes: {
    r'date': IndexSchema(
      id: -7552997827385218417,
      name: r'date',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'date',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _bodyMeasurementGetId,
  getLinks: _bodyMeasurementGetLinks,
  attach: _bodyMeasurementAttach,
  version: '3.1.0+1',
);

int _bodyMeasurementEstimateSize(
  BodyMeasurement object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.note;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.photoPath;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _bodyMeasurementSerialize(
  BodyMeasurement object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDouble(offsets[0], object.armCm);
  writer.writeDouble(offsets[1], object.bodyFatPct);
  writer.writeDouble(offsets[2], object.chestCm);
  writer.writeDateTime(offsets[3], object.createdAt);
  writer.writeDateTime(offsets[4], object.date);
  writer.writeDouble(offsets[5], object.hipsCm);
  writer.writeDouble(offsets[6], object.neckCm);
  writer.writeString(offsets[7], object.note);
  writer.writeString(offsets[8], object.photoPath);
  writer.writeDouble(offsets[9], object.thighCm);
  writer.writeDouble(offsets[10], object.waistCm);
  writer.writeDouble(offsets[11], object.weightKg);
}

BodyMeasurement _bodyMeasurementDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = BodyMeasurement();
  object.armCm = reader.readDoubleOrNull(offsets[0]);
  object.bodyFatPct = reader.readDoubleOrNull(offsets[1]);
  object.chestCm = reader.readDoubleOrNull(offsets[2]);
  object.createdAt = reader.readDateTime(offsets[3]);
  object.date = reader.readDateTime(offsets[4]);
  object.hipsCm = reader.readDoubleOrNull(offsets[5]);
  object.id = id;
  object.neckCm = reader.readDoubleOrNull(offsets[6]);
  object.note = reader.readStringOrNull(offsets[7]);
  object.photoPath = reader.readStringOrNull(offsets[8]);
  object.thighCm = reader.readDoubleOrNull(offsets[9]);
  object.waistCm = reader.readDoubleOrNull(offsets[10]);
  object.weightKg = reader.readDouble(offsets[11]);
  return object;
}

P _bodyMeasurementDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDoubleOrNull(offset)) as P;
    case 1:
      return (reader.readDoubleOrNull(offset)) as P;
    case 2:
      return (reader.readDoubleOrNull(offset)) as P;
    case 3:
      return (reader.readDateTime(offset)) as P;
    case 4:
      return (reader.readDateTime(offset)) as P;
    case 5:
      return (reader.readDoubleOrNull(offset)) as P;
    case 6:
      return (reader.readDoubleOrNull(offset)) as P;
    case 7:
      return (reader.readStringOrNull(offset)) as P;
    case 8:
      return (reader.readStringOrNull(offset)) as P;
    case 9:
      return (reader.readDoubleOrNull(offset)) as P;
    case 10:
      return (reader.readDoubleOrNull(offset)) as P;
    case 11:
      return (reader.readDouble(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _bodyMeasurementGetId(BodyMeasurement object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _bodyMeasurementGetLinks(BodyMeasurement object) {
  return [];
}

void _bodyMeasurementAttach(
    IsarCollection<dynamic> col, Id id, BodyMeasurement object) {
  object.id = id;
}

extension BodyMeasurementQueryWhereSort
    on QueryBuilder<BodyMeasurement, BodyMeasurement, QWhere> {
  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterWhere> anyDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'date'),
      );
    });
  }
}

extension BodyMeasurementQueryWhere
    on QueryBuilder<BodyMeasurement, BodyMeasurement, QWhereClause> {
  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterWhereClause>
      idNotEqualTo(Id id) {
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

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterWhereClause> idBetween(
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

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterWhereClause> dateEqualTo(
      DateTime date) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'date',
        value: [date],
      ));
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterWhereClause>
      dateNotEqualTo(DateTime date) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'date',
              lower: [],
              upper: [date],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'date',
              lower: [date],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'date',
              lower: [date],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'date',
              lower: [],
              upper: [date],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterWhereClause>
      dateGreaterThan(
    DateTime date, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'date',
        lower: [date],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterWhereClause>
      dateLessThan(
    DateTime date, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'date',
        lower: [],
        upper: [date],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterWhereClause> dateBetween(
    DateTime lowerDate,
    DateTime upperDate, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'date',
        lower: [lowerDate],
        includeLower: includeLower,
        upper: [upperDate],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension BodyMeasurementQueryFilter
    on QueryBuilder<BodyMeasurement, BodyMeasurement, QFilterCondition> {
  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      armCmIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'armCm',
      ));
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      armCmIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'armCm',
      ));
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      armCmEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'armCm',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      armCmGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'armCm',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      armCmLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'armCm',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      armCmBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'armCm',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      bodyFatPctIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'bodyFatPct',
      ));
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      bodyFatPctIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'bodyFatPct',
      ));
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      bodyFatPctEqualTo(
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

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      bodyFatPctGreaterThan(
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

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      bodyFatPctLessThan(
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

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      bodyFatPctBetween(
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

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      chestCmIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'chestCm',
      ));
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      chestCmIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'chestCm',
      ));
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      chestCmEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'chestCm',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      chestCmGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'chestCm',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      chestCmLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'chestCm',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      chestCmBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'chestCm',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
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

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      createdAtLessThan(
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

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      createdAtBetween(
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

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      dateEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'date',
        value: value,
      ));
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      dateGreaterThan(
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

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      dateLessThan(
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

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      dateBetween(
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

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      hipsCmIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'hipsCm',
      ));
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      hipsCmIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'hipsCm',
      ));
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      hipsCmEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'hipsCm',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      hipsCmGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'hipsCm',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      hipsCmLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'hipsCm',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      hipsCmBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'hipsCm',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      idGreaterThan(
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

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      idLessThan(
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

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      idBetween(
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

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      neckCmIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'neckCm',
      ));
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      neckCmIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'neckCm',
      ));
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      neckCmEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'neckCm',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      neckCmGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'neckCm',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      neckCmLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'neckCm',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      neckCmBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'neckCm',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      noteIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'note',
      ));
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      noteIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'note',
      ));
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      noteEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'note',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      noteGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'note',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      noteLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'note',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      noteBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'note',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      noteStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'note',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      noteEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'note',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      noteContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'note',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      noteMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'note',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      noteIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'note',
        value: '',
      ));
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      noteIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'note',
        value: '',
      ));
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      photoPathIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'photoPath',
      ));
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      photoPathIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'photoPath',
      ));
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      photoPathEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'photoPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      photoPathGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'photoPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      photoPathLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'photoPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      photoPathBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'photoPath',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      photoPathStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'photoPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      photoPathEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'photoPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      photoPathContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'photoPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      photoPathMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'photoPath',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      photoPathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'photoPath',
        value: '',
      ));
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      photoPathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'photoPath',
        value: '',
      ));
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      thighCmIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'thighCm',
      ));
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      thighCmIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'thighCm',
      ));
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      thighCmEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'thighCm',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      thighCmGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'thighCm',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      thighCmLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'thighCm',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      thighCmBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'thighCm',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      waistCmIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'waistCm',
      ));
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      waistCmIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'waistCm',
      ));
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      waistCmEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'waistCm',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      waistCmGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'waistCm',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      waistCmLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'waistCm',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      waistCmBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'waistCm',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      weightKgEqualTo(
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

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      weightKgGreaterThan(
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

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      weightKgLessThan(
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

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterFilterCondition>
      weightKgBetween(
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

extension BodyMeasurementQueryObject
    on QueryBuilder<BodyMeasurement, BodyMeasurement, QFilterCondition> {}

extension BodyMeasurementQueryLinks
    on QueryBuilder<BodyMeasurement, BodyMeasurement, QFilterCondition> {}

extension BodyMeasurementQuerySortBy
    on QueryBuilder<BodyMeasurement, BodyMeasurement, QSortBy> {
  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterSortBy> sortByArmCm() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'armCm', Sort.asc);
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterSortBy>
      sortByArmCmDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'armCm', Sort.desc);
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterSortBy>
      sortByBodyFatPct() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bodyFatPct', Sort.asc);
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterSortBy>
      sortByBodyFatPctDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bodyFatPct', Sort.desc);
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterSortBy> sortByChestCm() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'chestCm', Sort.asc);
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterSortBy>
      sortByChestCmDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'chestCm', Sort.desc);
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterSortBy>
      sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterSortBy>
      sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterSortBy> sortByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.asc);
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterSortBy>
      sortByDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.desc);
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterSortBy> sortByHipsCm() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hipsCm', Sort.asc);
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterSortBy>
      sortByHipsCmDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hipsCm', Sort.desc);
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterSortBy> sortByNeckCm() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'neckCm', Sort.asc);
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterSortBy>
      sortByNeckCmDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'neckCm', Sort.desc);
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterSortBy> sortByNote() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.asc);
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterSortBy>
      sortByNoteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.desc);
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterSortBy>
      sortByPhotoPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'photoPath', Sort.asc);
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterSortBy>
      sortByPhotoPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'photoPath', Sort.desc);
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterSortBy> sortByThighCm() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'thighCm', Sort.asc);
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterSortBy>
      sortByThighCmDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'thighCm', Sort.desc);
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterSortBy> sortByWaistCm() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'waistCm', Sort.asc);
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterSortBy>
      sortByWaistCmDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'waistCm', Sort.desc);
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterSortBy>
      sortByWeightKg() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weightKg', Sort.asc);
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterSortBy>
      sortByWeightKgDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weightKg', Sort.desc);
    });
  }
}

extension BodyMeasurementQuerySortThenBy
    on QueryBuilder<BodyMeasurement, BodyMeasurement, QSortThenBy> {
  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterSortBy> thenByArmCm() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'armCm', Sort.asc);
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterSortBy>
      thenByArmCmDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'armCm', Sort.desc);
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterSortBy>
      thenByBodyFatPct() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bodyFatPct', Sort.asc);
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterSortBy>
      thenByBodyFatPctDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bodyFatPct', Sort.desc);
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterSortBy> thenByChestCm() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'chestCm', Sort.asc);
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterSortBy>
      thenByChestCmDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'chestCm', Sort.desc);
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterSortBy>
      thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterSortBy>
      thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterSortBy> thenByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.asc);
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterSortBy>
      thenByDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.desc);
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterSortBy> thenByHipsCm() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hipsCm', Sort.asc);
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterSortBy>
      thenByHipsCmDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hipsCm', Sort.desc);
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterSortBy> thenByNeckCm() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'neckCm', Sort.asc);
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterSortBy>
      thenByNeckCmDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'neckCm', Sort.desc);
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterSortBy> thenByNote() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.asc);
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterSortBy>
      thenByNoteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.desc);
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterSortBy>
      thenByPhotoPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'photoPath', Sort.asc);
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterSortBy>
      thenByPhotoPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'photoPath', Sort.desc);
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterSortBy> thenByThighCm() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'thighCm', Sort.asc);
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterSortBy>
      thenByThighCmDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'thighCm', Sort.desc);
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterSortBy> thenByWaistCm() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'waistCm', Sort.asc);
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterSortBy>
      thenByWaistCmDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'waistCm', Sort.desc);
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterSortBy>
      thenByWeightKg() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weightKg', Sort.asc);
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QAfterSortBy>
      thenByWeightKgDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weightKg', Sort.desc);
    });
  }
}

extension BodyMeasurementQueryWhereDistinct
    on QueryBuilder<BodyMeasurement, BodyMeasurement, QDistinct> {
  QueryBuilder<BodyMeasurement, BodyMeasurement, QDistinct> distinctByArmCm() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'armCm');
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QDistinct>
      distinctByBodyFatPct() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'bodyFatPct');
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QDistinct>
      distinctByChestCm() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'chestCm');
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QDistinct>
      distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QDistinct> distinctByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'date');
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QDistinct> distinctByHipsCm() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'hipsCm');
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QDistinct> distinctByNeckCm() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'neckCm');
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QDistinct> distinctByNote(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'note', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QDistinct> distinctByPhotoPath(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'photoPath', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QDistinct>
      distinctByThighCm() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'thighCm');
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QDistinct>
      distinctByWaistCm() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'waistCm');
    });
  }

  QueryBuilder<BodyMeasurement, BodyMeasurement, QDistinct>
      distinctByWeightKg() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'weightKg');
    });
  }
}

extension BodyMeasurementQueryProperty
    on QueryBuilder<BodyMeasurement, BodyMeasurement, QQueryProperty> {
  QueryBuilder<BodyMeasurement, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<BodyMeasurement, double?, QQueryOperations> armCmProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'armCm');
    });
  }

  QueryBuilder<BodyMeasurement, double?, QQueryOperations>
      bodyFatPctProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'bodyFatPct');
    });
  }

  QueryBuilder<BodyMeasurement, double?, QQueryOperations> chestCmProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'chestCm');
    });
  }

  QueryBuilder<BodyMeasurement, DateTime, QQueryOperations>
      createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<BodyMeasurement, DateTime, QQueryOperations> dateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'date');
    });
  }

  QueryBuilder<BodyMeasurement, double?, QQueryOperations> hipsCmProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'hipsCm');
    });
  }

  QueryBuilder<BodyMeasurement, double?, QQueryOperations> neckCmProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'neckCm');
    });
  }

  QueryBuilder<BodyMeasurement, String?, QQueryOperations> noteProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'note');
    });
  }

  QueryBuilder<BodyMeasurement, String?, QQueryOperations> photoPathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'photoPath');
    });
  }

  QueryBuilder<BodyMeasurement, double?, QQueryOperations> thighCmProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'thighCm');
    });
  }

  QueryBuilder<BodyMeasurement, double?, QQueryOperations> waistCmProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'waistCm');
    });
  }

  QueryBuilder<BodyMeasurement, double, QQueryOperations> weightKgProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'weightKg');
    });
  }
}
