import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/alarm.dart';
import '../repositories/alarm_repository.dart';

/// Creates or updates an alarm (matched by [Alarm.id]).
@lazySingleton
class SaveAlarmUseCase implements UseCase<Alarm, Alarm> {
  final AlarmRepository repository;

  SaveAlarmUseCase(this.repository);

  @override
  Future<Either<Failure, Alarm>> call(Alarm alarm) =>
      repository.saveAlarm(alarm);
}
