import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/area_of_life.dart';
import '../../domain/repositories/area_of_life_repository.dart';
import '../datasources/area_of_life_local_data_source.dart';
import '../datasources/area_of_life_remote_data_source.dart';
import '../models/areas_of_life_table.dart';

@LazySingleton(as: AreaOfLifeRepository)
class AreaOfLifeRepositoryImpl implements AreaOfLifeRepository {
  final AreaOfLifeRemoteDataSource remoteDataSource;
  final AreaOfLifeLocalDataSource localDataSource;

  AreaOfLifeRepositoryImpl(this.remoteDataSource, this.localDataSource);

  @override
  Stream<Either<Failure, List<AreaOfLife>>> watchAreas() =>
      localDataSource.watchAreas().transform(
        StreamTransformer<
          List<AreaOfLifeRecord>,
          Either<Failure, List<AreaOfLife>>
        >.fromHandlers(
          handleData: (records, sink) =>
              sink.add(Right(records.map((r) => r.toEntity()).toList())),
          handleError: (error, _, sink) =>
              sink.add(Left(CacheFailure(error.toString()))),
        ),
      );

  @override
  Future<Either<Failure, Unit>> refreshAreas() async {
    try {
      final areas = await remoteDataSource.fetchAreas();
      // An empty answer is never trusted over what is saved: the app can not work
      // without areas, so it is a misconfigured server rather than a real "none".
      if (areas.isNotEmpty) await localDataSource.replaceAll(areas);
      return const Right(unit);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }
}
