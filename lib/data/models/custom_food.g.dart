// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'custom_food.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetCustomFoodCollection on Isar {
  IsarCollection<CustomFood> get customFoods => this.collection();
}

const CustomFoodSchema = CollectionSchema(
  name: r'CustomFood',
  id: 2829764927784470877,
  properties: {
    r'caloriesPerServing': PropertySchema(
      id: 0,
      name: r'caloriesPerServing',
      type: IsarType.long,
    ),
    r'carbsGPerServing': PropertySchema(
      id: 1,
      name: r'carbsGPerServing',
      type: IsarType.long,
    ),
    r'createdAt': PropertySchema(
      id: 2,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'fatGPerServing': PropertySchema(
      id: 3,
      name: r'fatGPerServing',
      type: IsarType.long,
    ),
    r'fiberGPerServing': PropertySchema(
      id: 4,
      name: r'fiberGPerServing',
      type: IsarType.long,
    ),
    r'ingredients': PropertySchema(
      id: 5,
      name: r'ingredients',
      type: IsarType.string,
    ),
    r'name': PropertySchema(
      id: 6,
      name: r'name',
      type: IsarType.string,
    ),
    r'proteinGPerServing': PropertySchema(
      id: 7,
      name: r'proteinGPerServing',
      type: IsarType.long,
    ),
    r'servingDescription': PropertySchema(
      id: 8,
      name: r'servingDescription',
      type: IsarType.string,
    ),
    r'servingSizeG': PropertySchema(
      id: 9,
      name: r'servingSizeG',
      type: IsarType.double,
    ),
    r'sodiumMgPerServing': PropertySchema(
      id: 10,
      name: r'sodiumMgPerServing',
      type: IsarType.long,
    )
  },
  estimateSize: _customFoodEstimateSize,
  serialize: _customFoodSerialize,
  deserialize: _customFoodDeserialize,
  deserializeProp: _customFoodDeserializeProp,
  idName: r'id',
  indexes: {
    r'name': IndexSchema(
      id: 879695947855722453,
      name: r'name',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'name',
          type: IndexType.hash,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _customFoodGetId,
  getLinks: _customFoodGetLinks,
  attach: _customFoodAttach,
  version: '3.1.0+1',
);

int _customFoodEstimateSize(
  CustomFood object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.ingredients;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.name.length * 3;
  bytesCount += 3 + object.servingDescription.length * 3;
  return bytesCount;
}

void _customFoodSerialize(
  CustomFood object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.caloriesPerServing);
  writer.writeLong(offsets[1], object.carbsGPerServing);
  writer.writeDateTime(offsets[2], object.createdAt);
  writer.writeLong(offsets[3], object.fatGPerServing);
  writer.writeLong(offsets[4], object.fiberGPerServing);
  writer.writeString(offsets[5], object.ingredients);
  writer.writeString(offsets[6], object.name);
  writer.writeLong(offsets[7], object.proteinGPerServing);
  writer.writeString(offsets[8], object.servingDescription);
  writer.writeDouble(offsets[9], object.servingSizeG);
  writer.writeLong(offsets[10], object.sodiumMgPerServing);
}

CustomFood _customFoodDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = CustomFood();
  object.caloriesPerServing = reader.readLong(offsets[0]);
  object.carbsGPerServing = reader.readLong(offsets[1]);
  object.createdAt = reader.readDateTime(offsets[2]);
  object.fatGPerServing = reader.readLong(offsets[3]);
  object.fiberGPerServing = reader.readLong(offsets[4]);
  object.id = id;
  object.ingredients = reader.readStringOrNull(offsets[5]);
  object.name = reader.readString(offsets[6]);
  object.proteinGPerServing = reader.readLong(offsets[7]);
  object.servingDescription = reader.readString(offsets[8]);
  object.servingSizeG = reader.readDouble(offsets[9]);
  object.sodiumMgPerServing = reader.readLong(offsets[10]);
  return object;
}

P _customFoodDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLong(offset)) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    case 2:
      return (reader.readDateTime(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    case 4:
      return (reader.readLong(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readLong(offset)) as P;
    case 8:
      return (reader.readString(offset)) as P;
    case 9:
      return (reader.readDouble(offset)) as P;
    case 10:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _customFoodGetId(CustomFood object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _customFoodGetLinks(CustomFood object) {
  return [];
}

void _customFoodAttach(IsarCollection<dynamic> col, Id id, CustomFood object) {
  object.id = id;
}

extension CustomFoodQueryWhereSort
    on QueryBuilder<CustomFood, CustomFood, QWhere> {
  QueryBuilder<CustomFood, CustomFood, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension CustomFoodQueryWhere
    on QueryBuilder<CustomFood, CustomFood, QWhereClause> {
  QueryBuilder<CustomFood, CustomFood, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<CustomFood, CustomFood, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<CustomFood, CustomFood, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<CustomFood, CustomFood, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<CustomFood, CustomFood, QAfterWhereClause> idBetween(
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

  QueryBuilder<CustomFood, CustomFood, QAfterWhereClause> nameEqualTo(
      String name) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'name',
        value: [name],
      ));
    });
  }

  QueryBuilder<CustomFood, CustomFood, QAfterWhereClause> nameNotEqualTo(
      String name) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'name',
              lower: [],
              upper: [name],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'name',
              lower: [name],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'name',
              lower: [name],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'name',
              lower: [],
              upper: [name],
              includeUpper: false,
            ));
      }
    });
  }
}

