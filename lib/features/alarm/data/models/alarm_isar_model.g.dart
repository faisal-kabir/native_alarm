// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'alarm_isar_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types, experimental_member_use

extension GetAlarmIsarModelCollection on Isar {
  IsarCollection<AlarmIsarModel> get alarmIsarModels => this.collection();
}

const AlarmIsarModelSchema = CollectionSchema(
  name: r'AlarmIsarModel',
  id: -1240313664775071482,
  properties: {
    r'alarmId': PropertySchema(id: 0, name: r'alarmId', type: IsarType.string),
    r'audioTrackId': PropertySchema(
      id: 1,
      name: r'audioTrackId',
      type: IsarType.string,
    ),
    r'enabled': PropertySchema(id: 2, name: r'enabled', type: IsarType.bool),
    r'label': PropertySchema(id: 3, name: r'label', type: IsarType.string),
    r'missionName': PropertySchema(
      id: 4,
      name: r'missionName',
      type: IsarType.string,
    ),
    r'repeatWeekdays': PropertySchema(
      id: 5,
      name: r'repeatWeekdays',
      type: IsarType.longList,
    ),
    r'ringtoneId': PropertySchema(
      id: 6,
      name: r'ringtoneId',
      type: IsarType.string,
    ),
    r'time': PropertySchema(id: 7, name: r'time', type: IsarType.dateTime),
  },

  estimateSize: _alarmIsarModelEstimateSize,
  serialize: _alarmIsarModelSerialize,
  deserialize: _alarmIsarModelDeserialize,
  deserializeProp: _alarmIsarModelDeserializeProp,
  idName: r'isarId',
  indexes: {
    r'alarmId': IndexSchema(
      id: 635271235571588173,
      name: r'alarmId',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'alarmId',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},

  getId: _alarmIsarModelGetId,
  getLinks: _alarmIsarModelGetLinks,
  attach: _alarmIsarModelAttach,
  version: '3.4.1',
);

int _alarmIsarModelEstimateSize(
  AlarmIsarModel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.alarmId.length * 3;
  bytesCount += 3 + object.audioTrackId.length * 3;
  {
    final value = object.label;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.missionName;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.repeatWeekdays.length * 8;
  bytesCount += 3 + object.ringtoneId.length * 3;
  return bytesCount;
}

void _alarmIsarModelSerialize(
  AlarmIsarModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.alarmId);
  writer.writeString(offsets[1], object.audioTrackId);
  writer.writeBool(offsets[2], object.enabled);
  writer.writeString(offsets[3], object.label);
  writer.writeString(offsets[4], object.missionName);
  writer.writeLongList(offsets[5], object.repeatWeekdays);
  writer.writeString(offsets[6], object.ringtoneId);
  writer.writeDateTime(offsets[7], object.time);
}

AlarmIsarModel _alarmIsarModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = AlarmIsarModel();
  object.alarmId = reader.readString(offsets[0]);
  object.audioTrackId = reader.readString(offsets[1]);
  object.enabled = reader.readBool(offsets[2]);
  object.isarId = id;
  object.label = reader.readStringOrNull(offsets[3]);
  object.missionName = reader.readStringOrNull(offsets[4]);
  object.repeatWeekdays = reader.readLongList(offsets[5]) ?? [];
  object.ringtoneId = reader.readString(offsets[6]);
  object.time = reader.readDateTime(offsets[7]);
  return object;
}

P _alarmIsarModelDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readBool(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readLongList(offset) ?? []) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _alarmIsarModelGetId(AlarmIsarModel object) {
  return object.isarId;
}

List<IsarLinkBase<dynamic>> _alarmIsarModelGetLinks(AlarmIsarModel object) {
  return [];
}

void _alarmIsarModelAttach(
  IsarCollection<dynamic> col,
  Id id,
  AlarmIsarModel object,
) {
  object.isarId = id;
}

extension AlarmIsarModelByIndex on IsarCollection<AlarmIsarModel> {
  Future<AlarmIsarModel?> getByAlarmId(String alarmId) {
    return getByIndex(r'alarmId', [alarmId]);
  }

  AlarmIsarModel? getByAlarmIdSync(String alarmId) {
    return getByIndexSync(r'alarmId', [alarmId]);
  }

