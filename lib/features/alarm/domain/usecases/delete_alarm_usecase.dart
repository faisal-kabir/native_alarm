import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/alarm_repository.dart';

/// Removes the alarm with the given id.
@lazySingleton
class DeleteAlarmUseCase implements UseCase<void, String> {
  final AlarmRepository repository;

  DeleteAlarmUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(String alarmId) =>
      repository.deleteAlarm(alarmId);
}
