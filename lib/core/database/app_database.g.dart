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

class $ReasonsTableTable extends ReasonsTable
    with TableInfo<$ReasonsTableTable, ReasonRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReasonsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _reasonIdMeta = const VerificationMeta(
    'reasonId',
  );
  @override
  late final GeneratedColumn<String> reasonId = GeneratedColumn<String>(
    'reason_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _areaNameMeta = const VerificationMeta(
    'areaName',
  );
  @override
  late final GeneratedColumn<String> areaName = GeneratedColumn<String>(
    'area_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _areaColorMeta = const VerificationMeta(
    'areaColor',
  );
  @override
  late final GeneratedColumn<int> areaColor = GeneratedColumn<int>(
    'area_color',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _toneNameMeta = const VerificationMeta(
    'toneName',
  );
  @override
  late final GeneratedColumn<String> toneName = GeneratedColumn<String>(
    'tone_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    reasonId,
    name,
    areaName,
    areaColor,
    toneName,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reasons';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReasonRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('reason_id')) {
      context.handle(
        _reasonIdMeta,
        reasonId.isAcceptableOrUnknown(data['reason_id']!, _reasonIdMeta),
      );
    } else if (isInserting) {
      context.missing(_reasonIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('area_name')) {
      context.handle(
        _areaNameMeta,
        areaName.isAcceptableOrUnknown(data['area_name']!, _areaNameMeta),
      );
    } else if (isInserting) {
      context.missing(_areaNameMeta);
    }
    if (data.containsKey('area_color')) {
      context.handle(
        _areaColorMeta,
        areaColor.isAcceptableOrUnknown(data['area_color']!, _areaColorMeta),
      );
    }
    if (data.containsKey('tone_name')) {
      context.handle(
        _toneNameMeta,
        toneName.isAcceptableOrUnknown(data['tone_name']!, _toneNameMeta),
      );
    } else if (isInserting) {
      context.missing(_toneNameMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {reasonId};
  @override
  ReasonRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReasonRecord(
      reasonId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      areaName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}area_name'],
      )!,
      areaColor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}area_color'],
      ),
      toneName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tone_name'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ReasonsTableTable createAlias(String alias) {
    return $ReasonsTableTable(attachedDatabase, alias);
  }
}