  Future<bool> deleteByAlarmId(String alarmId) {
    return deleteByIndex(r'alarmId', [alarmId]);
  }

  bool deleteByAlarmIdSync(String alarmId) {
    return deleteByIndexSync(r'alarmId', [alarmId]);
  }

  Future<List<AlarmIsarModel?>> getAllByAlarmId(List<String> alarmIdValues) {
    final values = alarmIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'alarmId', values);
  }

  List<AlarmIsarModel?> getAllByAlarmIdSync(List<String> alarmIdValues) {
    final values = alarmIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'alarmId', values);
  }

  Future<int> deleteAllByAlarmId(List<String> alarmIdValues) {
    final values = alarmIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'alarmId', values);
  }

  int deleteAllByAlarmIdSync(List<String> alarmIdValues) {
    final values = alarmIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'alarmId', values);
  }

  Future<Id> putByAlarmId(AlarmIsarModel object) {
    return putByIndex(r'alarmId', object);
  }

  Id putByAlarmIdSync(AlarmIsarModel object, {bool saveLinks = true}) {
    return putByIndexSync(r'alarmId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByAlarmId(List<AlarmIsarModel> objects) {
    return putAllByIndex(r'alarmId', objects);
  }

  List<Id> putAllByAlarmIdSync(
    List<AlarmIsarModel> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'alarmId', objects, saveLinks: saveLinks);
  }
}

extension AlarmIsarModelQueryWhereSort
    on QueryBuilder<AlarmIsarModel, AlarmIsarModel, QWhere> {
  QueryBuilder<AlarmIsarModel, AlarmIsarModel, QAfterWhere> anyIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension AlarmIsarModelQueryWhere
    on QueryBuilder<AlarmIsarModel, AlarmIsarModel, QWhereClause> {
  QueryBuilder<AlarmIsarModel, AlarmIsarModel, QAfterWhereClause> isarIdEqualTo(
    Id isarId,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(lower: isarId, upper: isarId),
      );
    });
  }

  QueryBuilder<AlarmIsarModel, AlarmIsarModel, QAfterWhereClause>
  isarIdNotEqualTo(Id isarId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: isarId, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: isarId, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: isarId, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: isarId, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<AlarmIsarModel, AlarmIsarModel, QAfterWhereClause>
  isarIdGreaterThan(Id isarId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: isarId, includeLower: include),
      );
    });
  }

  QueryBuilder<AlarmIsarModel, AlarmIsarModel, QAfterWhereClause>
  isarIdLessThan(Id isarId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: isarId, includeUpper: include),
      );
    });
  }

  QueryBuilder<AlarmIsarModel, AlarmIsarModel, QAfterWhereClause> isarIdBetween(
    Id lowerIsarId,
    Id upperIsarId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(
          lower: lowerIsarId,
          includeLower: includeLower,
          upper: upperIsarId,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<AlarmIsarModel, AlarmIsarModel, QAfterWhereClause>
  alarmIdEqualTo(String alarmId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'alarmId', value: [alarmId]),
      );
    });
  }

  QueryBuilder<AlarmIsarModel, AlarmIsarModel, QAfterWhereClause>
  alarmIdNotEqualTo(String alarmId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'alarmId',
                lower: [],
                upper: [alarmId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'alarmId',
                lower: [alarmId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'alarmId',
                lower: [alarmId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'alarmId',
                lower: [],
                upper: [alarmId],
                includeUpper: false,
              ),
            );
      }
    });
  }
}

