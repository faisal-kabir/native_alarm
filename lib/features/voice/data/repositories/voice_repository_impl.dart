import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/voice.dart';
import '../../domain/repositories/voice_repository.dart';
import '../datasources/voice_local_data_source.dart';
import '../datasources/voice_remote_data_source.dart';
import '../models/voices_table.dart';

@LazySingleton(as: VoiceRepository)
class VoiceRepositoryImpl implements VoiceRepository {
  final VoiceRemoteDataSource remoteDataSource;
  final VoiceLocalDataSource localDataSource;

  VoiceRepositoryImpl(this.remoteDataSource, this.localDataSource);

  @override
  Stream<Either<Failure, List<Voice>>> watchVoices() =>
      localDataSource.watchVoices().transform(
        StreamTransformer<
          List<VoiceRecord>,
          Either<Failure, List<Voice>>
        >.fromHandlers(
          handleData: (records, sink) =>
              sink.add(Right(records.map((r) => r.toEntity()).toList())),
          handleError: (error, _, sink) =>
              sink.add(Left(CacheFailure(error.toString()))),
        ),
      );

  @override
  Future<Either<Failure, Unit>> refreshVoices() async {
    try {
      final voices = await remoteDataSource.fetchVoices();
      // An empty answer is never trusted over what is saved (a misconfigured server,
      // not a real "no voices").
      if (voices.isNotEmpty) await localDataSource.replaceAll(voices);
      return const Right(unit);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }
}
