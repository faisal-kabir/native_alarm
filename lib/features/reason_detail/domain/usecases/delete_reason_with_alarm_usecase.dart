import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../alarm/domain/repositories/alarm_repository.dart';
import '../../../alarm/domain/repositories/alarm_scheduler.dart';
import '../../../create_alarm/domain/repositories/remote_alarm_repository.dart';
import '../../../reasons/domain/entities/reason.dart';
import '../../../reasons/domain/repositories/reason_repository.dart';

/// Deletes a Reason, and with it the alarm that plays it (every alarm needs a Reason):
/// the alarm leaves the server first (`alarm`, its `sub_alarm` rows, the Reason's
/// link), then the device (its ring is cancelled, its row removed), then the Reason
/// goes (server, then device). Offline nothing changes and it fails, so it can simply
/// be tried again; an alarm already gone stays gone if only the Reason then fails.
@lazySingleton
class DeleteReasonWithAlarmUseCase implements UseCase<Unit, Reason> {
  final ReasonRepository reasons;
  final AlarmRepository alarms;
  final RemoteAlarmRepository remoteAlarms;
  final AlarmScheduler scheduler;

  DeleteReasonWithAlarmUseCase(
    this.reasons,
    this.alarms,
    this.remoteAlarms,
    this.scheduler,
  );

  @override
  Future<Either<Failure, Unit>> call(Reason reason) async {
    final saved = await alarms.getAlarms();
    if (saved.isLeft()) return saved.map((_) => unit);
    final local = [
      for (final a in saved.getOrElse(() => const []))
        if (a.reasonId == reason.id) a,
    ];

    // The server's copy: the one the Reason points at, or the one the device sent.
    final remoteIds = {?reason.alarmId, for (final a in local) ?a.remoteId};
    for (final id in remoteIds) {
      final removed = await remoteAlarms.remove(id);
      if (removed.isLeft()) return removed;
    }

    for (final alarm in local) {
      try {
        await scheduler.cancel(alarm.id);
      } catch (e) {
        return Left(CacheFailure('Alarm not cancelled: $e'));
      }
      final deleted = await alarms.deleteAlarm(alarm.id);
      if (deleted.isLeft()) return deleted.map((_) => unit);
    }

    return reasons.deleteReason(reason.id);
  }
}
