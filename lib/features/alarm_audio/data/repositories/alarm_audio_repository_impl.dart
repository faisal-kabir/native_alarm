import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/media_url.dart';
import '../../domain/entities/alarm_audio.dart';
import '../../domain/repositories/alarm_audio_repository.dart';
import '../datasources/alarm_audio_file_store.dart';
import '../datasources/alarm_audio_local_data_source.dart';
import '../datasources/alarm_audio_remote_data_source.dart';
import '../models/alarm_audio_model.dart';
import '../models/alarm_audios_table.dart';

/// The alarm sounds and sound tracks live on the device (rows in drift, files in the
/// app's folder) so alarms can be made offline. A refresh mirrors the server's rows,
/// then downloads only the files that are new or changed, then deletes the files no
/// row uses any more.
@LazySingleton(as: AlarmAudioRepository)
class AlarmAudioRepositoryImpl implements AlarmAudioRepository {
  final AlarmAudioRemoteDataSource remoteDataSource;
  final AlarmAudioLocalDataSource localDataSource;
  final AlarmAudioFileStore fileStore;

  AlarmAudioRepositoryImpl(
    this.remoteDataSource,
    this.localDataSource,
    this.fileStore,
  );

  /// The refresh running now: a second call (the app opened again meanwhile) waits
  /// for it instead of downloading the same files twice.
  Future<Either<Failure, Unit>>? _running;

  @override
  Stream<Either<Failure, List<AlarmAudio>>> watchAudio(AlarmAudioKind kind) =>
      Stream.fromFuture(fileStore.folder()).asyncExpand(
        (folder) => localDataSource
            .watchAudio(kind)
            .transform(
              StreamTransformer.fromHandlers(
                handleData: (records, sink) => sink.add(
                  Right([for (final r in records) r.toEntity(folder)]),
                ),
                handleError: (error, _, sink) =>
                    sink.add(Left(CacheFailure(error.toString()))),
              ),
            ),
      );

  @override
  Future<Either<Failure, Unit>> refreshAudio() =>
      _running ??= _refresh().whenComplete(() => _running = null);

  Future<Either<Failure, Unit>> _refresh() async {
    Failure? failure;
    final fresh = <AlarmAudioModel>[];
    for (final kind in AlarmAudioKind.values) {
      try {
        final rows = await remoteDataSource.fetchAudio(kind);
        // An empty answer is never trusted over what is saved (a misconfigured
        // server, not a real "nothing").
        if (rows.isEmpty) continue;
        await localDataSource.replaceAll(kind, rows);
        fresh.addAll(rows);
      } on ServerException catch (e) {
        failure ??= ServerFailure(e.message);
      } on CacheException catch (e) {
        failure ??= CacheFailure(e.message);
      }
    }
    try {
      if (!await _downloadFiles(fresh)) {
        failure ??= const ServerFailure('Some files were not downloaded');
      }
      await _deleteUnusedFiles();
    } on CacheException catch (e) {
      failure ??= CacheFailure(e.message);
    }
    return failure == null ? const Right(unit) : Left(failure);
  }

  /// Downloads the files of [rows] that are missing or out of date. A file that fails
  /// keeps the row's previous file (still playable) and is tried again next time.
  /// False when any failed.
  Future<bool> _downloadFiles(List<AlarmAudioModel> rows) async {
    final saved = {
      for (final r in await localDataSource.allAudio()) '${r.kind}/${r.id}': r,
    };
    var allDone = true;
    for (final row in rows) {
      final record = saved['${row.kind.table}/${row.id}'];
      for (final (part, path, current) in [
        ('icon', row.icon, record?.iconFile),
        ('audio', row.audio, record?.audioFile),
      ]) {
        if (path == null) continue;
        final name = alarmAudioFileName(
          row.kind,
          row.id,
          part,
          path,
          row.updatedAt,
        );
        if (name == current && await fileStore.exists(name)) continue;
        try {
          await fileStore.download(mediaUrl(path), name);
          await localDataSource.setFile(
            row.kind,
            row.id,
            iconFile: part == 'icon' ? name : null,
            audioFile: part == 'audio' ? name : null,
          );
        } on ServerException catch (e) {
          allDone = false;
          debugPrint(
            'Alarm $part not downloaded (${row.kind.table} ${row.id}): '
            '${e.message}',
          );
        }
      }
    }
    return allDone;
  }

  Future<void> _deleteUnusedFiles() async {
    final keep = <String>{
      for (final r in await localDataSource.allAudio()) ...[
        ?r.iconFile,
        ?r.audioFile,
      ],
    };
    await fileStore.deleteAllBut(keep);
  }
}
