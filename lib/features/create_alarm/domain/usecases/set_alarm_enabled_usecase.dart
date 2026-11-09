import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../alarm/domain/entities/alarm.dart';
import '../../../alarm/domain/repositories/alarm_repository.dart';
import '../../../alarm/domain/repositories/alarm_scheduler.dart';
import '../entities/alarm_schedule.dart';

class SetAlarmEnabledParams {
  const SetAlarmEnabledParams(
    this.alarm, {
    required this.enabled,
    required this.now,
  });

  final Alarm alarm;
  final bool enabled;
  final DateTime now;
}

/// An alarm's on / off switch. On: it is set to ring at its next time ([nextRingOf]:
/// a switched-off alarm's saved time has usually passed). Off: the device stops it.
/// The device goes first and the saved alarm follows, so the two never disagree; when
/// the device refuses, nothing changes. Answers the alarm as saved.
@lazySingleton
class SetAlarmEnabledUseCase implements UseCase<Alarm, SetAlarmEnabledParams> {
  final AlarmRepository repository;
  final AlarmScheduler scheduler;

  SetAlarmEnabledUseCase(this.repository, this.scheduler);

  @override
  Future<Either<Failure, Alarm>> call(SetAlarmEnabledParams params) async {
    final alarm = params.alarm;
    final next = params.enabled
        ? alarm.copyWith(enabled: true, time: nextRingOf(alarm, params.now))
        : alarm.copyWith(enabled: false);
    try {
      params.enabled
          ? await scheduler.schedule(
              next,
              title: alarm.missionName ?? alarm.label ?? '',
            )
          : await scheduler.cancel(alarm.id);
    } catch (e) {
      return Left(
        CacheFailure('Alarm not ${params.enabled ? 'set' : 'stopped'}: $e'),
      );
    }
    return repository.saveAlarm(next);
  }
}
