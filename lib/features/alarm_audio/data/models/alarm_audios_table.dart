import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/alarm_audio.dart';

/// SQL table `alarm_audios`: the device's copy of the server's `alarm_sound` and
/// `sound_track` tables, keyed by ([kind] = the server table, [id]). [iconFile] and
/// [audioFile] are the NAMES of the downloaded files in the app's `alarm_audio`
/// folder (never full paths: the app's folder can move after an update), null until
/// downloaded. Rows come back as [AlarmAudioRecord].
@DataClassName('AlarmAudioRecord')
class AlarmAudiosTable extends Table {
  @override
  String get tableName => 'alarm_audios';

  TextColumn get kind => text()();
  IntColumn get id => integer()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  TextColumn get icon => text().nullable()();
  IntColumn get color => integer().nullable()();
  TextColumn get audio => text().nullable()();
  TextColumn get iconFile => text().nullable()();
  TextColumn get audioFile => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {kind, id};
}

extension AlarmAudioRecordMapper on AlarmAudioRecord {
  /// [folder] is where the downloaded files are.
  AlarmAudio toEntity(String folder) => AlarmAudio(
    kind: AlarmAudioKind.values.firstWhere((k) => k.table == kind),
    id: id,
    title: title,
    description: description,
    icon: icon,
    color: color,
    audio: audio,
    iconFile: iconFile == null ? null : '$folder/$iconFile',
    audioFile: audioFile == null ? null : '$folder/$audioFile',
  );
}

extension AlarmAudioCompanionMapper on AlarmAudio {
  /// The server's values only: the file names of a row that stays are kept, and
  /// cleared when the server no longer has that file.
  AlarmAudiosTableCompanion toCompanion() => AlarmAudiosTableCompanion(
    kind: Value(kind.table),
    id: Value(id),
    title: Value(title),
    description: Value(description),
    icon: Value(icon),
    color: Value(color),
    audio: Value(audio),
    iconFile: icon == null ? const Value(null) : const Value.absent(),
    audioFile: audio == null ? const Value(null) : const Value.absent(),
  );
}
