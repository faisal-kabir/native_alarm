import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/constants/app_constant.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../alarm/domain/entities/alarm.dart';
import '../../../alarm/domain/repositories/alarm_repository.dart';
import '../../../alarm/domain/repositories/alarm_scheduler.dart';
import '../entities/alarm_draft.dart';
import '../entities/alarm_schedule.dart';
import '../repositories/remote_alarm_repository.dart';
import 'upload_pending_alarms_usecase.dart';

/// Every alarm place is taken ([AppConstant.maxAlarmCount]).
class AlarmLimitFailure extends Failure {
  const AlarmLimitFailure() : super('Alarm limit reached');
}

class CreateAlarmParams {
  const CreateAlarmParams({
    required this.draft,
    required this.title,
    required this.now,
  });

  /// What the editor holds (finalized here).
  final AlarmDraft draft;

  /// The Reason's name: the alarm's label and the alarm screen's text.
  final String title;
  final DateTime now;
}

/// Makes a new alarm from the editor's [AlarmDraft]: never more than
/// [AppConstant.maxAlarmCount]. It goes to the server first (`alarm`, `sub_alarm`, the
/// Reason's `alarm_id`) and is kept on the device as the server answered it; offline
/// it is kept on the device only and sent when the app next opens online
/// ([UploadPendingAlarmsUseCase]). Then (when enabled) it is set to ring at its next
/// time. If the device's alarm system refuses it, nothing is kept anywhere, so the
/// person can simply try again.
@lazySingleton
class CreateAlarmUseCase implements UseCase<Alarm, CreateAlarmParams> {
  final AlarmRepository repository;
  final RemoteAlarmRepository remote;
  final AlarmScheduler scheduler;

  CreateAlarmUseCase(this.repository, this.remote, this.scheduler);

  /// The message played once it is stopped (the native layer's own track).
  static const String messageTrack = 'morning_message';

  @override
  Future<Either<Failure, Alarm>> call(CreateAlarmParams params) async =>
      (await repository.getAlarms()).fold(
        (failure) async => Left(failure),
        (alarms) async => alarms.length >= AppConstant.maxAlarmCount
            ? const Left(AlarmLimitFailure())
            : _create(params),
      );

  Future<Either<Failure, Alarm>> _create(CreateAlarmParams params) async {
    final draft = finalize(params.draft);
    final made = Alarm(
      id: 'alarm_${params.now.microsecondsSinceEpoch}',
      enabled: draft.enabled,
      time: nextRing(draft, params.now),
      repeatWeekdays: [for (final d in draft.days) alarmWeekday(d)]..sort(),
      audioTrackId: messageTrack,
      ringtoneId: draft.alarmSoundId?.toString() ?? 'default',
      label: params.title,
      missionName: params.title,
      reasonId: draft.reasonId,
      soundTrackId: draft.soundTrackId,
      alarmSoundId: draft.alarmSoundId,
      ringAgain: draft.again,
      dayTimes: draft.byDay?.map(
        (day, time) => MapEntry(alarmWeekday(day), time.minutesOfDay),
      ),
    );

    final alarm = (await remote.upload(
      made,
      now: params.now,
    )).getOrElse(() => made);

    final saved = await repository.saveAlarm(alarm);
    if (saved.isLeft()) {
      await _removeRemote(alarm);
      return saved;
    }
    if (!alarm.enabled) return Right(alarm);
    try {
      await scheduler.schedule(alarm, title: params.title);
      return Right(alarm);
    } catch (e) {
      await repository.deleteAlarm(alarm.id);
      await _removeRemote(alarm);
      return Left(CacheFailure('Alarm not scheduled: $e'));
    }
  }

  /// Takes back the server's copy of an alarm the device did not keep.
  Future<void> _removeRemote(Alarm alarm) async {
    final remoteId = alarm.remoteId;
    if (remoteId != null) await remote.remove(remoteId);
  }
}