extension AlarmIsarModelQueryFilter
    on QueryBuilder<AlarmIsarModel, AlarmIsarModel, QFilterCondition> {
  QueryBuilder<AlarmIsarModel, AlarmIsarModel, QAfterFilterCondition>
  alarmIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'alarmId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AlarmIsarModel, AlarmIsarModel, QAfterFilterCondition>
  alarmIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'alarmId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AlarmIsarModel, AlarmIsarModel, QAfterFilterCondition>
  alarmIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'alarmId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AlarmIsarModel, AlarmIsarModel, QAfterFilterCondition>
  alarmIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'alarmId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AlarmIsarModel, AlarmIsarModel, QAfterFilterCondition>
  alarmIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'alarmId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AlarmIsarModel, AlarmIsarModel, QAfterFilterCondition>
  alarmIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'alarmId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AlarmIsarModel, AlarmIsarModel, QAfterFilterCondition>
  alarmIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'alarmId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AlarmIsarModel, AlarmIsarModel, QAfterFilterCondition>
  alarmIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'alarmId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AlarmIsarModel, AlarmIsarModel, QAfterFilterCondition>
  alarmIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'alarmId', value: ''),
      );
    });
  }

  QueryBuilder<AlarmIsarModel, AlarmIsarModel, QAfterFilterCondition>
  alarmIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'alarmId', value: ''),
      );
    });
  }

  QueryBuilder<AlarmIsarModel, AlarmIsarModel, QAfterFilterCondition>
  audioTrackIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'audioTrackId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AlarmIsarModel, AlarmIsarModel, QAfterFilterCondition>
  audioTrackIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'audioTrackId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AlarmIsarModel, AlarmIsarModel, QAfterFilterCondition>
  audioTrackIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'audioTrackId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AlarmIsarModel, AlarmIsarModel, QAfterFilterCondition>
  audioTrackIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'audioTrackId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AlarmIsarModel, AlarmIsarModel, QAfterFilterCondition>
  audioTrackIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'audioTrackId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AlarmIsarModel, AlarmIsarModel, QAfterFilterCondition>
  audioTrackIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'audioTrackId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AlarmIsarModel, AlarmIsarModel, QAfterFilterCondition>
  audioTrackIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'audioTrackId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AlarmIsarModel, AlarmIsarModel, QAfterFilterCondition>
  audioTrackIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'audioTrackId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AlarmIsarModel, AlarmIsarModel, QAfterFilterCondition>
  audioTrackIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'audioTrackId', value: ''),
      );
    });
  }

  QueryBuilder<AlarmIsarModel, AlarmIsarModel, QAfterFilterCondition>
  audioTrackIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'audioTrackId', value: ''),
      );
    });
  }

  QueryBuilder<AlarmIsarModel, AlarmIsarModel, QAfterFilterCondition>
  enabledEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'enabled', value: value),
      );
    });
  }

  QueryBuilder<AlarmIsarModel, AlarmIsarModel, QAfterFilterCondition>
  isarIdEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isarId', value: value),
      );
    });
  }

  QueryBuilder<AlarmIsarModel, AlarmIsarModel, QAfterFilterCondition>
  isarIdGreaterThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'isarId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<AlarmIsarModel, AlarmIsarModel, QAfterFilterCondition>
  isarIdLessThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'isarId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<AlarmIsarModel, AlarmIsarModel, QAfterFilterCondition>
  isarIdBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'isarId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<AlarmIsarModel, AlarmIsarModel, QAfterFilterCondition>
  labelIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'label'),
      );
    });
  }

  QueryBuilder<AlarmIsarModel, AlarmIsarModel, QAfterFilterCondition>
  labelIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'label'),
      );
    });
  }

  QueryBuilder<AlarmIsarModel, AlarmIsarModel, QAfterFilterCondition>
  labelEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'label',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AlarmIsarModel, AlarmIsarModel, QAfterFilterCondition>
  labelGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'label',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AlarmIsarModel, AlarmIsarModel, QAfterFilterCondition>
  labelLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'label',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AlarmIsarModel, AlarmIsarModel, QAfterFilterCondition>
  labelBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'label',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AlarmIsarModel, AlarmIsarModel, QAfterFilterCondition>
  labelStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'label',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AlarmIsarModel, AlarmIsarModel, QAfterFilterCondition>
  labelEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'label',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AlarmIsarModel, AlarmIsarModel, QAfterFilterCondition>
  labelContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'label',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AlarmIsarModel, AlarmIsarModel, QAfterFilterCondition>
  labelMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'label',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AlarmIsarModel, AlarmIsarModel, QAfterFilterCondition>
  labelIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'label', value: ''),
      );
    });
  }

  QueryBuilder<AlarmIsarModel, AlarmIsarModel, QAfterFilterCondition>
  labelIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'label', value: ''),
      );
    });
  }

  QueryBuilder<AlarmIsarModel, AlarmIsarModel, QAfterFilterCondition>
  missionNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'missionName'),
      );
    });
  }

  QueryBuilder<AlarmIsarModel, AlarmIsarModel, QAfterFilterCondition>
  missionNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'missionName'),
      );
    });
  }

  QueryBuilder<AlarmIsarModel, AlarmIsarModel, QAfterFilterCondition>
  missionNameEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'missionName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AlarmIsarModel, AlarmIsarModel, QAfterFilterCondition>
  missionNameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'missionName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AlarmIsarModel, AlarmIsarModel, QAfterFilterCondition>
  missionNameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'missionName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AlarmIsarModel, AlarmIsarModel, QAfterFilterCondition>
  missionNameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'missionName',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AlarmIsarModel, AlarmIsarModel, QAfterFilterCondition>
  missionNameStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'missionName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AlarmIsarModel, AlarmIsarModel, QAfterFilterCondition>
  missionNameEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'missionName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AlarmIsarModel, AlarmIsarModel, QAfterFilterCondition>
  missionNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'missionName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AlarmIsarModel, AlarmIsarModel, QAfterFilterCondition>
  missionNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'missionName',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AlarmIsarModel, AlarmIsarModel, QAfterFilterCondition>
  missionNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'missionName', value: ''),
      );
    });
  }

  QueryBuilder<AlarmIsarModel, AlarmIsarModel, QAfterFilterCondition>
  missionNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'missionName', value: ''),
      );
    });
  }

  QueryBuilder<AlarmIsarModel, AlarmIsarModel, QAfterFilterCondition>
  repeatWeekdaysElementEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'repeatWeekdays', value: value),
      );
    });
  }

  QueryBuilder<AlarmIsarModel, AlarmIsarModel, QAfterFilterCondition>
  repeatWeekdaysElementGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'repeatWeekdays',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<AlarmIsarModel, AlarmIsarModel, QAfterFilterCondition>
  repeatWeekdaysElementLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'repeatWeekdays',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<AlarmIsarModel, AlarmIsarModel, QAfterFilterCondition>
  repeatWeekdaysElementBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'repeatWeekdays',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<AlarmIsarModel, AlarmIsarModel, QAfterFilterCondition>
  repeatWeekdaysLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'repeatWeekdays', length, true, length, true);
    });
  }

  QueryBuilder<AlarmIsarModel, AlarmIsarModel, QAfterFilterCondition>
  repeatWeekdaysIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'repeatWeekdays', 0, true, 0, true);
    });
  }

  QueryBuilder<AlarmIsarModel, AlarmIsarModel, QAfterFilterCondition>
  repeatWeekdaysIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'repeatWeekdays', 0, false, 999999, true);
    });
  }

  QueryBuilder<AlarmIsarModel, AlarmIsarModel, QAfterFilterCondition>
  repeatWeekdaysLengthLessThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'repeatWeekdays', 0, true, length, include);
    });
  }

  QueryBuilder<AlarmIsarModel, AlarmIsarModel, QAfterFilterCondition>
  repeatWeekdaysLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'repeatWeekdays', length, include, 999999, true);
    });
  }

  QueryBuilder<AlarmIsarModel, AlarmIsarModel, QAfterFilterCondition>
  repeatWeekdaysLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'repeatWeekdays',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<AlarmIsarModel, AlarmIsarModel, QAfterFilterCondition>
  ringtoneIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'ringtoneId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AlarmIsarModel, AlarmIsarModel, QAfterFilterCondition>
  ringtoneIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'ringtoneId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AlarmIsarModel, AlarmIsarModel, QAfterFilterCondition>
  ringtoneIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'ringtoneId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AlarmIsarModel, AlarmIsarModel, QAfterFilterCondition>
  ringtoneIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'ringtoneId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AlarmIsarModel, AlarmIsarModel, QAfterFilterCondition>
  ringtoneIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'ringtoneId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AlarmIsarModel, AlarmIsarModel, QAfterFilterCondition>
  ringtoneIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'ringtoneId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AlarmIsarModel, AlarmIsarModel, QAfterFilterCondition>
  ringtoneIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'ringtoneId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AlarmIsarModel, AlarmIsarModel, QAfterFilterCondition>
  ringtoneIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'ringtoneId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AlarmIsarModel, AlarmIsarModel, QAfterFilterCondition>
  ringtoneIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'ringtoneId', value: ''),
      );
    });
  }

  QueryBuilder<AlarmIsarModel, AlarmIsarModel, QAfterFilterCondition>
  ringtoneIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'ringtoneId', value: ''),
      );
    });
  }

  QueryBuilder<AlarmIsarModel, AlarmIsarModel, QAfterFilterCondition>
  timeEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'time', value: value),
      );
    });
  }

  QueryBuilder<AlarmIsarModel, AlarmIsarModel, QAfterFilterCondition>
  timeGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'time',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<AlarmIsarModel, AlarmIsarModel, QAfterFilterCondition>
  timeLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'time',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<AlarmIsarModel, AlarmIsarModel, QAfterFilterCondition>
  timeBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'time',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension AlarmIsarModelQueryObject
    on QueryBuilder<AlarmIsarModel, AlarmIsarModel, QFilterCondition> {}

