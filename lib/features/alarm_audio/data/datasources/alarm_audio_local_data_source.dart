import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/alarm_audio.dart';
import '../models/alarm_audios_table.dart';

abstract class AlarmAudioLocalDataSource {
  /// The saved rows of [kind], by id; emits again after every change.
  Stream<List<AlarmAudioRecord>> watchAudio(AlarmAudioKind kind);

  /// Every saved row (both lists).
  Future<List<AlarmAudioRecord>> allAudio();

  /// Makes the saved rows of [kind] exactly [rows] (added, updated, removed) in one
  /// transaction. File names of rows that stay are kept.
  Future<void> replaceAll(AlarmAudioKind kind, List<AlarmAudio> rows);

  /// Records a downloaded file (its name in the files folder) on a row.
  Future<void> setFile(
    AlarmAudioKind kind,
    int id, {
    String? iconFile,
    String? audioFile,
  });
}

@LazySingleton(as: AlarmAudioLocalDataSource)
class AlarmAudioLocalDataSourceImpl implements AlarmAudioLocalDataSource {
  final AppDatabase db;

  AlarmAudioLocalDataSourceImpl(this.db);

  @override
  Stream<List<AlarmAudioRecord>> watchAudio(AlarmAudioKind kind) =>
      (db.select(db.alarmAudiosTable)
            ..where((t) => t.kind.equals(kind.table))
            ..orderBy([(t) => OrderingTerm.asc(t.id)]))
          .watch();

  @override
  Future<List<AlarmAudioRecord>> allAudio() async {
    try {
      return await db.select(db.alarmAudiosTable).get();
    } catch (e) {
      throw CacheException(e.toString());
    }
  }

  @override
  Future<void> replaceAll(AlarmAudioKind kind, List<AlarmAudio> rows) async {
    try {
      await db.transaction(() async {
        final ids = [for (final row in rows) row.id];
        await (db.delete(
          db.alarmAudiosTable,
        )..where((t) => t.kind.equals(kind.table) & t.id.isNotIn(ids))).go();
        await db.batch(
          (batch) => batch.insertAllOnConflictUpdate(db.alarmAudiosTable, [
            for (final row in rows) row.toCompanion(),
          ]),
        );
      });
    } catch (e) {
      throw CacheException(e.toString());
    }
  }

  @override
  Future<void> setFile(
    AlarmAudioKind kind,
    int id, {
    String? iconFile,
    String? audioFile,
  }) async {
    try {
      await (db.update(
        db.alarmAudiosTable,
      )..where((t) => t.kind.equals(kind.table) & t.id.equals(id))).write(
        AlarmAudiosTableCompanion(
          iconFile: iconFile == null ? const Value.absent() : Value(iconFile),
          audioFile: audioFile == null
              ? const Value.absent()
              : Value(audioFile),
        ),
      );
    } catch (e) {
      throw CacheException(e.toString());
    }
  }
}
