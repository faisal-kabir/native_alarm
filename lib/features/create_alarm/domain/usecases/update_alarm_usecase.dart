import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../alarm/domain/entities/alarm.dart';
import '../../../alarm/domain/repositories/alarm_repository.dart';
import '../../../alarm/domain/repositories/alarm_scheduler.dart';
import '../entities/alarm_draft.dart';
import '../entities/alarm_schedule.dart';
import '../repositories/remote_alarm_repository.dart';

class UpdateAlarmParams {
  const UpdateAlarmParams({
    required this.alarm,
    required this.draft,
    required this.title,
    required this.now,
  });

  /// The alarm as it is saved now.
  final Alarm alarm;

  /// What the editor holds (finalized here).
  final AlarmDraft draft;

  /// The (possibly new) Reason's name: the alarm's label and the alarm screen's text.
  final String title;
  final DateTime now;
}

/// Saves an edited alarm everywhere, keeping its id: the server first (its `alarm`
/// row, its `sub_alarm` rows as many as it now has, and its Reason's link moved when
/// the Reason changed; an alarm not sent yet has no server copy and is sent with the
/// pending ones), then the device's row, then the device's alarm system (set again
/// at its next ring, or cancelled when switched off). If a later step fails, the
/// earlier ones are undone, so the alarm stays exactly as it was and the person can
/// simply try again.
@lazySingleton
class UpdateAlarmUseCase implements UseCase<Alarm, UpdateAlarmParams> {
  final AlarmRepository repository;
  final RemoteAlarmRepository remote;
  final AlarmScheduler scheduler;

  UpdateAlarmUseCase(this.repository, this.remote, this.scheduler);

  @override
  Future<Either<Failure, Alarm>> call(UpdateAlarmParams params) async {
    final old = params.alarm;
    final now = params.now;
    var alarm = alarmFromDraft(
      params.draft,
      id: old.id,
      title: params.title,
      now: now,
      audioTrackId: old.audioTrackId,
      remoteId: old.remoteId,
    );

    final onServer = old.remoteId != null;
    if (onServer) {
      final written = await remote.update(old, alarm, now: now);
      if (written.isLeft()) return written;
      alarm = written.getOrElse(() => alarm);
    }

    Future<void> undoServer() async {
      if (onServer) await remote.update(alarm, old, now: now);
    }

    final saved = await repository.saveAlarm(alarm);
    if (saved.isLeft()) {
      await undoServer();
      return saved;
    }

    try {
      alarm.enabled
          ? await scheduler.schedule(alarm, title: params.title)
          : await scheduler.cancel(alarm.id);
      return Right(alarm);
    } catch (e) {
      await undoServer();
      await repository.saveAlarm(old);
      try {
        if (old.enabled) {
          await scheduler.schedule(
            old,
            title: old.missionName ?? old.label ?? '',
          );
        }
      } catch (_) {
        // The device refused both; the saved alarm is the old one either way.
      }
      return Left(CacheFailure('Alarm not scheduled: $e'));
    }
  }
}
