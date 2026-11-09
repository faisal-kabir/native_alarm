import 'package:injectable/injectable.dart';

import '../../../core/platform/alarm_platform_client.dart';
import '../../../core/platform/alarm_schedule_options.dart';
import '../../alarm_audio/domain/entities/alarm_audio.dart';
import '../../alarm_audio/domain/repositories/alarm_audio_repository.dart';
import '../domain/entities/alarm.dart';
import '../domain/repositories/alarm_scheduler.dart';

/// [AlarmScheduler] on the existing native channel (`scheduleAlarm`): Android and iOS
/// read the same keys, so an alarm behaves the same on both.
///
/// Native rings at `timeMs` with the alarm sound's downloaded file (`tuneFile`, copied
/// by native) and, for a repeating alarm, sets each next ring itself from `ringDays`.
/// The soundtrack is not native yet.
@LazySingleton(as: AlarmScheduler)
class PlatformAlarmScheduler implements AlarmScheduler {
  final AlarmPlatformClient client;
  final AlarmAudioRepository audioRepository;

  PlatformAlarmScheduler(this.client, this.audioRepository);

  @override
  Future<bool> hasAccess() => client.hasNotificationPermission();

  @override
  Future<void> requestAccess() => client.requestNotificationPermission();

  @override
  Future<void> schedule(Alarm alarm, {required String title}) async =>
      client.scheduleAlarm({
        'alarmId': alarm.id,
        'timeMs': alarm.time.millisecondsSinceEpoch,
        'audioTrackId': alarm.audioTrackId,
        'missionName': title,
        ...AlarmScheduleOptions(
          repeatCount: alarm.ringAgain,
          repeatIntervalSec: AlarmScheduler.ringAgainInterval.inSeconds,
          tuneFile: await _soundFile(alarm.alarmSoundId),
          ringDays: alarm.ringDays,
          title: title,
        ).toMap(),
      });

  @override
  Future<void> cancel(String alarmId) => client.cancelAlarm(alarmId);

  /// The device's copy of alarm sound [id]; null (the default tune) when none was
  /// chosen or its file is not downloaded.
  Future<String?> _soundFile(int? id) async {
    if (id == null) return null;
    final sounds = await audioRepository
        .watchAudio(AlarmAudioKind.alarmSound)
        .first;
    return sounds.fold((_) => null, (list) {
      for (final sound in list) {
        if (sound.id == id) return sound.audioFile;
      }
      return null;
    });
  }
}
