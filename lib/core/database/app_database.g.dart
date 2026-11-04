// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $AlarmsTableTable extends AlarmsTable
    with TableInfo<$AlarmsTableTable, AlarmRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AlarmsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _alarmIdMeta = const VerificationMeta(
    'alarmId',
  );
  @override
  late final GeneratedColumn<String> alarmId = GeneratedColumn<String>(
    'alarm_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _enabledMeta = const VerificationMeta(
    'enabled',
  );
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
    'enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("enabled" IN (0, 1))',
    ),
  );
  static const VerificationMeta _timeMeta = const VerificationMeta('time');
  @override
  late final GeneratedColumn<DateTime> time = GeneratedColumn<DateTime>(
    'time',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<List<int>, String>
  repeatWeekdays = GeneratedColumn<String>(
    'repeat_weekdays',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  ).withConverter<List<int>>($AlarmsTableTable.$converterrepeatWeekdays);
  static const VerificationMeta _audioTrackIdMeta = const VerificationMeta(
    'audioTrackId',
  );
  @override
  late final GeneratedColumn<String> audioTrackId = GeneratedColumn<String>(
    'audio_track_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ringtoneIdMeta = const VerificationMeta(
    'ringtoneId',
  );
  @override
  late final GeneratedColumn<String> ringtoneId = GeneratedColumn<String>(
    'ringtone_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _missionNameMeta = const VerificationMeta(
    'missionName',
  );
  @override
  late final GeneratedColumn<String> missionName = GeneratedColumn<String>(
    'mission_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    alarmId,
    enabled,
    time,
    repeatWeekdays,
    audioTrackId,
    ringtoneId,
    label,
    missionName,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'alarms';
  @override
  VerificationContext validateIntegrity(
    Insertable<AlarmRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('alarm_id')) {
      context.handle(
        _alarmIdMeta,
        alarmId.isAcceptableOrUnknown(data['alarm_id']!, _alarmIdMeta),
      );
    } else if (isInserting) {
      context.missing(_alarmIdMeta);
    }
    if (data.containsKey('enabled')) {
      context.handle(
        _enabledMeta,
        enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta),
      );
    } else if (isInserting) {
      context.missing(_enabledMeta);
    }
    if (data.containsKey('time')) {
      context.handle(
        _timeMeta,
        time.isAcceptableOrUnknown(data['time']!, _timeMeta),
      );
    } else if (isInserting) {
      context.missing(_timeMeta);
    }
    if (data.containsKey('audio_track_id')) {
      context.handle(
        _audioTrackIdMeta,
        audioTrackId.isAcceptableOrUnknown(
          data['audio_track_id']!,
          _audioTrackIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_audioTrackIdMeta);
    }
    if (data.containsKey('ringtone_id')) {
      context.handle(
        _ringtoneIdMeta,
        ringtoneId.isAcceptableOrUnknown(data['ringtone_id']!, _ringtoneIdMeta),
      );
    } else if (isInserting) {
      context.missing(_ringtoneIdMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    }
    if (data.containsKey('mission_name')) {
      context.handle(
        _missionNameMeta,
        missionName.isAcceptableOrUnknown(
          data['mission_name']!,
          _missionNameMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {alarmId};
  @override
  AlarmRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AlarmRecord(
      alarmId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}alarm_id'],
      )!,
      enabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}enabled'],
      )!,
      time: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}time'],
      )!,
      repeatWeekdays: $AlarmsTableTable.$converterrepeatWeekdays.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}repeat_weekdays'],
        )!,
      ),
      audioTrackId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}audio_track_id'],
      )!,
      ringtoneId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ringtone_id'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      ),
      missionName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mission_name'],
      ),
    );
  }

  @override
  $AlarmsTableTable createAlias(String alias) {
    return $AlarmsTableTable(attachedDatabase, alias);
  }

  static TypeConverter<List<int>, String> $converterrepeatWeekdays =
      const WeekdaysConverter();
}