extension CustomFoodQueryFilter
    on QueryBuilder<CustomFood, CustomFood, QFilterCondition> {
  QueryBuilder<CustomFood, CustomFood, QAfterFilterCondition>
      caloriesPerServingEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'caloriesPerServing',
        value: value,
      ));
    });
  }

  QueryBuilder<CustomFood, CustomFood, QAfterFilterCondition>
      caloriesPerServingGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'caloriesPerServing',
        value: value,
      ));
    });
  }

  QueryBuilder<CustomFood, CustomFood, QAfterFilterCondition>
      caloriesPerServingLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'caloriesPerServing',
        value: value,
      ));
    });
  }

  QueryBuilder<CustomFood, CustomFood, QAfterFilterCondition>
      caloriesPerServingBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'caloriesPerServing',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CustomFood, CustomFood, QAfterFilterCondition>
      carbsGPerServingEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'carbsGPerServing',
        value: value,
      ));
    });
  }

  QueryBuilder<CustomFood, CustomFood, QAfterFilterCondition>
      carbsGPerServingGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'carbsGPerServing',
        value: value,
      ));
    });
  }

  QueryBuilder<CustomFood, CustomFood, QAfterFilterCondition>
      carbsGPerServingLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'carbsGPerServing',
        value: value,
      ));
    });
  }

  QueryBuilder<CustomFood, CustomFood, QAfterFilterCondition>
      carbsGPerServingBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'carbsGPerServing',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CustomFood, CustomFood, QAfterFilterCondition> createdAtEqualTo(
      DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CustomFood, CustomFood, QAfterFilterCondition>
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

  QueryBuilder<CustomFood, CustomFood, QAfterFilterCondition> createdAtLessThan(
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

  QueryBuilder<CustomFood, CustomFood, QAfterFilterCondition> createdAtBetween(
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

  QueryBuilder<CustomFood, CustomFood, QAfterFilterCondition>
      fatGPerServingEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fatGPerServing',
        value: value,
      ));
    });
  }

  QueryBuilder<CustomFood, CustomFood, QAfterFilterCondition>
      fatGPerServingGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'fatGPerServing',
        value: value,
      ));
    });
  }

  QueryBuilder<CustomFood, CustomFood, QAfterFilterCondition>
      fatGPerServingLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'fatGPerServing',
        value: value,
      ));
    });
  }

  QueryBuilder<CustomFood, CustomFood, QAfterFilterCondition>
      fatGPerServingBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'fatGPerServing',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CustomFood, CustomFood, QAfterFilterCondition>
      fiberGPerServingEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fiberGPerServing',
        value: value,
      ));
    });
  }

  QueryBuilder<CustomFood, CustomFood, QAfterFilterCondition>
      fiberGPerServingGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'fiberGPerServing',
        value: value,
      ));
    });
  }

  QueryBuilder<CustomFood, CustomFood, QAfterFilterCondition>
      fiberGPerServingLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'fiberGPerServing',
        value: value,
      ));
    });
  }

  QueryBuilder<CustomFood, CustomFood, QAfterFilterCondition>
      fiberGPerServingBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'fiberGPerServing',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CustomFood, CustomFood, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<CustomFood, CustomFood, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<CustomFood, CustomFood, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<CustomFood, CustomFood, QAfterFilterCondition> idBetween(
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

  QueryBuilder<CustomFood, CustomFood, QAfterFilterCondition>
      ingredientsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'ingredients',
      ));
    });
  }

  QueryBuilder<CustomFood, CustomFood, QAfterFilterCondition>
      ingredientsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'ingredients',
      ));
    });
  }

  QueryBuilder<CustomFood, CustomFood, QAfterFilterCondition>
      ingredientsEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ingredients',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomFood, CustomFood, QAfterFilterCondition>
      ingredientsGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'ingredients',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomFood, CustomFood, QAfterFilterCondition>
      ingredientsLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'ingredients',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomFood, CustomFood, QAfterFilterCondition>
      ingredientsBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'ingredients',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomFood, CustomFood, QAfterFilterCondition>
      ingredientsStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'ingredients',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomFood, CustomFood, QAfterFilterCondition>
      ingredientsEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'ingredients',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomFood, CustomFood, QAfterFilterCondition>
      ingredientsContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'ingredients',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomFood, CustomFood, QAfterFilterCondition>
      ingredientsMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'ingredients',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomFood, CustomFood, QAfterFilterCondition>
      ingredientsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ingredients',
        value: '',
      ));
    });
  }

  QueryBuilder<CustomFood, CustomFood, QAfterFilterCondition>
      ingredientsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'ingredients',
        value: '',
      ));
    });
  }

  QueryBuilder<CustomFood, CustomFood, QAfterFilterCondition> nameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomFood, CustomFood, QAfterFilterCondition> nameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomFood, CustomFood, QAfterFilterCondition> nameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomFood, CustomFood, QAfterFilterCondition> nameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'name',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomFood, CustomFood, QAfterFilterCondition> nameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomFood, CustomFood, QAfterFilterCondition> nameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomFood, CustomFood, QAfterFilterCondition> nameContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomFood, CustomFood, QAfterFilterCondition> nameMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'name',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomFood, CustomFood, QAfterFilterCondition> nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<CustomFood, CustomFood, QAfterFilterCondition> nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<CustomFood, CustomFood, QAfterFilterCondition>
      proteinGPerServingEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'proteinGPerServing',
        value: value,
      ));
    });
  }

  QueryBuilder<CustomFood, CustomFood, QAfterFilterCondition>
      proteinGPerServingGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'proteinGPerServing',
        value: value,
      ));
    });
  }

  QueryBuilder<CustomFood, CustomFood, QAfterFilterCondition>
      proteinGPerServingLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'proteinGPerServing',
        value: value,
      ));
    });
  }

  QueryBuilder<CustomFood, CustomFood, QAfterFilterCondition>
      proteinGPerServingBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'proteinGPerServing',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CustomFood, CustomFood, QAfterFilterCondition>
      servingDescriptionEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'servingDescription',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomFood, CustomFood, QAfterFilterCondition>
      servingDescriptionGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'servingDescription',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomFood, CustomFood, QAfterFilterCondition>
      servingDescriptionLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'servingDescription',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomFood, CustomFood, QAfterFilterCondition>
      servingDescriptionBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'servingDescription',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomFood, CustomFood, QAfterFilterCondition>
      servingDescriptionStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'servingDescription',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomFood, CustomFood, QAfterFilterCondition>
      servingDescriptionEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'servingDescription',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomFood, CustomFood, QAfterFilterCondition>
      servingDescriptionContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'servingDescription',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomFood, CustomFood, QAfterFilterCondition>
      servingDescriptionMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'servingDescription',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomFood, CustomFood, QAfterFilterCondition>
      servingDescriptionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'servingDescription',
        value: '',
      ));
    });
  }

  QueryBuilder<CustomFood, CustomFood, QAfterFilterCondition>
      servingDescriptionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'servingDescription',
        value: '',
      ));
    });
  }

  QueryBuilder<CustomFood, CustomFood, QAfterFilterCondition>
      servingSizeGEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'servingSizeG',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CustomFood, CustomFood, QAfterFilterCondition>
      servingSizeGGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'servingSizeG',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CustomFood, CustomFood, QAfterFilterCondition>
      servingSizeGLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'servingSizeG',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CustomFood, CustomFood, QAfterFilterCondition>
      servingSizeGBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'servingSizeG',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CustomFood, CustomFood, QAfterFilterCondition>
      sodiumMgPerServingEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sodiumMgPerServing',
        value: value,
      ));
    });
  }

  QueryBuilder<CustomFood, CustomFood, QAfterFilterCondition>
      sodiumMgPerServingGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'sodiumMgPerServing',
        value: value,
      ));
    });
  }

  QueryBuilder<CustomFood, CustomFood, QAfterFilterCondition>
      sodiumMgPerServingLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'sodiumMgPerServing',
        value: value,
      ));
    });
  }

  QueryBuilder<CustomFood, CustomFood, QAfterFilterCondition>
      sodiumMgPerServingBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'sodiumMgPerServing',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension CustomFoodQueryObject
    on QueryBuilder<CustomFood, CustomFood, QFilterCondition> {}