extension AlarmIsarModelQueryLinks
    on QueryBuilder<AlarmIsarModel, AlarmIsarModel, QFilterCondition> {}

extension AlarmIsarModelQuerySortBy
    on QueryBuilder<AlarmIsarModel, AlarmIsarModel, QSortBy> {
  QueryBuilder<AlarmIsarModel, AlarmIsarModel, QAfterSortBy> sortByAlarmId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'alarmId', Sort.asc);
    });
  }

  QueryBuilder<AlarmIsarModel, AlarmIsarModel, QAfterSortBy>
  sortByAlarmIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'alarmId', Sort.desc);
    });
  }

  QueryBuilder<AlarmIsarModel, AlarmIsarModel, QAfterSortBy>
  sortByAudioTrackId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'audioTrackId', Sort.asc);
    });
  }

  QueryBuilder<AlarmIsarModel, AlarmIsarModel, QAfterSortBy>
  sortByAudioTrackIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'audioTrackId', Sort.desc);
    });
  }

  QueryBuilder<AlarmIsarModel, AlarmIsarModel, QAfterSortBy> sortByEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'enabled', Sort.asc);
    });
  }

  QueryBuilder<AlarmIsarModel, AlarmIsarModel, QAfterSortBy>
  sortByEnabledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'enabled', Sort.desc);
    });
  }

  QueryBuilder<AlarmIsarModel, AlarmIsarModel, QAfterSortBy> sortByLabel() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'label', Sort.asc);
    });
  }

  QueryBuilder<AlarmIsarModel, AlarmIsarModel, QAfterSortBy> sortByLabelDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'label', Sort.desc);
    });
  }

  QueryBuilder<AlarmIsarModel, AlarmIsarModel, QAfterSortBy>
  sortByMissionName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'missionName', Sort.asc);
    });
  }

  QueryBuilder<AlarmIsarModel, AlarmIsarModel, QAfterSortBy>
  sortByMissionNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'missionName', Sort.desc);
    });
  }

  QueryBuilder<AlarmIsarModel, AlarmIsarModel, QAfterSortBy>
  sortByRingtoneId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ringtoneId', Sort.asc);
    });
  }

  QueryBuilder<AlarmIsarModel, AlarmIsarModel, QAfterSortBy>
  sortByRingtoneIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ringtoneId', Sort.desc);
    });
  }

  QueryBuilder<AlarmIsarModel, AlarmIsarModel, QAfterSortBy> sortByTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'time', Sort.asc);
    });
  }

  QueryBuilder<AlarmIsarModel, AlarmIsarModel, QAfterSortBy> sortByTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'time', Sort.desc);
    });
  }
}