class AlarmRecord extends DataClass implements Insertable<AlarmRecord> {
  final String alarmId;
  final bool enabled;
  final DateTime time;
  final List<int> repeatWeekdays;
  final String audioTrackId;
  final String ringtoneId;
  final String? label;
  final String? missionName;
  const AlarmRecord({
    required this.alarmId,
    required this.enabled,
    required this.time,
    required this.repeatWeekdays,
    required this.audioTrackId,
    required this.ringtoneId,
    this.label,
    this.missionName,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['alarm_id'] = Variable<String>(alarmId);
    map['enabled'] = Variable<bool>(enabled);
    map['time'] = Variable<DateTime>(time);
    {
      map['repeat_weekdays'] = Variable<String>(
        $AlarmsTableTable.$converterrepeatWeekdays.toSql(repeatWeekdays),
      );
    }
    map['audio_track_id'] = Variable<String>(audioTrackId);
    map['ringtone_id'] = Variable<String>(ringtoneId);
    if (!nullToAbsent || label != null) {
      map['label'] = Variable<String>(label);
    }
    if (!nullToAbsent || missionName != null) {
      map['mission_name'] = Variable<String>(missionName);
    }
    return map;
  }

  AlarmsTableCompanion toCompanion(bool nullToAbsent) {
    return AlarmsTableCompanion(
      alarmId: Value(alarmId),
      enabled: Value(enabled),
      time: Value(time),
      repeatWeekdays: Value(repeatWeekdays),
      audioTrackId: Value(audioTrackId),
      ringtoneId: Value(ringtoneId),
      label: label == null && nullToAbsent
          ? const Value.absent()
          : Value(label),
      missionName: missionName == null && nullToAbsent
          ? const Value.absent()
          : Value(missionName),
    );
  }

  factory AlarmRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AlarmRecord(
      alarmId: serializer.fromJson<String>(json['alarmId']),
      enabled: serializer.fromJson<bool>(json['enabled']),
      time: serializer.fromJson<DateTime>(json['time']),
      repeatWeekdays: serializer.fromJson<List<int>>(json['repeatWeekdays']),
      audioTrackId: serializer.fromJson<String>(json['audioTrackId']),
      ringtoneId: serializer.fromJson<String>(json['ringtoneId']),
      label: serializer.fromJson<String?>(json['label']),
      missionName: serializer.fromJson<String?>(json['missionName']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'alarmId': serializer.toJson<String>(alarmId),
      'enabled': serializer.toJson<bool>(enabled),
      'time': serializer.toJson<DateTime>(time),
      'repeatWeekdays': serializer.toJson<List<int>>(repeatWeekdays),
      'audioTrackId': serializer.toJson<String>(audioTrackId),
      'ringtoneId': serializer.toJson<String>(ringtoneId),
      'label': serializer.toJson<String?>(label),
      'missionName': serializer.toJson<String?>(missionName),
    };
  }

  AlarmRecord copyWith({
    String? alarmId,
    bool? enabled,
    DateTime? time,
    List<int>? repeatWeekdays,
    String? audioTrackId,
    String? ringtoneId,
    Value<String?> label = const Value.absent(),
    Value<String?> missionName = const Value.absent(),
  }) => AlarmRecord(
    alarmId: alarmId ?? this.alarmId,
    enabled: enabled ?? this.enabled,
    time: time ?? this.time,
    repeatWeekdays: repeatWeekdays ?? this.repeatWeekdays,
    audioTrackId: audioTrackId ?? this.audioTrackId,
    ringtoneId: ringtoneId ?? this.ringtoneId,
    label: label.present ? label.value : this.label,
    missionName: missionName.present ? missionName.value : this.missionName,
  );
  AlarmRecord copyWithCompanion(AlarmsTableCompanion data) {
    return AlarmRecord(
      alarmId: data.alarmId.present ? data.alarmId.value : this.alarmId,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
      time: data.time.present ? data.time.value : this.time,
      repeatWeekdays: data.repeatWeekdays.present
          ? data.repeatWeekdays.value
          : this.repeatWeekdays,
      audioTrackId: data.audioTrackId.present
          ? data.audioTrackId.value
          : this.audioTrackId,
      ringtoneId: data.ringtoneId.present
          ? data.ringtoneId.value
          : this.ringtoneId,
      label: data.label.present ? data.label.value : this.label,
      missionName: data.missionName.present
          ? data.missionName.value
          : this.missionName,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AlarmRecord(')
          ..write('alarmId: $alarmId, ')
          ..write('enabled: $enabled, ')
          ..write('time: $time, ')
          ..write('repeatWeekdays: $repeatWeekdays, ')
          ..write('audioTrackId: $audioTrackId, ')
          ..write('ringtoneId: $ringtoneId, ')
          ..write('label: $label, ')
          ..write('missionName: $missionName')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    alarmId,
    enabled,
    time,
    repeatWeekdays,
    audioTrackId,
    ringtoneId,
    label,
    missionName,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AlarmRecord &&
          other.alarmId == this.alarmId &&
          other.enabled == this.enabled &&
          other.time == this.time &&
          other.repeatWeekdays == this.repeatWeekdays &&
          other.audioTrackId == this.audioTrackId &&
          other.ringtoneId == this.ringtoneId &&
          other.label == this.label &&
          other.missionName == this.missionName);
}

class AlarmsTableCompanion extends UpdateCompanion<AlarmRecord> {
  final Value<String> alarmId;
  final Value<bool> enabled;
  final Value<DateTime> time;
  final Value<List<int>> repeatWeekdays;
  final Value<String> audioTrackId;
  final Value<String> ringtoneId;
  final Value<String?> label;
  final Value<String?> missionName;
  final Value<int> rowid;
  const AlarmsTableCompanion({
    this.alarmId = const Value.absent(),
    this.enabled = const Value.absent(),
    this.time = const Value.absent(),
    this.repeatWeekdays = const Value.absent(),
    this.audioTrackId = const Value.absent(),
    this.ringtoneId = const Value.absent(),
    this.label = const Value.absent(),
    this.missionName = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AlarmsTableCompanion.insert({
    required String alarmId,
    required bool enabled,
    required DateTime time,
    this.repeatWeekdays = const Value.absent(),
    required String audioTrackId,
    required String ringtoneId,
    this.label = const Value.absent(),
    this.missionName = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : alarmId = Value(alarmId),
       enabled = Value(enabled),
       time = Value(time),
       audioTrackId = Value(audioTrackId),
       ringtoneId = Value(ringtoneId);
  static Insertable<AlarmRecord> custom({
    Expression<String>? alarmId,
    Expression<bool>? enabled,
    Expression<DateTime>? time,
    Expression<String>? repeatWeekdays,
    Expression<String>? audioTrackId,
    Expression<String>? ringtoneId,
    Expression<String>? label,
    Expression<String>? missionName,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (alarmId != null) 'alarm_id': alarmId,
      if (enabled != null) 'enabled': enabled,
      if (time != null) 'time': time,
      if (repeatWeekdays != null) 'repeat_weekdays': repeatWeekdays,
      if (audioTrackId != null) 'audio_track_id': audioTrackId,
      if (ringtoneId != null) 'ringtone_id': ringtoneId,
      if (label != null) 'label': label,
      if (missionName != null) 'mission_name': missionName,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AlarmsTableCompanion copyWith({
    Value<String>? alarmId,
    Value<bool>? enabled,
    Value<DateTime>? time,
    Value<List<int>>? repeatWeekdays,
    Value<String>? audioTrackId,
    Value<String>? ringtoneId,
    Value<String?>? label,
    Value<String?>? missionName,
    Value<int>? rowid,
  }) {
    return AlarmsTableCompanion(
      alarmId: alarmId ?? this.alarmId,
      enabled: enabled ?? this.enabled,
      time: time ?? this.time,
      repeatWeekdays: repeatWeekdays ?? this.repeatWeekdays,
      audioTrackId: audioTrackId ?? this.audioTrackId,
      ringtoneId: ringtoneId ?? this.ringtoneId,
      label: label ?? this.label,
      missionName: missionName ?? this.missionName,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (alarmId.present) {
      map['alarm_id'] = Variable<String>(alarmId.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (time.present) {
      map['time'] = Variable<DateTime>(time.value);
    }
    if (repeatWeekdays.present) {
      map['repeat_weekdays'] = Variable<String>(
        $AlarmsTableTable.$converterrepeatWeekdays.toSql(repeatWeekdays.value),
      );
    }
    if (audioTrackId.present) {
      map['audio_track_id'] = Variable<String>(audioTrackId.value);
    }
    if (ringtoneId.present) {
      map['ringtone_id'] = Variable<String>(ringtoneId.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (missionName.present) {
      map['mission_name'] = Variable<String>(missionName.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AlarmsTableCompanion(')
          ..write('alarmId: $alarmId, ')
          ..write('enabled: $enabled, ')
          ..write('time: $time, ')
          ..write('repeatWeekdays: $repeatWeekdays, ')
          ..write('audioTrackId: $audioTrackId, ')
          ..write('ringtoneId: $ringtoneId, ')
          ..write('label: $label, ')
          ..write('missionName: $missionName, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $AlarmsTableTable alarmsTable = $AlarmsTableTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [alarmsTable];
}

typedef $$AlarmsTableTableCreateCompanionBuilder =
    AlarmsTableCompanion Function({
      required String alarmId,
      required bool enabled,
      required DateTime time,
      Value<List<int>> repeatWeekdays,
      required String audioTrackId,
      required String ringtoneId,
      Value<String?> label,
      Value<String?> missionName,
      Value<int> rowid,
    });
typedef $$AlarmsTableTableUpdateCompanionBuilder =
    AlarmsTableCompanion Function({
      Value<String> alarmId,
      Value<bool> enabled,
      Value<DateTime> time,
      Value<List<int>> repeatWeekdays,
      Value<String> audioTrackId,
      Value<String> ringtoneId,
      Value<String?> label,
      Value<String?> missionName,
      Value<int> rowid,
    });

class $$AlarmsTableTableFilterComposer
    extends Composer<_$AppDatabase, $AlarmsTableTable> {
  $$AlarmsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get alarmId => $composableBuilder(
    column: $table.alarmId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get time => $composableBuilder(
    column: $table.time,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<List<int>, List<int>, String>
  get repeatWeekdays => $composableBuilder(
    column: $table.repeatWeekdays,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get audioTrackId => $composableBuilder(
    column: $table.audioTrackId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ringtoneId => $composableBuilder(
    column: $table.ringtoneId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get missionName => $composableBuilder(
    column: $table.missionName,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AlarmsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $AlarmsTableTable> {
  $$AlarmsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get alarmId => $composableBuilder(
    column: $table.alarmId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get time => $composableBuilder(
    column: $table.time,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get repeatWeekdays => $composableBuilder(
    column: $table.repeatWeekdays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get audioTrackId => $composableBuilder(
    column: $table.audioTrackId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ringtoneId => $composableBuilder(
    column: $table.ringtoneId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get missionName => $composableBuilder(
    column: $table.missionName,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AlarmsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $AlarmsTableTable> {
  $$AlarmsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get alarmId =>
      $composableBuilder(column: $table.alarmId, builder: (column) => column);

  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);

  GeneratedColumn<DateTime> get time =>
      $composableBuilder(column: $table.time, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<int>, String> get repeatWeekdays =>
      $composableBuilder(
        column: $table.repeatWeekdays,
        builder: (column) => column,
      );

  GeneratedColumn<String> get audioTrackId => $composableBuilder(
    column: $table.audioTrackId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get ringtoneId => $composableBuilder(
    column: $table.ringtoneId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<String> get missionName => $composableBuilder(
    column: $table.missionName,
    builder: (column) => column,
  );
}

class $$AlarmsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AlarmsTableTable,
          AlarmRecord,
          $$AlarmsTableTableFilterComposer,
          $$AlarmsTableTableOrderingComposer,
          $$AlarmsTableTableAnnotationComposer,
          $$AlarmsTableTableCreateCompanionBuilder,
          $$AlarmsTableTableUpdateCompanionBuilder,
          (
            AlarmRecord,
            BaseReferences<_$AppDatabase, $AlarmsTableTable, AlarmRecord>,
          ),
          AlarmRecord,
          PrefetchHooks Function()
        > {
  $$AlarmsTableTableTableManager(_$AppDatabase db, $AlarmsTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AlarmsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AlarmsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AlarmsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> alarmId = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<DateTime> time = const Value.absent(),
                Value<List<int>> repeatWeekdays = const Value.absent(),
                Value<String> audioTrackId = const Value.absent(),
                Value<String> ringtoneId = const Value.absent(),
                Value<String?> label = const Value.absent(),
                Value<String?> missionName = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AlarmsTableCompanion(
                alarmId: alarmId,
                enabled: enabled,
                time: time,
                repeatWeekdays: repeatWeekdays,
                audioTrackId: audioTrackId,
                ringtoneId: ringtoneId,
                label: label,
                missionName: missionName,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String alarmId,
                required bool enabled,
                required DateTime time,
                Value<List<int>> repeatWeekdays = const Value.absent(),
                required String audioTrackId,
                required String ringtoneId,
                Value<String?> label = const Value.absent(),
                Value<String?> missionName = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AlarmsTableCompanion.insert(
                alarmId: alarmId,
                enabled: enabled,
                time: time,
                repeatWeekdays: repeatWeekdays,
                audioTrackId: audioTrackId,
                ringtoneId: ringtoneId,
                label: label,
                missionName: missionName,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AlarmsTableTable, AlarmRecord>(table),
                  BaseReferences<_$AppDatabase, $AlarmsTableTable, AlarmRecord>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AlarmsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AlarmsTableTable,
      AlarmRecord,
      $$AlarmsTableTableFilterComposer,
      $$AlarmsTableTableOrderingComposer,
      $$AlarmsTableTableAnnotationComposer,
      $$AlarmsTableTableCreateCompanionBuilder,
      $$AlarmsTableTableUpdateCompanionBuilder,
      (
        AlarmRecord,
        BaseReferences<_$AppDatabase, $AlarmsTableTable, AlarmRecord>,
      ),
      AlarmRecord,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$AlarmsTableTableTableManager get alarmsTable =>
      $$AlarmsTableTableTableManager(_db, _db.alarmsTable);
}
