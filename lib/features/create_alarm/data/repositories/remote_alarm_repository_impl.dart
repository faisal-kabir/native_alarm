import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../alarm/domain/entities/alarm.dart';
import '../../../reasons/data/datasources/reason_local_data_source.dart';
import '../../domain/repositories/remote_alarm_repository.dart';
import '../datasources/alarm_remote_data_source.dart';
import '../models/alarm_server_model.dart';

/// Also keeps the device's copy of the Reasons in step: the Reason an alarm takes, or
/// gives back, is saved as the server now holds it (with its `alarm_id`), so the
/// pickers know at once which Reasons are free.
@LazySingleton(as: RemoteAlarmRepository)
class RemoteAlarmRepositoryImpl implements RemoteAlarmRepository {
  final AlarmRemoteDataSource remoteDataSource;
  final ReasonLocalDataSource reasonLocalDataSource;

  RemoteAlarmRepositoryImpl(this.remoteDataSource, this.reasonLocalDataSource);

  @override
  Future<Either<Failure, Alarm>> upload(
    Alarm alarm, {
    required DateTime now,
  }) async {
    final Map<String, dynamic> json;
    try {
      json = await remoteDataSource.insertAlarm(alarm, now);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
    final Alarm uploaded;
    try {
      uploaded = alarmFromServer(json, alarm);
    } on Object catch (e) {
      // A row of a shape this app can not read: it is taken off the server again, so
      // the device (which keeps the alarm and sends it later) leaves no copy behind.
      final id = json['id'];
      if (id is num) await remove(id.toInt());
      return Left(ServerFailure('Alarm not readable: $e'));
    }
    final reason = json['reason'];
    if (reason is Map<String, dynamic>) await _saveReasons([reason]);
    return Right(uploaded);
  }

  @override
  Future<Either<Failure, Unit>> remove(int remoteId) async {
    try {
      await _saveReasons(await remoteDataSource.deleteAlarm(remoteId));
      return const Right(unit);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  /// The next reasons refresh brings the same rows, so a failed save loses nothing.
  Future<void> _saveReasons(List<Map<String, dynamic>> rows) async {
    try {
      for (final row in rows) {
        await reasonLocalDataSource.saveRow(row);
      }
    } on CacheException {
      // Kept as it was until the next refresh.
    }
  }
}
