import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../alarm/domain/repositories/alarm_repository.dart';
import '../../../alarm/domain/repositories/alarm_scheduler.dart';
import '../../../alarm/domain/usecases/get_alarms_usecase.dart';
import '../../../reasons/domain/entities/reason.dart';
import '../../../reasons/domain/repositories/reason_repository.dart';
import '../entities/alarm_schedule.dart';

class SyncSystemAlarmsParams {
  const SyncSystemAlarmsParams(this.now);

  final DateTime now;
}

/// Keeps the device's alarm system exactly in step with the saved alarms. Runs when the
/// app opens or comes back, when the alarm sounds have been brought up to date and
/// after a Reason is renamed; works offline.
/// * One-off alarms that have rung are switched off ([GetAlarmsUseCase]).
/// * A repeating alarm whose ring (and its "Ring again" rings) is over is saved with
///   its next ring ([nextRingOf]).
/// * Each alarm's text follows its Reason's current name (saved too).
/// * Then [AlarmScheduler.sync]: switched-on alarms set where missing or changed (a
///   sound file downloaded since, a new name, an app reinstall), switched-off ones taken
///   off, anything else the device holds removed.
/// Two calls at once run only once.
@lazySingleton
class SyncSystemAlarmsUseCase implements UseCase<Unit, SyncSystemAlarmsParams> {
  final GetAlarmsUseCase getAlarms;
  final AlarmRepository repository;
  final ReasonRepository reasons;
  final AlarmScheduler scheduler;

  SyncSystemAlarmsUseCase(
    this.getAlarms,
    this.repository,
    this.reasons,
    this.scheduler,
  );

  Future<Either<Failure, Unit>>? _running;

  @override
  Future<Either<Failure, Unit>> call(SyncSystemAlarmsParams params) =>
      _running ??= _run(params.now).whenComplete(() => _running = null);

  Future<Either<Failure, Unit>> _run(DateTime now) async {
    final saved = await getAlarms(NoParams());
    if (saved.isLeft()) return saved.map((_) => unit);
    final names = {
      for (final r in (await reasons.watchReasons().first).getOrElse(
        () => const <Reason>[],
      ))
        r.id: r.name,
    };

    final system = <SystemAlarm>[];
    for (var alarm in saved.getOrElse(() => const [])) {
      final title =
          names[alarm.reasonId] ?? alarm.missionName ?? alarm.label ?? '';
      final over =
          alarm.enabled &&
          alarm.repeatWeekdays.isNotEmpty &&
          !now.isBefore(
            alarm.time.add(
              AlarmScheduler.ringAgainInterval * (alarm.ringAgain + 1),
            ),
          );
      if (over || title != alarm.missionName) {
        alarm = alarm.copyWith(
          time: over ? nextRingOf(alarm, now) : null,
          label: title,
          missionName: title,
        );
        await repository.saveAlarm(alarm);
      }
      system.add((alarm: alarm, title: title));
    }

    try {
      await scheduler.sync(system, now: now);
      return const Right(unit);
    } catch (e) {
      return Left(CacheFailure('Alarms not synced: $e'));
    }
  }
}
