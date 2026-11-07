import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/new_reason.dart';
import '../../domain/entities/reason.dart';
import '../../domain/entities/reason_name.dart';
import '../../domain/repositories/reason_repository.dart';
import '../datasources/reason_local_data_source.dart';
import '../datasources/reason_remote_data_source.dart';
import '../models/reasons_table.dart';

@LazySingleton(as: ReasonRepository)
class ReasonRepositoryImpl implements ReasonRepository {
  final ReasonRemoteDataSource remoteDataSource;
  final ReasonLocalDataSource localDataSource;

  ReasonRepositoryImpl(this.remoteDataSource, this.localDataSource);

  /// Refresh, create and rename run one after another: a refresh that downloaded
  /// the list just before a new reason was saved (or renamed) would otherwise put
  /// the old list back over it.
  Future<void> _last = Future<void>.value();

  Future<T> _oneAtATime<T>(Future<T> Function() task) {
    final run = _last.then((_) => task());
    _last = run.then<void>((_) {}, onError: (Object _) {});
    return run;
  }

  @override
  Stream<Either<Failure, List<Reason>>> watchReasons() =>
      localDataSource.watchReasons().transform(
        StreamTransformer<
          List<ReasonRecord>,
          Either<Failure, List<Reason>>
        >.fromHandlers(
          handleData: (records, sink) =>
              sink.add(Right(records.map((r) => r.toEntity()).toList())),
          handleError: (error, _, sink) =>
              sink.add(Left(CacheFailure(error.toString()))),
        ),
      );

  @override
  Future<Either<Failure, Unit>> refreshReasons() =>
      _oneAtATime(_refreshReasons);

  Future<Either<Failure, Unit>> _refreshReasons() async {
    try {
      await localDataSource.replaceAll(await remoteDataSource.fetchReasons());
      return const Right(unit);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, Reason>> createReason(NewReason reason) =>
      _oneAtATime(() => _createReason(reason));

  Future<Either<Failure, Reason>> _createReason(NewReason reason) async {
    try {
      final userId = await remoteDataSource.fetchOwnUserId();
      final taken = await remoteDataSource.fetchNamesStartingWith(
        userId,
        reason.baseName.trim(),
      );
      final name = nextReasonName(reason.baseName, taken);
      final id = await remoteDataSource.insertReason(userId, name, reason);
      final saved = Reason(
        id: '$id',
        name: name,
        areaName: reason.areaTitle,
        areaColor: reason.areaColor,
        toneName: reason.soundTitle,
      );
      await localDataSource.saveReason(saved);
      return Right(saved);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, Unit>> renameReason(String id, String name) =>
      _oneAtATime(() => _renameReason(id, name));

  Future<Either<Failure, Unit>> _renameReason(String id, String name) async {
    final serverId = int.tryParse(id);
    if (serverId == null) return const Left(CacheFailure('Unknown reason'));
    try {
      await remoteDataSource.updateName(serverId, name);
      await localDataSource.renameReason(id, name);
      return const Right(unit);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }
}
