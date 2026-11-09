import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../alarm/domain/entities/alarm.dart';

/// The server's copy of the person's alarms (`alarm`, `sub_alarm`, and the Reason's
/// `alarm_id`).
abstract class RemoteAlarmRepository {
  /// Puts [alarm] on the server and answers it as the server now holds it (with its
  /// [Alarm.remoteId]); [now] dates its schedules' next rings.
  Future<Either<Failure, Alarm>> upload(Alarm alarm, {required DateTime now});

  /// Removes server alarm [remoteId] (and its schedules, and its Reason's link).
  Future<Either<Failure, Unit>> remove(int remoteId);
}
