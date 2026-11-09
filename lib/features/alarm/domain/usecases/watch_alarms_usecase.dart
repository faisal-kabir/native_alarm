import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/alarm.dart';
import '../repositories/alarm_repository.dart';

/// Streams the saved alarms: now, and again after every change wherever it is made
/// (made, switched, deleted with its Reason, moved to its next day).
@lazySingleton
class WatchAlarmsUseCase {
  final AlarmRepository repository;

  WatchAlarmsUseCase(this.repository);

  Stream<Either<Failure, List<Alarm>>> call(NoParams params) =>
      repository.watchAlarms();
}
