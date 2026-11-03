import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/alarm.dart';

abstract class AlarmRepository {
  Future<Either<Failure, List<Alarm>>> getAlarms();
  Future<Either<Failure, Alarm>> saveAlarm(Alarm alarm);
  Future<Either<Failure, void>> deleteAlarm(String alarmId);
}
