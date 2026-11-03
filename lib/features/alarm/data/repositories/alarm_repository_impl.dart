import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/alarm.dart';
import '../../domain/repositories/alarm_repository.dart';
import '../datasources/alarm_local_data_source.dart';
import '../models/alarm_isar_model.dart';

@LazySingleton(as: AlarmRepository)
class AlarmRepositoryImpl implements AlarmRepository {
  final AlarmLocalDataSource localDataSource;

  AlarmRepositoryImpl(this.localDataSource);

  @override
  Future<Either<Failure, List<Alarm>>> getAlarms() async {
    try {
      final models = await localDataSource.getAlarms();
      return Right(models.map((m) => m.toEntity()).toList());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, Alarm>> saveAlarm(Alarm alarm) async {
    try {
      await localDataSource.saveAlarm(AlarmIsarModel.fromEntity(alarm));
      return Right(alarm);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> deleteAlarm(String alarmId) async {
    try {
      await localDataSource.deleteAlarm(alarmId);
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }
}
