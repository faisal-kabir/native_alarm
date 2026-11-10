import 'dart:convert';

import 'package:injectable/injectable.dart';

import '../../../core/platform/alarm_platform_client.dart';
import '../../../core/platform/alarm_schedule_options.dart';
import '../../alarm_audio/domain/entities/alarm_audio.dart';
import '../../alarm_audio/domain/repositories/alarm_audio_repository.dart';
import '../domain/entities/alarm.dart';
import '../domain/repositories/alarm_scheduler.dart';

/// The one place the app talks to the device's alarm system ([AlarmScheduler]), on the
/// native channel both platforms read the same way (`scheduleAlarm`, `cancelAlarm`,
/// `syncAlarms`).
///
/// An alarm is sent with everything native needs to ring it alone, app closed: its
/// next ring (`timeMs`), its week (`ringDays`: weekday 1 = Mon .. 7 = Sun → minutes,
/// one entry per day of every schedule), its text (the Reason's name), its alarm
/// sound's downloaded file (`tuneFile`, which native copies), Ring again
/// (`repeatCount`, 300 s apart) and a `signature` of all that, which native keeps:
/// [sync] sets again only an alarm whose signature differs from what native holds.
@LazySingleton(as: AlarmScheduler)
class SystemAlarmManager implements AlarmScheduler {
  final AlarmPlatformClient client;
  final AlarmAudioRepository audioRepository;

  SystemAlarmManager(this.client, this.audioRepository);

  @override
  Future<bool> hasAccess() => client.hasNotificationPermission();

  @override
  Future<void> requestAccess() => client.requestNotificationPermission();

  @override
  Future<void> schedule(Alarm alarm, {required String title}) async {
    final sounds = await _soundFiles();
    await client.scheduleAlarm(
      _payload(alarm, title, sounds[alarm.alarmSoundId]),
    );
  }

  @override
  Future<void> cancel(String alarmId) => client.cancelAlarm(alarmId);

  @override
  Future<void> sync(List<SystemAlarm> alarms, {required DateTime now}) async {
    final held = await client.syncAlarms([for (final a in alarms) a.alarm.id]);
    final sounds = await _soundFiles();
    for (final (:alarm, :title) in alarms) {
      if (!alarm.enabled) {
        if (held.containsKey(alarm.id)) await cancel(alarm.id);
        continue;
      }
      // A one-off alarm whose ring is over is switched off by the app, not set again.
      if (alarm.repeatWeekdays.isEmpty && !alarm.time.isAfter(now)) continue;
      final payload = _payload(alarm, title, sounds[alarm.alarmSoundId]);
      if (held[alarm.id] != payload['signature']) {
        await client.scheduleAlarm(payload);
      }
    }
  }

  @override
  Future<void> snooze(
    String alarmId, {
    required DateTime at,
    required String title,
  }) => client.scheduleAlarm({
    // Native keeps a pending snooze through a sync (the prefix), until it has rung.
    'alarmId': 'snooze_$alarmId',
    'timeMs': at.millisecondsSinceEpoch,
    'audioTrackId': AlarmScheduler.messageTrack,
    'missionName': title,
    ...AlarmScheduleOptions(title: title).toMap(),
  });

  /// What native is sent for [alarm]: one map, with the [signature] of it all.
  Map<String, dynamic> _payload(Alarm alarm, String title, String? tuneFile) {
    final ringDays = alarm.ringDays;
    final signature = jsonEncode({
      'title': title,
      'tune': tuneFile,
      'again': alarm.ringAgain,
      // A week rings by its days; a one-off at its moment.
      if (ringDays.isEmpty)
        'at': alarm.time.millisecondsSinceEpoch
      else
        'days': [
          for (final d in ringDays.keys.toList()..sort()) [d, ringDays[d]],
        ],
    });
    return {
      'alarmId': alarm.id,
      'timeMs': alarm.time.millisecondsSinceEpoch,
      'audioTrackId': alarm.audioTrackId,
      'missionName': title,
      ...AlarmScheduleOptions(
        repeatCount: alarm.ringAgain,
        repeatIntervalSec: AlarmScheduler.ringAgainInterval.inSeconds,
        tuneFile: tuneFile,
        ringDays: ringDays,
        title: title,
        signature: signature,
      ).toMap(),
    };
  }

  /// The device's copy of every alarm sound, by id (only those downloaded).
  Future<Map<int, String>> _soundFiles() async {
    final sounds = await audioRepository
        .watchAudio(AlarmAudioKind.alarmSound)
        .first;
    return sounds.fold(
      (_) => const {},
      (list) => {
        for (final s in list)
          if (s.audioFile != null) s.id: s.audioFile!,
      },
    );
  }
}
