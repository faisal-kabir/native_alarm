import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../alarm/domain/entities/alarm.dart';
import '../../../alarm/domain/repositories/alarm_repository.dart';
import '../../../alarm/domain/repositories/alarm_scheduler.dart';
import '../repositories/remote_alarm_repository.dart';

/// Deletes an alarm everywhere: the server's copy first (`alarm`, its `sub_alarm` rows
/// and its Reason's link; an alarm made offline and not sent yet has none), then its
/// ring on the device, then the device's row. Its Reason stays, free for another
/// alarm. Offline, an alarm that is on the server stays as it was and this fails, so
/// it can simply be tried again.
@lazySingleton
class RemoveAlarmUseCase implements UseCase<Unit, Alarm> {
  final AlarmRepository repository;
  final RemoteAlarmRepository remote;
  final AlarmScheduler scheduler;

  RemoveAlarmUseCase(this.repository, this.remote, this.scheduler);

  @override
  Future<Either<Failure, Unit>> call(Alarm alarm) async {
    final remoteId = alarm.remoteId;
    if (remoteId != null) {
      final removed = await remote.remove(remoteId);
      if (removed.isLeft()) return removed;
    }
    try {
      await scheduler.cancel(alarm.id);
    } catch (e) {
      return Left(CacheFailure('Alarm not cancelled: $e'));
    }
    return (await repository.deleteAlarm(alarm.id)).map((_) => unit);
  }
}