extension AlarmIsarModelQuerySortThenBy
    on QueryBuilder<AlarmIsarModel, AlarmIsarModel, QSortThenBy> {
  QueryBuilder<AlarmIsarModel, AlarmIsarModel, QAfterSortBy> thenByAlarmId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'alarmId', Sort.asc);
    });
  }

  QueryBuilder<AlarmIsarModel, AlarmIsarModel, QAfterSortBy>
  thenByAlarmIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'alarmId', Sort.desc);
    });
  }

  QueryBuilder<AlarmIsarModel, AlarmIsarModel, QAfterSortBy>
  thenByAudioTrackId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'audioTrackId', Sort.asc);
    });
  }

  QueryBuilder<AlarmIsarModel, AlarmIsarModel, QAfterSortBy>
  thenByAudioTrackIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'audioTrackId', Sort.desc);
    });
  }

  QueryBuilder<AlarmIsarModel, AlarmIsarModel, QAfterSortBy> thenByEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'enabled', Sort.asc);
    });
  }

  QueryBuilder<AlarmIsarModel, AlarmIsarModel, QAfterSortBy>
  thenByEnabledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'enabled', Sort.desc);
    });
  }

  QueryBuilder<AlarmIsarModel, AlarmIsarModel, QAfterSortBy> thenByIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.asc);
    });
  }

  QueryBuilder<AlarmIsarModel, AlarmIsarModel, QAfterSortBy>
  thenByIsarIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.desc);
    });
  }

  QueryBuilder<AlarmIsarModel, AlarmIsarModel, QAfterSortBy> thenByLabel() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'label', Sort.asc);
    });
  }

  QueryBuilder<AlarmIsarModel, AlarmIsarModel, QAfterSortBy> thenByLabelDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'label', Sort.desc);
    });
  }

  QueryBuilder<AlarmIsarModel, AlarmIsarModel, QAfterSortBy>
  thenByMissionName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'missionName', Sort.asc);
    });
  }

  QueryBuilder<AlarmIsarModel, AlarmIsarModel, QAfterSortBy>
  thenByMissionNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'missionName', Sort.desc);
    });
  }

  QueryBuilder<AlarmIsarModel, AlarmIsarModel, QAfterSortBy>
  thenByRingtoneId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ringtoneId', Sort.asc);
    });
  }

  QueryBuilder<AlarmIsarModel, AlarmIsarModel, QAfterSortBy>
  thenByRingtoneIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ringtoneId', Sort.desc);
    });
  }

  QueryBuilder<AlarmIsarModel, AlarmIsarModel, QAfterSortBy> thenByTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'time', Sort.asc);
    });
  }

  QueryBuilder<AlarmIsarModel, AlarmIsarModel, QAfterSortBy> thenByTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'time', Sort.desc);
    });
  }
}