extension CustomFoodQueryLinks
    on QueryBuilder<CustomFood, CustomFood, QFilterCondition> {}

extension CustomFoodQuerySortBy
    on QueryBuilder<CustomFood, CustomFood, QSortBy> {
  QueryBuilder<CustomFood, CustomFood, QAfterSortBy>
      sortByCaloriesPerServing() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'caloriesPerServing', Sort.asc);
    });
  }

  QueryBuilder<CustomFood, CustomFood, QAfterSortBy>
      sortByCaloriesPerServingDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'caloriesPerServing', Sort.desc);
    });
  }

  QueryBuilder<CustomFood, CustomFood, QAfterSortBy> sortByCarbsGPerServing() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'carbsGPerServing', Sort.asc);
    });
  }

  QueryBuilder<CustomFood, CustomFood, QAfterSortBy>
      sortByCarbsGPerServingDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'carbsGPerServing', Sort.desc);
    });
  }

  QueryBuilder<CustomFood, CustomFood, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<CustomFood, CustomFood, QAfterSortBy> sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<CustomFood, CustomFood, QAfterSortBy> sortByFatGPerServing() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fatGPerServing', Sort.asc);
    });
  }

  QueryBuilder<CustomFood, CustomFood, QAfterSortBy>
      sortByFatGPerServingDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fatGPerServing', Sort.desc);
    });
  }

  QueryBuilder<CustomFood, CustomFood, QAfterSortBy> sortByFiberGPerServing() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fiberGPerServing', Sort.asc);
    });
  }

  QueryBuilder<CustomFood, CustomFood, QAfterSortBy>
      sortByFiberGPerServingDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fiberGPerServing', Sort.desc);
    });
  }

  QueryBuilder<CustomFood, CustomFood, QAfterSortBy> sortByIngredients() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ingredients', Sort.asc);
    });
  }

  QueryBuilder<CustomFood, CustomFood, QAfterSortBy> sortByIngredientsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ingredients', Sort.desc);
    });
  }

  QueryBuilder<CustomFood, CustomFood, QAfterSortBy> sortByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<CustomFood, CustomFood, QAfterSortBy> sortByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<CustomFood, CustomFood, QAfterSortBy>
      sortByProteinGPerServing() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'proteinGPerServing', Sort.asc);
    });
  }

  QueryBuilder<CustomFood, CustomFood, QAfterSortBy>
      sortByProteinGPerServingDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'proteinGPerServing', Sort.desc);
    });
  }

  QueryBuilder<CustomFood, CustomFood, QAfterSortBy>
      sortByServingDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'servingDescription', Sort.asc);
    });
  }

  QueryBuilder<CustomFood, CustomFood, QAfterSortBy>
      sortByServingDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'servingDescription', Sort.desc);
    });
  }

  QueryBuilder<CustomFood, CustomFood, QAfterSortBy> sortByServingSizeG() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'servingSizeG', Sort.asc);
    });
  }

  QueryBuilder<CustomFood, CustomFood, QAfterSortBy> sortByServingSizeGDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'servingSizeG', Sort.desc);
    });
  }

  QueryBuilder<CustomFood, CustomFood, QAfterSortBy>
      sortBySodiumMgPerServing() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sodiumMgPerServing', Sort.asc);
    });
  }

  QueryBuilder<CustomFood, CustomFood, QAfterSortBy>
      sortBySodiumMgPerServingDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sodiumMgPerServing', Sort.desc);
    });
  }
}