class ReasonRecord extends DataClass implements Insertable<ReasonRecord> {
  final String reasonId;
  final String name;
  final String areaName;
  final int? areaColor;
  final String toneName;
  final DateTime createdAt;
  const ReasonRecord({
    required this.reasonId,
    required this.name,
    required this.areaName,
    this.areaColor,
    required this.toneName,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['reason_id'] = Variable<String>(reasonId);
    map['name'] = Variable<String>(name);
    map['area_name'] = Variable<String>(areaName);
    if (!nullToAbsent || areaColor != null) {
      map['area_color'] = Variable<int>(areaColor);
    }
    map['tone_name'] = Variable<String>(toneName);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ReasonsTableCompanion toCompanion(bool nullToAbsent) {
    return ReasonsTableCompanion(
      reasonId: Value(reasonId),
      name: Value(name),
      areaName: Value(areaName),
      areaColor: areaColor == null && nullToAbsent
          ? const Value.absent()
          : Value(areaColor),
      toneName: Value(toneName),
      createdAt: Value(createdAt),
    );
  }

  factory ReasonRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReasonRecord(
      reasonId: serializer.fromJson<String>(json['reasonId']),
      name: serializer.fromJson<String>(json['name']),
      areaName: serializer.fromJson<String>(json['areaName']),
      areaColor: serializer.fromJson<int?>(json['areaColor']),
      toneName: serializer.fromJson<String>(json['toneName']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'reasonId': serializer.toJson<String>(reasonId),
      'name': serializer.toJson<String>(name),
      'areaName': serializer.toJson<String>(areaName),
      'areaColor': serializer.toJson<int?>(areaColor),
      'toneName': serializer.toJson<String>(toneName),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ReasonRecord copyWith({
    String? reasonId,
    String? name,
    String? areaName,
    Value<int?> areaColor = const Value.absent(),
    String? toneName,
    DateTime? createdAt,
  }) => ReasonRecord(
    reasonId: reasonId ?? this.reasonId,
    name: name ?? this.name,
    areaName: areaName ?? this.areaName,
    areaColor: areaColor.present ? areaColor.value : this.areaColor,
    toneName: toneName ?? this.toneName,
    createdAt: createdAt ?? this.createdAt,
  );
  ReasonRecord copyWithCompanion(ReasonsTableCompanion data) {
    return ReasonRecord(
      reasonId: data.reasonId.present ? data.reasonId.value : this.reasonId,
      name: data.name.present ? data.name.value : this.name,
      areaName: data.areaName.present ? data.areaName.value : this.areaName,
      areaColor: data.areaColor.present ? data.areaColor.value : this.areaColor,
      toneName: data.toneName.present ? data.toneName.value : this.toneName,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReasonRecord(')
          ..write('reasonId: $reasonId, ')
          ..write('name: $name, ')
          ..write('areaName: $areaName, ')
          ..write('areaColor: $areaColor, ')
          ..write('toneName: $toneName, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(reasonId, name, areaName, areaColor, toneName, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReasonRecord &&
          other.reasonId == this.reasonId &&
          other.name == this.name &&
          other.areaName == this.areaName &&
          other.areaColor == this.areaColor &&
          other.toneName == this.toneName &&
          other.createdAt == this.createdAt);
}

class ReasonsTableCompanion extends UpdateCompanion<ReasonRecord> {
  final Value<String> reasonId;
  final Value<String> name;
  final Value<String> areaName;
  final Value<int?> areaColor;
  final Value<String> toneName;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const ReasonsTableCompanion({
    this.reasonId = const Value.absent(),
    this.name = const Value.absent(),
    this.areaName = const Value.absent(),
    this.areaColor = const Value.absent(),
    this.toneName = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReasonsTableCompanion.insert({
    required String reasonId,
    required String name,
    required String areaName,
    this.areaColor = const Value.absent(),
    required String toneName,
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : reasonId = Value(reasonId),
       name = Value(name),
       areaName = Value(areaName),
       toneName = Value(toneName);
  static Insertable<ReasonRecord> custom({
    Expression<String>? reasonId,
    Expression<String>? name,
    Expression<String>? areaName,
    Expression<int>? areaColor,
    Expression<String>? toneName,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (reasonId != null) 'reason_id': reasonId,
      if (name != null) 'name': name,
      if (areaName != null) 'area_name': areaName,
      if (areaColor != null) 'area_color': areaColor,
      if (toneName != null) 'tone_name': toneName,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReasonsTableCompanion copyWith({
    Value<String>? reasonId,
    Value<String>? name,
    Value<String>? areaName,
    Value<int?>? areaColor,
    Value<String>? toneName,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return ReasonsTableCompanion(
      reasonId: reasonId ?? this.reasonId,
      name: name ?? this.name,
      areaName: areaName ?? this.areaName,
      areaColor: areaColor ?? this.areaColor,
      toneName: toneName ?? this.toneName,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (reasonId.present) {
      map['reason_id'] = Variable<String>(reasonId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (areaName.present) {
      map['area_name'] = Variable<String>(areaName.value);
    }
    if (areaColor.present) {
      map['area_color'] = Variable<int>(areaColor.value);
    }
    if (toneName.present) {
      map['tone_name'] = Variable<String>(toneName.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReasonsTableCompanion(')
          ..write('reasonId: $reasonId, ')
          ..write('name: $name, ')
          ..write('areaName: $areaName, ')
          ..write('areaColor: $areaColor, ')
          ..write('toneName: $toneName, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SettingsTableTable extends SettingsTable
    with TableInfo<$SettingsTableTable, SettingsRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _notifyBillingMeta = const VerificationMeta(
    'notifyBilling',
  );
  @override
  late final GeneratedColumn<bool> notifyBilling = GeneratedColumn<bool>(
    'notify_billing',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("notify_billing" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _notifyAlarmsMeta = const VerificationMeta(
    'notifyAlarms',
  );
  @override
  late final GeneratedColumn<bool> notifyAlarms = GeneratedColumn<bool>(
    'notify_alarms',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("notify_alarms" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _notifyQuotesMeta = const VerificationMeta(
    'notifyQuotes',
  );
  @override
  late final GeneratedColumn<bool> notifyQuotes = GeneratedColumn<bool>(
    'notify_quotes',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("notify_quotes" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    notifyBilling,
    notifyAlarms,
    notifyQuotes,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<SettingsRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('notify_billing')) {
      context.handle(
        _notifyBillingMeta,
        notifyBilling.isAcceptableOrUnknown(
          data['notify_billing']!,
          _notifyBillingMeta,
        ),
      );
    }
    if (data.containsKey('notify_alarms')) {
      context.handle(
        _notifyAlarmsMeta,
        notifyAlarms.isAcceptableOrUnknown(
          data['notify_alarms']!,
          _notifyAlarmsMeta,
        ),
      );
    }
    if (data.containsKey('notify_quotes')) {
      context.handle(
        _notifyQuotesMeta,
        notifyQuotes.isAcceptableOrUnknown(
          data['notify_quotes']!,
          _notifyQuotesMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SettingsRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SettingsRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      notifyBilling: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}notify_billing'],
      )!,
      notifyAlarms: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}notify_alarms'],
      )!,
      notifyQuotes: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}notify_quotes'],
      )!,
    );
  }

  @override
  $SettingsTableTable createAlias(String alias) {
    return $SettingsTableTable(attachedDatabase, alias);
  }
}

class SettingsRecord extends DataClass implements Insertable<SettingsRecord> {
  final int id;
  final bool notifyBilling;
  final bool notifyAlarms;
  final bool notifyQuotes;
  const SettingsRecord({
    required this.id,
    required this.notifyBilling,
    required this.notifyAlarms,
    required this.notifyQuotes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['notify_billing'] = Variable<bool>(notifyBilling);
    map['notify_alarms'] = Variable<bool>(notifyAlarms);
    map['notify_quotes'] = Variable<bool>(notifyQuotes);
    return map;
  }

  SettingsTableCompanion toCompanion(bool nullToAbsent) {
    return SettingsTableCompanion(
      id: Value(id),
      notifyBilling: Value(notifyBilling),
      notifyAlarms: Value(notifyAlarms),
      notifyQuotes: Value(notifyQuotes),
    );
  }

  factory SettingsRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettingsRecord(
      id: serializer.fromJson<int>(json['id']),
      notifyBilling: serializer.fromJson<bool>(json['notifyBilling']),
      notifyAlarms: serializer.fromJson<bool>(json['notifyAlarms']),
      notifyQuotes: serializer.fromJson<bool>(json['notifyQuotes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'notifyBilling': serializer.toJson<bool>(notifyBilling),
      'notifyAlarms': serializer.toJson<bool>(notifyAlarms),
      'notifyQuotes': serializer.toJson<bool>(notifyQuotes),
    };
  }

  SettingsRecord copyWith({
    int? id,
    bool? notifyBilling,
    bool? notifyAlarms,
    bool? notifyQuotes,
  }) => SettingsRecord(
    id: id ?? this.id,
    notifyBilling: notifyBilling ?? this.notifyBilling,
    notifyAlarms: notifyAlarms ?? this.notifyAlarms,
    notifyQuotes: notifyQuotes ?? this.notifyQuotes,
  );
  SettingsRecord copyWithCompanion(SettingsTableCompanion data) {
    return SettingsRecord(
      id: data.id.present ? data.id.value : this.id,
      notifyBilling: data.notifyBilling.present
          ? data.notifyBilling.value
          : this.notifyBilling,
      notifyAlarms: data.notifyAlarms.present
          ? data.notifyAlarms.value
          : this.notifyAlarms,
      notifyQuotes: data.notifyQuotes.present
          ? data.notifyQuotes.value
          : this.notifyQuotes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettingsRecord(')
          ..write('id: $id, ')
          ..write('notifyBilling: $notifyBilling, ')
          ..write('notifyAlarms: $notifyAlarms, ')
          ..write('notifyQuotes: $notifyQuotes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, notifyBilling, notifyAlarms, notifyQuotes);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SettingsRecord &&
          other.id == this.id &&
          other.notifyBilling == this.notifyBilling &&
          other.notifyAlarms == this.notifyAlarms &&
          other.notifyQuotes == this.notifyQuotes);
}

class SettingsTableCompanion extends UpdateCompanion<SettingsRecord> {
  final Value<int> id;
  final Value<bool> notifyBilling;
  final Value<bool> notifyAlarms;
  final Value<bool> notifyQuotes;
  const SettingsTableCompanion({
    this.id = const Value.absent(),
    this.notifyBilling = const Value.absent(),
    this.notifyAlarms = const Value.absent(),
    this.notifyQuotes = const Value.absent(),
  });
  SettingsTableCompanion.insert({
    this.id = const Value.absent(),
    this.notifyBilling = const Value.absent(),
    this.notifyAlarms = const Value.absent(),
    this.notifyQuotes = const Value.absent(),
  });
  static Insertable<SettingsRecord> custom({
    Expression<int>? id,
    Expression<bool>? notifyBilling,
    Expression<bool>? notifyAlarms,
    Expression<bool>? notifyQuotes,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (notifyBilling != null) 'notify_billing': notifyBilling,
      if (notifyAlarms != null) 'notify_alarms': notifyAlarms,
      if (notifyQuotes != null) 'notify_quotes': notifyQuotes,
    });
  }

  SettingsTableCompanion copyWith({
    Value<int>? id,
    Value<bool>? notifyBilling,
    Value<bool>? notifyAlarms,
    Value<bool>? notifyQuotes,
  }) {
    return SettingsTableCompanion(
      id: id ?? this.id,
      notifyBilling: notifyBilling ?? this.notifyBilling,
      notifyAlarms: notifyAlarms ?? this.notifyAlarms,
      notifyQuotes: notifyQuotes ?? this.notifyQuotes,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (notifyBilling.present) {
      map['notify_billing'] = Variable<bool>(notifyBilling.value);
    }
    if (notifyAlarms.present) {
      map['notify_alarms'] = Variable<bool>(notifyAlarms.value);
    }
    if (notifyQuotes.present) {
      map['notify_quotes'] = Variable<bool>(notifyQuotes.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsTableCompanion(')
          ..write('id: $id, ')
          ..write('notifyBilling: $notifyBilling, ')
          ..write('notifyAlarms: $notifyAlarms, ')
          ..write('notifyQuotes: $notifyQuotes')
          ..write(')'))
        .toString();
  }
}

class $AreasOfLifeTableTable extends AreasOfLifeTable
    with TableInfo<$AreasOfLifeTableTable, AreaOfLifeRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AreasOfLifeTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
    'icon',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<int> color = GeneratedColumn<int>(
    'color',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    title,
    description,
    icon,
    color,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'areas_of_life';
  @override
  VerificationContext validateIntegrity(
    Insertable<AreaOfLifeRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('icon')) {
      context.handle(
        _iconMeta,
        icon.isAcceptableOrUnknown(data['icon']!, _iconMeta),
      );
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AreaOfLifeRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AreaOfLifeRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      icon: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon'],
      ),
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color'],
      ),
    );
  }

  @override
  $AreasOfLifeTableTable createAlias(String alias) {
    return $AreasOfLifeTableTable(attachedDatabase, alias);
  }
}

class AreaOfLifeRecord extends DataClass
    implements Insertable<AreaOfLifeRecord> {
  final int id;
  final String name;
  final String title;
  final String? description;
  final String? icon;
  final int? color;
  const AreaOfLifeRecord({
    required this.id,
    required this.name,
    required this.title,
    this.description,
    this.icon,
    this.color,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || icon != null) {
      map['icon'] = Variable<String>(icon);
    }
    if (!nullToAbsent || color != null) {
      map['color'] = Variable<int>(color);
    }
    return map;
  }

  AreasOfLifeTableCompanion toCompanion(bool nullToAbsent) {
    return AreasOfLifeTableCompanion(
      id: Value(id),
      name: Value(name),
      title: Value(title),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      icon: icon == null && nullToAbsent ? const Value.absent() : Value(icon),
      color: color == null && nullToAbsent
          ? const Value.absent()
          : Value(color),
    );
  }

  factory AreaOfLifeRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AreaOfLifeRecord(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
      icon: serializer.fromJson<String?>(json['icon']),
      color: serializer.fromJson<int?>(json['color']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String?>(description),
      'icon': serializer.toJson<String?>(icon),
      'color': serializer.toJson<int?>(color),
    };
  }

  AreaOfLifeRecord copyWith({
    int? id,
    String? name,
    String? title,
    Value<String?> description = const Value.absent(),
    Value<String?> icon = const Value.absent(),
    Value<int?> color = const Value.absent(),
  }) => AreaOfLifeRecord(
    id: id ?? this.id,
    name: name ?? this.name,
    title: title ?? this.title,
    description: description.present ? description.value : this.description,
    icon: icon.present ? icon.value : this.icon,
    color: color.present ? color.value : this.color,
  );
  AreaOfLifeRecord copyWithCompanion(AreasOfLifeTableCompanion data) {
    return AreaOfLifeRecord(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
      icon: data.icon.present ? data.icon.value : this.icon,
      color: data.color.present ? data.color.value : this.color,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AreaOfLifeRecord(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('icon: $icon, ')
          ..write('color: $color')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, title, description, icon, color);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AreaOfLifeRecord &&
          other.id == this.id &&
          other.name == this.name &&
          other.title == this.title &&
          other.description == this.description &&
          other.icon == this.icon &&
          other.color == this.color);
}

class AreasOfLifeTableCompanion extends UpdateCompanion<AreaOfLifeRecord> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> title;
  final Value<String?> description;
  final Value<String?> icon;
  final Value<int?> color;
  const AreasOfLifeTableCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.icon = const Value.absent(),
    this.color = const Value.absent(),
  });
  AreasOfLifeTableCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String title,
    this.description = const Value.absent(),
    this.icon = const Value.absent(),
    this.color = const Value.absent(),
  }) : name = Value(name),
       title = Value(title);
  static Insertable<AreaOfLifeRecord> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? title,
    Expression<String>? description,
    Expression<String>? icon,
    Expression<int>? color,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (icon != null) 'icon': icon,
      if (color != null) 'color': color,
    });
  }

  AreasOfLifeTableCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? title,
    Value<String?>? description,
    Value<String?>? icon,
    Value<int?>? color,
  }) {
    return AreasOfLifeTableCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      title: title ?? this.title,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      color: color ?? this.color,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (color.present) {
      map['color'] = Variable<int>(color.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AreasOfLifeTableCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('icon: $icon, ')
          ..write('color: $color')
          ..write(')'))
        .toString();
  }
}

class $VoicesTableTable extends VoicesTable
    with TableInfo<$VoicesTableTable, VoiceRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VoicesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _voiceIdMeta = const VerificationMeta(
    'voiceId',
  );
  @override
  late final GeneratedColumn<String> voiceId = GeneratedColumn<String>(
    'voice_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _audioMeta = const VerificationMeta('audio');
  @override
  late final GeneratedColumn<String> audio = GeneratedColumn<String>(
    'audio',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _avatarMeta = const VerificationMeta('avatar');
  @override
  late final GeneratedColumn<String> avatar = GeneratedColumn<String>(
    'avatar',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _groupIdMeta = const VerificationMeta(
    'groupId',
  );
  @override
  late final GeneratedColumn<int> groupId = GeneratedColumn<int>(
    'group_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _groupTitleMeta = const VerificationMeta(
    'groupTitle',
  );
  @override
  late final GeneratedColumn<String> groupTitle = GeneratedColumn<String>(
    'group_title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _groupDescriptionMeta = const VerificationMeta(
    'groupDescription',
  );
  @override
  late final GeneratedColumn<String> groupDescription = GeneratedColumn<String>(
    'group_description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _genderMeta = const VerificationMeta('gender');
  @override
  late final GeneratedColumn<String> gender = GeneratedColumn<String>(
    'gender',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _accentMeta = const VerificationMeta('accent');
  @override
  late final GeneratedColumn<String> accent = GeneratedColumn<String>(
    'accent',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _traitsMeta = const VerificationMeta('traits');
  @override
  late final GeneratedColumn<String> traits = GeneratedColumn<String>(
    'traits',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<int> color = GeneratedColumn<int>(
    'color',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isPremiumMeta = const VerificationMeta(
    'isPremium',
  );
  @override
  late final GeneratedColumn<bool> isPremium = GeneratedColumn<bool>(
    'is_premium',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_premium" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    voiceId,
    audio,
    avatar,
    groupId,
    groupTitle,
    groupDescription,
    gender,
    accent,
    traits,
    color,
    isPremium,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'voices';
  @override
  VerificationContext validateIntegrity(
    Insertable<VoiceRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('voice_id')) {
      context.handle(
        _voiceIdMeta,
        voiceId.isAcceptableOrUnknown(data['voice_id']!, _voiceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_voiceIdMeta);
    }
    if (data.containsKey('audio')) {
      context.handle(
        _audioMeta,
        audio.isAcceptableOrUnknown(data['audio']!, _audioMeta),
      );
    }
    if (data.containsKey('avatar')) {
      context.handle(
        _avatarMeta,
        avatar.isAcceptableOrUnknown(data['avatar']!, _avatarMeta),
      );
    }
    if (data.containsKey('group_id')) {
      context.handle(
        _groupIdMeta,
        groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta),
      );
    }
    if (data.containsKey('group_title')) {
      context.handle(
        _groupTitleMeta,
        groupTitle.isAcceptableOrUnknown(data['group_title']!, _groupTitleMeta),
      );
    }
    if (data.containsKey('group_description')) {
      context.handle(
        _groupDescriptionMeta,
        groupDescription.isAcceptableOrUnknown(
          data['group_description']!,
          _groupDescriptionMeta,
        ),
      );
    }
    if (data.containsKey('gender')) {
      context.handle(
        _genderMeta,
        gender.isAcceptableOrUnknown(data['gender']!, _genderMeta),
      );
    }
    if (data.containsKey('accent')) {
      context.handle(
        _accentMeta,
        accent.isAcceptableOrUnknown(data['accent']!, _accentMeta),
      );
    }
    if (data.containsKey('traits')) {
      context.handle(
        _traitsMeta,
        traits.isAcceptableOrUnknown(data['traits']!, _traitsMeta),
      );
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    }
    if (data.containsKey('is_premium')) {
      context.handle(
        _isPremiumMeta,
        isPremium.isAcceptableOrUnknown(data['is_premium']!, _isPremiumMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  VoiceRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VoiceRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      voiceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}voice_id'],
      )!,
      audio: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}audio'],
      ),
      avatar: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}avatar'],
      ),
      groupId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}group_id'],
      ),
      groupTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_title'],
      ),
      groupDescription: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_description'],
      ),
      gender: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}gender'],
      ),
      accent: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}accent'],
      ),
      traits: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}traits'],
      ),
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color'],
      ),
      isPremium: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_premium'],
      )!,
    );
  }

  @override
  $VoicesTableTable createAlias(String alias) {
    return $VoicesTableTable(attachedDatabase, alias);
  }
}

class VoiceRecord extends DataClass implements Insertable<VoiceRecord> {
  final int id;
  final String name;
  final String voiceId;
  final String? audio;
  final String? avatar;
  final int? groupId;
  final String? groupTitle;
  final String? groupDescription;
  final String? gender;
  final String? accent;
  final String? traits;
  final int? color;
  final bool isPremium;
  const VoiceRecord({
    required this.id,
    required this.name,
    required this.voiceId,
    this.audio,
    this.avatar,
    this.groupId,
    this.groupTitle,
    this.groupDescription,
    this.gender,
    this.accent,
    this.traits,
    this.color,
    required this.isPremium,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['voice_id'] = Variable<String>(voiceId);
    if (!nullToAbsent || audio != null) {
      map['audio'] = Variable<String>(audio);
    }
    if (!nullToAbsent || avatar != null) {
      map['avatar'] = Variable<String>(avatar);
    }
    if (!nullToAbsent || groupId != null) {
      map['group_id'] = Variable<int>(groupId);
    }
    if (!nullToAbsent || groupTitle != null) {
      map['group_title'] = Variable<String>(groupTitle);
    }
    if (!nullToAbsent || groupDescription != null) {
      map['group_description'] = Variable<String>(groupDescription);
    }
    if (!nullToAbsent || gender != null) {
      map['gender'] = Variable<String>(gender);
    }
    if (!nullToAbsent || accent != null) {
      map['accent'] = Variable<String>(accent);
    }
    if (!nullToAbsent || traits != null) {
      map['traits'] = Variable<String>(traits);
    }
    if (!nullToAbsent || color != null) {
      map['color'] = Variable<int>(color);
    }
    map['is_premium'] = Variable<bool>(isPremium);
    return map;
  }

  VoicesTableCompanion toCompanion(bool nullToAbsent) {
    return VoicesTableCompanion(
      id: Value(id),
      name: Value(name),
      voiceId: Value(voiceId),
      audio: audio == null && nullToAbsent
          ? const Value.absent()
          : Value(audio),
      avatar: avatar == null && nullToAbsent
          ? const Value.absent()
          : Value(avatar),
      groupId: groupId == null && nullToAbsent
          ? const Value.absent()
          : Value(groupId),
      groupTitle: groupTitle == null && nullToAbsent
          ? const Value.absent()
          : Value(groupTitle),
      groupDescription: groupDescription == null && nullToAbsent
          ? const Value.absent()
          : Value(groupDescription),
      gender: gender == null && nullToAbsent
          ? const Value.absent()
          : Value(gender),
      accent: accent == null && nullToAbsent
          ? const Value.absent()
          : Value(accent),
      traits: traits == null && nullToAbsent
          ? const Value.absent()
          : Value(traits),
      color: color == null && nullToAbsent
          ? const Value.absent()
          : Value(color),
      isPremium: Value(isPremium),
    );
  }

  factory VoiceRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VoiceRecord(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      voiceId: serializer.fromJson<String>(json['voiceId']),
      audio: serializer.fromJson<String?>(json['audio']),
      avatar: serializer.fromJson<String?>(json['avatar']),
      groupId: serializer.fromJson<int?>(json['groupId']),
      groupTitle: serializer.fromJson<String?>(json['groupTitle']),
      groupDescription: serializer.fromJson<String?>(json['groupDescription']),
      gender: serializer.fromJson<String?>(json['gender']),
      accent: serializer.fromJson<String?>(json['accent']),
      traits: serializer.fromJson<String?>(json['traits']),
      color: serializer.fromJson<int?>(json['color']),
      isPremium: serializer.fromJson<bool>(json['isPremium']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'voiceId': serializer.toJson<String>(voiceId),
      'audio': serializer.toJson<String?>(audio),
      'avatar': serializer.toJson<String?>(avatar),
      'groupId': serializer.toJson<int?>(groupId),
      'groupTitle': serializer.toJson<String?>(groupTitle),
      'groupDescription': serializer.toJson<String?>(groupDescription),
      'gender': serializer.toJson<String?>(gender),
      'accent': serializer.toJson<String?>(accent),
      'traits': serializer.toJson<String?>(traits),
      'color': serializer.toJson<int?>(color),
      'isPremium': serializer.toJson<bool>(isPremium),
    };
  }

  VoiceRecord copyWith({
    int? id,
    String? name,
    String? voiceId,
    Value<String?> audio = const Value.absent(),
    Value<String?> avatar = const Value.absent(),
    Value<int?> groupId = const Value.absent(),
    Value<String?> groupTitle = const Value.absent(),
    Value<String?> groupDescription = const Value.absent(),
    Value<String?> gender = const Value.absent(),
    Value<String?> accent = const Value.absent(),
    Value<String?> traits = const Value.absent(),
    Value<int?> color = const Value.absent(),
    bool? isPremium,
  }) => VoiceRecord(
    id: id ?? this.id,
    name: name ?? this.name,
    voiceId: voiceId ?? this.voiceId,
    audio: audio.present ? audio.value : this.audio,
    avatar: avatar.present ? avatar.value : this.avatar,
    groupId: groupId.present ? groupId.value : this.groupId,
    groupTitle: groupTitle.present ? groupTitle.value : this.groupTitle,
    groupDescription: groupDescription.present
        ? groupDescription.value
        : this.groupDescription,
    gender: gender.present ? gender.value : this.gender,
    accent: accent.present ? accent.value : this.accent,
    traits: traits.present ? traits.value : this.traits,
    color: color.present ? color.value : this.color,
    isPremium: isPremium ?? this.isPremium,
  );
  VoiceRecord copyWithCompanion(VoicesTableCompanion data) {
    return VoiceRecord(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      voiceId: data.voiceId.present ? data.voiceId.value : this.voiceId,
      audio: data.audio.present ? data.audio.value : this.audio,
      avatar: data.avatar.present ? data.avatar.value : this.avatar,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      groupTitle: data.groupTitle.present
          ? data.groupTitle.value
          : this.groupTitle,
      groupDescription: data.groupDescription.present
          ? data.groupDescription.value
          : this.groupDescription,
      gender: data.gender.present ? data.gender.value : this.gender,
      accent: data.accent.present ? data.accent.value : this.accent,
      traits: data.traits.present ? data.traits.value : this.traits,
      color: data.color.present ? data.color.value : this.color,
      isPremium: data.isPremium.present ? data.isPremium.value : this.isPremium,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VoiceRecord(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('voiceId: $voiceId, ')
          ..write('audio: $audio, ')
          ..write('avatar: $avatar, ')
          ..write('groupId: $groupId, ')
          ..write('groupTitle: $groupTitle, ')
          ..write('groupDescription: $groupDescription, ')
          ..write('gender: $gender, ')
          ..write('accent: $accent, ')
          ..write('traits: $traits, ')
          ..write('color: $color, ')
          ..write('isPremium: $isPremium')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    voiceId,
    audio,
    avatar,
    groupId,
    groupTitle,
    groupDescription,
    gender,
    accent,
    traits,
    color,
    isPremium,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VoiceRecord &&
          other.id == this.id &&
          other.name == this.name &&
          other.voiceId == this.voiceId &&
          other.audio == this.audio &&
          other.avatar == this.avatar &&
          other.groupId == this.groupId &&
          other.groupTitle == this.groupTitle &&
          other.groupDescription == this.groupDescription &&
          other.gender == this.gender &&
          other.accent == this.accent &&
          other.traits == this.traits &&
          other.color == this.color &&
          other.isPremium == this.isPremium);
}

class VoicesTableCompanion extends UpdateCompanion<VoiceRecord> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> voiceId;
  final Value<String?> audio;
  final Value<String?> avatar;
  final Value<int?> groupId;
  final Value<String?> groupTitle;
  final Value<String?> groupDescription;
  final Value<String?> gender;
  final Value<String?> accent;
  final Value<String?> traits;
  final Value<int?> color;
  final Value<bool> isPremium;
  const VoicesTableCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.voiceId = const Value.absent(),
    this.audio = const Value.absent(),
    this.avatar = const Value.absent(),
    this.groupId = const Value.absent(),
    this.groupTitle = const Value.absent(),
    this.groupDescription = const Value.absent(),
    this.gender = const Value.absent(),
    this.accent = const Value.absent(),
    this.traits = const Value.absent(),
    this.color = const Value.absent(),
    this.isPremium = const Value.absent(),
  });
  VoicesTableCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String voiceId,
    this.audio = const Value.absent(),
    this.avatar = const Value.absent(),
    this.groupId = const Value.absent(),
    this.groupTitle = const Value.absent(),
    this.groupDescription = const Value.absent(),
    this.gender = const Value.absent(),
    this.accent = const Value.absent(),
    this.traits = const Value.absent(),
    this.color = const Value.absent(),
    this.isPremium = const Value.absent(),
  }) : name = Value(name),
       voiceId = Value(voiceId);
  static Insertable<VoiceRecord> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? voiceId,
    Expression<String>? audio,
    Expression<String>? avatar,
    Expression<int>? groupId,
    Expression<String>? groupTitle,
    Expression<String>? groupDescription,
    Expression<String>? gender,
    Expression<String>? accent,
    Expression<String>? traits,
    Expression<int>? color,
    Expression<bool>? isPremium,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (voiceId != null) 'voice_id': voiceId,
      if (audio != null) 'audio': audio,
      if (avatar != null) 'avatar': avatar,
      if (groupId != null) 'group_id': groupId,
      if (groupTitle != null) 'group_title': groupTitle,
      if (groupDescription != null) 'group_description': groupDescription,
      if (gender != null) 'gender': gender,
      if (accent != null) 'accent': accent,
      if (traits != null) 'traits': traits,
      if (color != null) 'color': color,
      if (isPremium != null) 'is_premium': isPremium,
    });
  }

  VoicesTableCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? voiceId,
    Value<String?>? audio,
    Value<String?>? avatar,
    Value<int?>? groupId,
    Value<String?>? groupTitle,
    Value<String?>? groupDescription,
    Value<String?>? gender,
    Value<String?>? accent,
    Value<String?>? traits,
    Value<int?>? color,
    Value<bool>? isPremium,
  }) {
    return VoicesTableCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      voiceId: voiceId ?? this.voiceId,
      audio: audio ?? this.audio,
      avatar: avatar ?? this.avatar,
      groupId: groupId ?? this.groupId,
      groupTitle: groupTitle ?? this.groupTitle,
      groupDescription: groupDescription ?? this.groupDescription,
      gender: gender ?? this.gender,
      accent: accent ?? this.accent,
      traits: traits ?? this.traits,
      color: color ?? this.color,
      isPremium: isPremium ?? this.isPremium,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (voiceId.present) {
      map['voice_id'] = Variable<String>(voiceId.value);
    }
    if (audio.present) {
      map['audio'] = Variable<String>(audio.value);
    }
    if (avatar.present) {
      map['avatar'] = Variable<String>(avatar.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<int>(groupId.value);
    }
    if (groupTitle.present) {
      map['group_title'] = Variable<String>(groupTitle.value);
    }
    if (groupDescription.present) {
      map['group_description'] = Variable<String>(groupDescription.value);
    }
    if (gender.present) {
      map['gender'] = Variable<String>(gender.value);
    }
    if (accent.present) {
      map['accent'] = Variable<String>(accent.value);
    }
    if (traits.present) {
      map['traits'] = Variable<String>(traits.value);
    }
    if (color.present) {
      map['color'] = Variable<int>(color.value);
    }
    if (isPremium.present) {
      map['is_premium'] = Variable<bool>(isPremium.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VoicesTableCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('voiceId: $voiceId, ')
          ..write('audio: $audio, ')
          ..write('avatar: $avatar, ')
          ..write('groupId: $groupId, ')
          ..write('groupTitle: $groupTitle, ')
          ..write('groupDescription: $groupDescription, ')
          ..write('gender: $gender, ')
          ..write('accent: $accent, ')
          ..write('traits: $traits, ')
          ..write('color: $color, ')
          ..write('isPremium: $isPremium')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $AlarmsTableTable alarmsTable = $AlarmsTableTable(this);
  late final $ReasonsTableTable reasonsTable = $ReasonsTableTable(this);
  late final $SettingsTableTable settingsTable = $SettingsTableTable(this);
  late final $AreasOfLifeTableTable areasOfLifeTable = $AreasOfLifeTableTable(
    this,
  );
  late final $VoicesTableTable voicesTable = $VoicesTableTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    alarmsTable,
    reasonsTable,
    settingsTable,
    areasOfLifeTable,
    voicesTable,
  ];
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
typedef $$ReasonsTableTableCreateCompanionBuilder =
    ReasonsTableCompanion Function({
      required String reasonId,
      required String name,
      required String areaName,
      Value<int?> areaColor,
      required String toneName,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$ReasonsTableTableUpdateCompanionBuilder =
    ReasonsTableCompanion Function({
      Value<String> reasonId,
      Value<String> name,
      Value<String> areaName,
      Value<int?> areaColor,
      Value<String> toneName,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$ReasonsTableTableFilterComposer
    extends Composer<_$AppDatabase, $ReasonsTableTable> {
  $$ReasonsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get reasonId => $composableBuilder(
    column: $table.reasonId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get areaName => $composableBuilder(
    column: $table.areaName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get areaColor => $composableBuilder(
    column: $table.areaColor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get toneName => $composableBuilder(
    column: $table.toneName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ReasonsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ReasonsTableTable> {
  $$ReasonsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get reasonId => $composableBuilder(
    column: $table.reasonId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get areaName => $composableBuilder(
    column: $table.areaName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get areaColor => $composableBuilder(
    column: $table.areaColor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get toneName => $composableBuilder(
    column: $table.toneName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ReasonsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReasonsTableTable> {
  $$ReasonsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get reasonId =>
      $composableBuilder(column: $table.reasonId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get areaName =>
      $composableBuilder(column: $table.areaName, builder: (column) => column);

  GeneratedColumn<int> get areaColor =>
      $composableBuilder(column: $table.areaColor, builder: (column) => column);

  GeneratedColumn<String> get toneName =>
      $composableBuilder(column: $table.toneName, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$ReasonsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReasonsTableTable,
          ReasonRecord,
          $$ReasonsTableTableFilterComposer,
          $$ReasonsTableTableOrderingComposer,
          $$ReasonsTableTableAnnotationComposer,
          $$ReasonsTableTableCreateCompanionBuilder,
          $$ReasonsTableTableUpdateCompanionBuilder,
          (
            ReasonRecord,
            BaseReferences<_$AppDatabase, $ReasonsTableTable, ReasonRecord>,
          ),
          ReasonRecord,
          PrefetchHooks Function()
        > {
  $$ReasonsTableTableTableManager(_$AppDatabase db, $ReasonsTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReasonsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReasonsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReasonsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> reasonId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> areaName = const Value.absent(),
                Value<int?> areaColor = const Value.absent(),
                Value<String> toneName = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReasonsTableCompanion(
                reasonId: reasonId,
                name: name,
                areaName: areaName,
                areaColor: areaColor,
                toneName: toneName,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String reasonId,
                required String name,
                required String areaName,
                Value<int?> areaColor = const Value.absent(),
                required String toneName,
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReasonsTableCompanion.insert(
                reasonId: reasonId,
                name: name,
                areaName: areaName,
                areaColor: areaColor,
                toneName: toneName,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ReasonsTableTable, ReasonRecord>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $ReasonsTableTable,
                    ReasonRecord
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ReasonsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReasonsTableTable,
      ReasonRecord,
      $$ReasonsTableTableFilterComposer,
      $$ReasonsTableTableOrderingComposer,
      $$ReasonsTableTableAnnotationComposer,
      $$ReasonsTableTableCreateCompanionBuilder,
      $$ReasonsTableTableUpdateCompanionBuilder,
      (
        ReasonRecord,
        BaseReferences<_$AppDatabase, $ReasonsTableTable, ReasonRecord>,
      ),
      ReasonRecord,
      PrefetchHooks Function()
    >;
typedef $$SettingsTableTableCreateCompanionBuilder =
    SettingsTableCompanion Function({
      Value<int> id,
      Value<bool> notifyBilling,
      Value<bool> notifyAlarms,
      Value<bool> notifyQuotes,
    });
typedef $$SettingsTableTableUpdateCompanionBuilder =
    SettingsTableCompanion Function({
      Value<int> id,
      Value<bool> notifyBilling,
      Value<bool> notifyAlarms,
      Value<bool> notifyQuotes,
    });

class $$SettingsTableTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsTableTable> {
  $$SettingsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get notifyBilling => $composableBuilder(
    column: $table.notifyBilling,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get notifyAlarms => $composableBuilder(
    column: $table.notifyAlarms,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get notifyQuotes => $composableBuilder(
    column: $table.notifyQuotes,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SettingsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsTableTable> {
  $$SettingsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get notifyBilling => $composableBuilder(
    column: $table.notifyBilling,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get notifyAlarms => $composableBuilder(
    column: $table.notifyAlarms,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get notifyQuotes => $composableBuilder(
    column: $table.notifyQuotes,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SettingsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsTableTable> {
  $$SettingsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<bool> get notifyBilling => $composableBuilder(
    column: $table.notifyBilling,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get notifyAlarms => $composableBuilder(
    column: $table.notifyAlarms,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get notifyQuotes => $composableBuilder(
    column: $table.notifyQuotes,
    builder: (column) => column,
  );
}

class $$SettingsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SettingsTableTable,
          SettingsRecord,
          $$SettingsTableTableFilterComposer,
          $$SettingsTableTableOrderingComposer,
          $$SettingsTableTableAnnotationComposer,
          $$SettingsTableTableCreateCompanionBuilder,
          $$SettingsTableTableUpdateCompanionBuilder,
          (
            SettingsRecord,
            BaseReferences<_$AppDatabase, $SettingsTableTable, SettingsRecord>,
          ),
          SettingsRecord,
          PrefetchHooks Function()
        > {
  $$SettingsTableTableTableManager(_$AppDatabase db, $SettingsTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<bool> notifyBilling = const Value.absent(),
                Value<bool> notifyAlarms = const Value.absent(),
                Value<bool> notifyQuotes = const Value.absent(),
              }) => SettingsTableCompanion(
                id: id,
                notifyBilling: notifyBilling,
                notifyAlarms: notifyAlarms,
                notifyQuotes: notifyQuotes,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<bool> notifyBilling = const Value.absent(),
                Value<bool> notifyAlarms = const Value.absent(),
                Value<bool> notifyQuotes = const Value.absent(),
              }) => SettingsTableCompanion.insert(
                id: id,
                notifyBilling: notifyBilling,
                notifyAlarms: notifyAlarms,
                notifyQuotes: notifyQuotes,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SettingsTableTable, SettingsRecord>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $SettingsTableTable,
                    SettingsRecord
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SettingsTableTable,
      SettingsRecord,
      $$SettingsTableTableFilterComposer,
      $$SettingsTableTableOrderingComposer,
      $$SettingsTableTableAnnotationComposer,
      $$SettingsTableTableCreateCompanionBuilder,
      $$SettingsTableTableUpdateCompanionBuilder,
      (
        SettingsRecord,
        BaseReferences<_$AppDatabase, $SettingsTableTable, SettingsRecord>,
      ),
      SettingsRecord,
      PrefetchHooks Function()
    >;
typedef $$AreasOfLifeTableTableCreateCompanionBuilder =
    AreasOfLifeTableCompanion Function({
      Value<int> id,
      required String name,
      required String title,
      Value<String?> description,
      Value<String?> icon,
      Value<int?> color,
    });
typedef $$AreasOfLifeTableTableUpdateCompanionBuilder =
    AreasOfLifeTableCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String> title,
      Value<String?> description,
      Value<String?> icon,
      Value<int?> color,
    });

class $$AreasOfLifeTableTableFilterComposer
    extends Composer<_$AppDatabase, $AreasOfLifeTableTable> {
  $$AreasOfLifeTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AreasOfLifeTableTableOrderingComposer
    extends Composer<_$AppDatabase, $AreasOfLifeTableTable> {
  $$AreasOfLifeTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AreasOfLifeTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $AreasOfLifeTableTable> {
  $$AreasOfLifeTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<int> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);
}

class $$AreasOfLifeTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AreasOfLifeTableTable,
          AreaOfLifeRecord,
          $$AreasOfLifeTableTableFilterComposer,
          $$AreasOfLifeTableTableOrderingComposer,
          $$AreasOfLifeTableTableAnnotationComposer,
          $$AreasOfLifeTableTableCreateCompanionBuilder,
          $$AreasOfLifeTableTableUpdateCompanionBuilder,
          (
            AreaOfLifeRecord,
            BaseReferences<
              _$AppDatabase,
              $AreasOfLifeTableTable,
              AreaOfLifeRecord
            >,
          ),
          AreaOfLifeRecord,
          PrefetchHooks Function()
        > {
  $$AreasOfLifeTableTableTableManager(
    _$AppDatabase db,
    $AreasOfLifeTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AreasOfLifeTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AreasOfLifeTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AreasOfLifeTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> icon = const Value.absent(),
                Value<int?> color = const Value.absent(),
              }) => AreasOfLifeTableCompanion(
                id: id,
                name: name,
                title: title,
                description: description,
                icon: icon,
                color: color,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required String title,
                Value<String?> description = const Value.absent(),
                Value<String?> icon = const Value.absent(),
                Value<int?> color = const Value.absent(),
              }) => AreasOfLifeTableCompanion.insert(
                id: id,
                name: name,
                title: title,
                description: description,
                icon: icon,
                color: color,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AreasOfLifeTableTable, AreaOfLifeRecord>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $AreasOfLifeTableTable,
                    AreaOfLifeRecord
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AreasOfLifeTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AreasOfLifeTableTable,
      AreaOfLifeRecord,
      $$AreasOfLifeTableTableFilterComposer,
      $$AreasOfLifeTableTableOrderingComposer,
      $$AreasOfLifeTableTableAnnotationComposer,
      $$AreasOfLifeTableTableCreateCompanionBuilder,
      $$AreasOfLifeTableTableUpdateCompanionBuilder,
      (
        AreaOfLifeRecord,
        BaseReferences<_$AppDatabase, $AreasOfLifeTableTable, AreaOfLifeRecord>,
      ),
      AreaOfLifeRecord,
      PrefetchHooks Function()
    >;
typedef $$VoicesTableTableCreateCompanionBuilder =
    VoicesTableCompanion Function({
      Value<int> id,
      required String name,
      required String voiceId,
      Value<String?> audio,
      Value<String?> avatar,
      Value<int?> groupId,
      Value<String?> groupTitle,
      Value<String?> groupDescription,
      Value<String?> gender,
      Value<String?> accent,
      Value<String?> traits,
      Value<int?> color,
      Value<bool> isPremium,
    });
typedef $$VoicesTableTableUpdateCompanionBuilder =
    VoicesTableCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String> voiceId,
      Value<String?> audio,
      Value<String?> avatar,
      Value<int?> groupId,
      Value<String?> groupTitle,
      Value<String?> groupDescription,
      Value<String?> gender,
      Value<String?> accent,
      Value<String?> traits,
      Value<int?> color,
      Value<bool> isPremium,
    });

class $$VoicesTableTableFilterComposer
    extends Composer<_$AppDatabase, $VoicesTableTable> {
  $$VoicesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get voiceId => $composableBuilder(
    column: $table.voiceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get audio => $composableBuilder(
    column: $table.audio,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get avatar => $composableBuilder(
    column: $table.avatar,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get groupTitle => $composableBuilder(
    column: $table.groupTitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get groupDescription => $composableBuilder(
    column: $table.groupDescription,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get gender => $composableBuilder(
    column: $table.gender,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accent => $composableBuilder(
    column: $table.accent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get traits => $composableBuilder(
    column: $table.traits,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPremium => $composableBuilder(
    column: $table.isPremium,
    builder: (column) => ColumnFilters(column),
  );
}

class $$VoicesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $VoicesTableTable> {
  $$VoicesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get voiceId => $composableBuilder(
    column: $table.voiceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get audio => $composableBuilder(
    column: $table.audio,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get avatar => $composableBuilder(
    column: $table.avatar,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get groupTitle => $composableBuilder(
    column: $table.groupTitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get groupDescription => $composableBuilder(
    column: $table.groupDescription,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gender => $composableBuilder(
    column: $table.gender,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accent => $composableBuilder(
    column: $table.accent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get traits => $composableBuilder(
    column: $table.traits,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPremium => $composableBuilder(
    column: $table.isPremium,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$VoicesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $VoicesTableTable> {
  $$VoicesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get voiceId =>
      $composableBuilder(column: $table.voiceId, builder: (column) => column);

  GeneratedColumn<String> get audio =>
      $composableBuilder(column: $table.audio, builder: (column) => column);

  GeneratedColumn<String> get avatar =>
      $composableBuilder(column: $table.avatar, builder: (column) => column);

  GeneratedColumn<int> get groupId =>
      $composableBuilder(column: $table.groupId, builder: (column) => column);

  GeneratedColumn<String> get groupTitle => $composableBuilder(
    column: $table.groupTitle,
    builder: (column) => column,
  );

  GeneratedColumn<String> get groupDescription => $composableBuilder(
    column: $table.groupDescription,
    builder: (column) => column,
  );

  GeneratedColumn<String> get gender =>
      $composableBuilder(column: $table.gender, builder: (column) => column);

  GeneratedColumn<String> get accent =>
      $composableBuilder(column: $table.accent, builder: (column) => column);

  GeneratedColumn<String> get traits =>
      $composableBuilder(column: $table.traits, builder: (column) => column);

  GeneratedColumn<int> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<bool> get isPremium =>
      $composableBuilder(column: $table.isPremium, builder: (column) => column);
}

class $$VoicesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $VoicesTableTable,
          VoiceRecord,
          $$VoicesTableTableFilterComposer,
          $$VoicesTableTableOrderingComposer,
          $$VoicesTableTableAnnotationComposer,
          $$VoicesTableTableCreateCompanionBuilder,
          $$VoicesTableTableUpdateCompanionBuilder,
          (
            VoiceRecord,
            BaseReferences<_$AppDatabase, $VoicesTableTable, VoiceRecord>,
          ),
          VoiceRecord,
          PrefetchHooks Function()
        > {
  $$VoicesTableTableTableManager(_$AppDatabase db, $VoicesTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VoicesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VoicesTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VoicesTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> voiceId = const Value.absent(),
                Value<String?> audio = const Value.absent(),
                Value<String?> avatar = const Value.absent(),
                Value<int?> groupId = const Value.absent(),
                Value<String?> groupTitle = const Value.absent(),
                Value<String?> groupDescription = const Value.absent(),
                Value<String?> gender = const Value.absent(),
                Value<String?> accent = const Value.absent(),
                Value<String?> traits = const Value.absent(),
                Value<int?> color = const Value.absent(),
                Value<bool> isPremium = const Value.absent(),
              }) => VoicesTableCompanion(
                id: id,
                name: name,
                voiceId: voiceId,
                audio: audio,
                avatar: avatar,
                groupId: groupId,
                groupTitle: groupTitle,
                groupDescription: groupDescription,
                gender: gender,
                accent: accent,
                traits: traits,
                color: color,
                isPremium: isPremium,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required String voiceId,
                Value<String?> audio = const Value.absent(),
                Value<String?> avatar = const Value.absent(),
                Value<int?> groupId = const Value.absent(),
                Value<String?> groupTitle = const Value.absent(),
                Value<String?> groupDescription = const Value.absent(),
                Value<String?> gender = const Value.absent(),
                Value<String?> accent = const Value.absent(),
                Value<String?> traits = const Value.absent(),
                Value<int?> color = const Value.absent(),
                Value<bool> isPremium = const Value.absent(),
              }) => VoicesTableCompanion.insert(
                id: id,
                name: name,
                voiceId: voiceId,
                audio: audio,
                avatar: avatar,
                groupId: groupId,
                groupTitle: groupTitle,
                groupDescription: groupDescription,
                gender: gender,
                accent: accent,
                traits: traits,
                color: color,
                isPremium: isPremium,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$VoicesTableTable, VoiceRecord>(table),
                  BaseReferences<_$AppDatabase, $VoicesTableTable, VoiceRecord>(
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

typedef $$VoicesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $VoicesTableTable,
      VoiceRecord,
      $$VoicesTableTableFilterComposer,
      $$VoicesTableTableOrderingComposer,
      $$VoicesTableTableAnnotationComposer,
      $$VoicesTableTableCreateCompanionBuilder,
      $$VoicesTableTableUpdateCompanionBuilder,
      (
        VoiceRecord,
        BaseReferences<_$AppDatabase, $VoicesTableTable, VoiceRecord>,
      ),
      VoiceRecord,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$AlarmsTableTableTableManager get alarmsTable =>
      $$AlarmsTableTableTableManager(_db, _db.alarmsTable);
  $$ReasonsTableTableTableManager get reasonsTable =>
      $$ReasonsTableTableTableManager(_db, _db.reasonsTable);
  $$SettingsTableTableTableManager get settingsTable =>
      $$SettingsTableTableTableManager(_db, _db.settingsTable);
  $$AreasOfLifeTableTableTableManager get areasOfLifeTable =>
      $$AreasOfLifeTableTableTableManager(_db, _db.areasOfLifeTable);
  $$VoicesTableTableTableManager get voicesTable =>
      $$VoicesTableTableTableManager(_db, _db.voicesTable);
}