extension AlarmIsarModelQueryWhereDistinct
    on QueryBuilder<AlarmIsarModel, AlarmIsarModel, QDistinct> {
  QueryBuilder<AlarmIsarModel, AlarmIsarModel, QDistinct> distinctByAlarmId({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'alarmId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AlarmIsarModel, AlarmIsarModel, QDistinct>
  distinctByAudioTrackId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'audioTrackId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AlarmIsarModel, AlarmIsarModel, QDistinct> distinctByEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'enabled');
    });
  }

  QueryBuilder<AlarmIsarModel, AlarmIsarModel, QDistinct> distinctByLabel({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'label', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AlarmIsarModel, AlarmIsarModel, QDistinct>
  distinctByMissionName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'missionName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AlarmIsarModel, AlarmIsarModel, QDistinct>
  distinctByRepeatWeekdays() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'repeatWeekdays');
    });
  }

  QueryBuilder<AlarmIsarModel, AlarmIsarModel, QDistinct> distinctByRingtoneId({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'ringtoneId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AlarmIsarModel, AlarmIsarModel, QDistinct> distinctByTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'time');
    });
  }
}

extension AlarmIsarModelQueryProperty
    on QueryBuilder<AlarmIsarModel, AlarmIsarModel, QQueryProperty> {
  QueryBuilder<AlarmIsarModel, int, QQueryOperations> isarIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isarId');
    });
  }

  QueryBuilder<AlarmIsarModel, String, QQueryOperations> alarmIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'alarmId');
    });
  }

  QueryBuilder<AlarmIsarModel, String, QQueryOperations>
  audioTrackIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'audioTrackId');
    });
  }

  QueryBuilder<AlarmIsarModel, bool, QQueryOperations> enabledProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'enabled');
    });
  }

  QueryBuilder<AlarmIsarModel, String?, QQueryOperations> labelProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'label');
    });
  }

  QueryBuilder<AlarmIsarModel, String?, QQueryOperations>
  missionNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'missionName');
    });
  }

  QueryBuilder<AlarmIsarModel, List<int>, QQueryOperations>
  repeatWeekdaysProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'repeatWeekdays');
    });
  }

  QueryBuilder<AlarmIsarModel, String, QQueryOperations> ringtoneIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'ringtoneId');
    });
  }

  QueryBuilder<AlarmIsarModel, DateTime, QQueryOperations> timeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'time');
    });
  }
}
