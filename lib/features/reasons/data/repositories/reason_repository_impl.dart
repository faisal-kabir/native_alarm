import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/new_reason.dart';
import '../../domain/entities/reason.dart';
import '../../domain/entities/reason_draft.dart';
import '../../domain/entities/reason_name.dart';
import '../../domain/repositories/reason_repository.dart';
import '../datasources/reason_local_data_source.dart';
import '../datasources/reason_remote_data_source.dart';
import '../models/reason_model.dart';
import '../models/reasons_table.dart';

/// Reasons are read from the device's copy only (instant, offline too); every write
/// goes to the server first and its answer (the full row, joins included) replaces the
/// device's copy, so the device only ever shows what the server has.
@LazySingleton(as: ReasonRepository)
class ReasonRepositoryImpl implements ReasonRepository {
  final ReasonRemoteDataSource remoteDataSource;
  final ReasonLocalDataSource localDataSource;

  ReasonRepositoryImpl(this.remoteDataSource, this.localDataSource);

  /// Writes run one after another: a refresh that downloaded the list just before a
  /// reason was saved would otherwise put the old list back over it.
  Future<void> _last = Future<void>.value();

  Future<T> _oneAtATime<T>(Future<T> Function() task) {
    final run = _last.then((_) => task());
    _last = run.then<void>((_) {}, onError: (Object _) {});
    return run;
  }

  /// Runs a server write, keeps its answer on the device and returns it.
  Future<Either<Failure, Reason>> _write(
    Future<Map<String, dynamic>> Function() send,
  ) => _oneAtATime(() async {
    try {
      final row = await send();
      await localDataSource.saveRow(row);
      return Right(reasonFromJson(row));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  });

  StreamTransformer<S, Either<Failure, T>> _toEither<S, T>(T Function(S) map) =>
      StreamTransformer.fromHandlers(
        handleData: (data, sink) => sink.add(Right(map(data))),
        handleError: (error, _, sink) =>
            sink.add(Left(CacheFailure(error.toString()))),
      );

  @override
  Stream<Either<Failure, List<Reason>>> watchReasons() =>
      localDataSource.watchReasons().transform(
        _toEither((records) => [for (final r in records) r.toEntity()]),
      );

  @override
  Stream<Either<Failure, Reason?>> watchReason(int id) => localDataSource
      .watchReason(id)
      .transform(_toEither((record) => record?.toEntity()));

  @override
  Future<Either<Failure, Unit>> refreshReasons() => _oneAtATime(() async {
    try {
      await localDataSource.replaceAll(await remoteDataSource.fetchReasons());
      return const Right(unit);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  });

  @override
  Future<Either<Failure, Reason>> createReason(NewReason reason) => _write(
    () async {
      final userId = await remoteDataSource.fetchOwnUserId();
      final base = reason.baseName.trim();
      final taken = await remoteDataSource.fetchNamesStartingWith(userId, base);
      return remoteDataSource.insertReason(
        userId,
        nextReasonName(base, taken),
        reason.draft,
      );
    },
  );

  @override
  Future<Either<Failure, Reason>> renameReason(int id, String name) =>
      _write(() => remoteDataSource.updateReason(id, {'name': name.trim()}));

  @override
  Future<Either<Failure, Reason>> updateReason(int id, ReasonDraft draft) =>
      _write(
        () => remoteDataSource.updateReason(id, reasonDraftColumns(draft)),
      );

  @override
  Future<Either<Failure, Unit>> deleteReason(int id) => _oneAtATime(() async {
    try {
      await remoteDataSource.deleteReason(id);
      await localDataSource.deleteRow(id);
      return const Right(unit);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  });
}