extension CustomFoodQuerySortThenBy
    on QueryBuilder<CustomFood, CustomFood, QSortThenBy> {
  QueryBuilder<CustomFood, CustomFood, QAfterSortBy>
      thenByCaloriesPerServing() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'caloriesPerServing', Sort.asc);
    });
  }

  QueryBuilder<CustomFood, CustomFood, QAfterSortBy>
      thenByCaloriesPerServingDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'caloriesPerServing', Sort.desc);
    });
  }

  QueryBuilder<CustomFood, CustomFood, QAfterSortBy> thenByCarbsGPerServing() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'carbsGPerServing', Sort.asc);
    });
  }

  QueryBuilder<CustomFood, CustomFood, QAfterSortBy>
      thenByCarbsGPerServingDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'carbsGPerServing', Sort.desc);
    });
  }

  QueryBuilder<CustomFood, CustomFood, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<CustomFood, CustomFood, QAfterSortBy> thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<CustomFood, CustomFood, QAfterSortBy> thenByFatGPerServing() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fatGPerServing', Sort.asc);
    });
  }

  QueryBuilder<CustomFood, CustomFood, QAfterSortBy>
      thenByFatGPerServingDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fatGPerServing', Sort.desc);
    });
  }

  QueryBuilder<CustomFood, CustomFood, QAfterSortBy> thenByFiberGPerServing() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fiberGPerServing', Sort.asc);
    });
  }

  QueryBuilder<CustomFood, CustomFood, QAfterSortBy>
      thenByFiberGPerServingDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fiberGPerServing', Sort.desc);
    });
  }

  QueryBuilder<CustomFood, CustomFood, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<CustomFood, CustomFood, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<CustomFood, CustomFood, QAfterSortBy> thenByIngredients() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ingredients', Sort.asc);
    });
  }

  QueryBuilder<CustomFood, CustomFood, QAfterSortBy> thenByIngredientsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ingredients', Sort.desc);
    });
  }

  QueryBuilder<CustomFood, CustomFood, QAfterSortBy> thenByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<CustomFood, CustomFood, QAfterSortBy> thenByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<CustomFood, CustomFood, QAfterSortBy>
      thenByProteinGPerServing() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'proteinGPerServing', Sort.asc);
    });
  }

  QueryBuilder<CustomFood, CustomFood, QAfterSortBy>
      thenByProteinGPerServingDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'proteinGPerServing', Sort.desc);
    });
  }

  QueryBuilder<CustomFood, CustomFood, QAfterSortBy>
      thenByServingDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'servingDescription', Sort.asc);
    });
  }

  QueryBuilder<CustomFood, CustomFood, QAfterSortBy>
      thenByServingDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'servingDescription', Sort.desc);
    });
  }

  QueryBuilder<CustomFood, CustomFood, QAfterSortBy> thenByServingSizeG() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'servingSizeG', Sort.asc);
    });
  }

  QueryBuilder<CustomFood, CustomFood, QAfterSortBy> thenByServingSizeGDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'servingSizeG', Sort.desc);
    });
  }

  QueryBuilder<CustomFood, CustomFood, QAfterSortBy>
      thenBySodiumMgPerServing() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sodiumMgPerServing', Sort.asc);
    });
  }

  QueryBuilder<CustomFood, CustomFood, QAfterSortBy>
      thenBySodiumMgPerServingDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sodiumMgPerServing', Sort.desc);
    });
  }
}

