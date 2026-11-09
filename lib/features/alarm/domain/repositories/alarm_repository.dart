import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/alarm.dart';

abstract class AlarmRepository {
  Future<Either<Failure, List<Alarm>>> getAlarms();

  /// The saved alarms now and after every change (a save, a delete, a reschedule).
  Stream<Either<Failure, List<Alarm>>> watchAlarms();
  Future<Either<Failure, Alarm>> saveAlarm(Alarm alarm);
  Future<Either<Failure, void>> deleteAlarm(String alarmId);
}
