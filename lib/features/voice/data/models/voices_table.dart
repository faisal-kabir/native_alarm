import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/voice.dart';
import '../../domain/entities/voice_group.dart';

/// SQL table `voices`: the device's copy of the server's `voice` table, keyed by the
/// server's id. The voice's group (title, description) is kept on the row, as the
/// server's join returns it. Rows come back as [VoiceRecord].
@DataClassName('VoiceRecord')
class VoicesTable extends Table {
  @override
  String get tableName => 'voices';

  IntColumn get id => integer()();
  TextColumn get name => text()();
  TextColumn get voiceId => text()();
  TextColumn get audio => text().nullable()();
  TextColumn get avatar => text().nullable()();
  IntColumn get groupId => integer().nullable()();
  TextColumn get groupTitle => text().nullable()();
  TextColumn get groupDescription => text().nullable()();
  TextColumn get gender => text().nullable()();
  TextColumn get accent => text().nullable()();
  TextColumn get traits => text().nullable()();
  IntColumn get color => integer().nullable()();
  BoolColumn get isPremium => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

extension VoiceRecordMapper on VoiceRecord {
  Voice toEntity() => Voice(
    id: id,
    name: name,
    voiceId: voiceId,
    audio: audio,
    avatar: avatar,
    groupId: groupId,
    group: groupId == null || groupTitle == null
        ? null
        : VoiceGroup(
            id: groupId!,
            title: groupTitle!,
            description: groupDescription,
          ),
    gender: gender,
    accent: accent,
    traits: traits,
    color: color,
    isPremium: isPremium,
  );
}

extension VoiceCompanionMapper on Voice {
  VoicesTableCompanion toCompanion() => VoicesTableCompanion(
    id: Value(id),
    name: Value(name),
    voiceId: Value(voiceId),
    audio: Value(audio),
    avatar: Value(avatar),
    groupId: Value(groupId),
    groupTitle: Value(group?.title),
    groupDescription: Value(group?.description),
    gender: Value(gender),
    accent: Value(accent),
    traits: Value(traits),
    color: Value(color),
    isPremium: Value(isPremium),
  );
}