extension CustomFoodQueryWhereDistinct
    on QueryBuilder<CustomFood, CustomFood, QDistinct> {
  QueryBuilder<CustomFood, CustomFood, QDistinct>
      distinctByCaloriesPerServing() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'caloriesPerServing');
    });
  }

  QueryBuilder<CustomFood, CustomFood, QDistinct> distinctByCarbsGPerServing() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'carbsGPerServing');
    });
  }

  QueryBuilder<CustomFood, CustomFood, QDistinct> distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<CustomFood, CustomFood, QDistinct> distinctByFatGPerServing() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'fatGPerServing');
    });
  }

  QueryBuilder<CustomFood, CustomFood, QDistinct> distinctByFiberGPerServing() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'fiberGPerServing');
    });
  }

  QueryBuilder<CustomFood, CustomFood, QDistinct> distinctByIngredients(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'ingredients', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CustomFood, CustomFood, QDistinct> distinctByName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'name', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CustomFood, CustomFood, QDistinct>
      distinctByProteinGPerServing() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'proteinGPerServing');
    });
  }

  QueryBuilder<CustomFood, CustomFood, QDistinct> distinctByServingDescription(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'servingDescription',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CustomFood, CustomFood, QDistinct> distinctByServingSizeG() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'servingSizeG');
    });
  }

  QueryBuilder<CustomFood, CustomFood, QDistinct>
      distinctBySodiumMgPerServing() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sodiumMgPerServing');
    });
  }
}

