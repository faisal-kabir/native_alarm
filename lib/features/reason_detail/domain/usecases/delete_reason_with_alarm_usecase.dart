import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../alarm/domain/repositories/alarm_repository.dart';
import '../../../create_alarm/domain/repositories/remote_alarm_repository.dart';
import '../../../create_alarm/domain/usecases/remove_alarm_usecase.dart';
import '../../../reasons/domain/entities/reason.dart';
import '../../../reasons/domain/repositories/reason_repository.dart';

/// Deletes a Reason, and with it the alarm that plays it (every alarm needs a Reason):
/// the alarm goes everywhere first ([RemoveAlarmUseCase]: server, its ring, the
/// device; or only the server's copy when the device has none), then the Reason
/// (server, then device). Offline nothing changes and it fails, so it can simply be
/// tried again; an alarm already gone stays gone if only the Reason then fails.
@lazySingleton
class DeleteReasonWithAlarmUseCase implements UseCase<Unit, Reason> {
  final ReasonRepository reasons;
  final AlarmRepository alarms;
  final RemoteAlarmRepository remoteAlarms;
  final RemoveAlarmUseCase removeAlarm;

  DeleteReasonWithAlarmUseCase(
    this.reasons,
    this.alarms,
    this.remoteAlarms,
    this.removeAlarm,
  );

  @override
  Future<Either<Failure, Unit>> call(Reason reason) async {
    final saved = await alarms.getAlarms();
    if (saved.isLeft()) return saved.map((_) => unit);
    final local = [
      for (final a in saved.getOrElse(() => const []))
        if (a.reasonId == reason.id) a,
    ];

    // An alarm only the server has (the Reason points at it, the device does not).
    final serverOnly = reason.alarmId;
    if (serverOnly != null && !local.any((a) => a.remoteId == serverOnly)) {
      final removed = await remoteAlarms.remove(serverOnly);
      if (removed.isLeft()) return removed;
    }
    for (final alarm in local) {
      final removed = await removeAlarm(alarm);
      if (removed.isLeft()) return removed;
    }

    return reasons.deleteReason(reason.id);
  }
}
