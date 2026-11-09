import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../alarm/domain/entities/alarm.dart';
import '../../../alarm/domain/repositories/alarm_repository.dart';
import '../../../alarm/domain/repositories/alarm_scheduler.dart';
import '../entities/alarm_schedule.dart';

class RescheduleAlarmsParams {
  const RescheduleAlarmsParams(this.now);

  final DateTime now;
}

/// Keeps repeating alarms set, run every time the app opens: an enabled alarm with
/// days whose ring (and its "Ring again" rings) is over moves to its next day
/// ([nextRingOf]), is set on the device again (with its sound) and saved with that
/// time. The device already sets the next ring by itself after each ring; this keeps
/// the saved time true and sets the alarm again when the device lost it. An alarm the
/// device refuses keeps its old time, so the next open tries again. One-off alarms
/// are left alone. Answers how many alarms moved; two calls at once run only once.
@lazySingleton
class RescheduleAlarmsUseCase implements UseCase<int, RescheduleAlarmsParams> {
  final AlarmRepository repository;
  final AlarmScheduler scheduler;

  RescheduleAlarmsUseCase(this.repository, this.scheduler);

  Future<Either<Failure, int>>? _running;

  @override
  Future<Either<Failure, int>> call(RescheduleAlarmsParams params) =>
      _running ??= _run(params.now).whenComplete(() => _running = null);

  Future<Either<Failure, int>> _run(DateTime now) async =>
      (await repository.getAlarms()).fold((failure) async => Left(failure), (
        alarms,
      ) async {
        var moved = 0;
        for (final alarm in alarms.where((a) => _isOver(a, now))) {
          final next = alarm.copyWith(time: nextRingOf(alarm, now));
          try {
            await scheduler.schedule(
              next,
              title: alarm.missionName ?? alarm.label ?? '',
            );
          } catch (_) {
            continue;
          }
          if ((await repository.saveAlarm(next)).isRight()) moved++;
        }
        return Right(moved);
      });

  /// A repeating alarm whose last possible ring (with every "Ring again") has passed.
  static bool _isOver(Alarm alarm, DateTime now) =>
      alarm.enabled &&
      alarm.repeatWeekdays.isNotEmpty &&
      !now.isBefore(
        alarm.time.add(
          AlarmScheduler.ringAgainInterval * (alarm.ringAgain + 1),
        ),
      );
}