extension CustomFoodQueryProperty
    on QueryBuilder<CustomFood, CustomFood, QQueryProperty> {
  QueryBuilder<CustomFood, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<CustomFood, int, QQueryOperations> caloriesPerServingProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'caloriesPerServing');
    });
  }

  QueryBuilder<CustomFood, int, QQueryOperations> carbsGPerServingProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'carbsGPerServing');
    });
  }

  QueryBuilder<CustomFood, DateTime, QQueryOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<CustomFood, int, QQueryOperations> fatGPerServingProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'fatGPerServing');
    });
  }

  QueryBuilder<CustomFood, int, QQueryOperations> fiberGPerServingProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'fiberGPerServing');
    });
  }

  QueryBuilder<CustomFood, String?, QQueryOperations> ingredientsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'ingredients');
    });
  }

  QueryBuilder<CustomFood, String, QQueryOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'name');
    });
  }

  QueryBuilder<CustomFood, int, QQueryOperations> proteinGPerServingProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'proteinGPerServing');
    });
  }

  QueryBuilder<CustomFood, String, QQueryOperations>
      servingDescriptionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'servingDescription');
    });
  }

  QueryBuilder<CustomFood, double, QQueryOperations> servingSizeGProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'servingSizeG');
    });
  }

  QueryBuilder<CustomFood, int, QQueryOperations> sodiumMgPerServingProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sodiumMgPerServing');
    });
  }
}
