import '../entities/alarm.dart';

/// One alarm as the device should hold it: the alarm and the text it rings with (its
/// Reason's name).
typedef SystemAlarm = ({Alarm alarm, String title});

/// The device's alarm system (AlarmKit / notifications on iOS, AlarmManager on
/// Android), behind ONE interface: every feature that makes, changes, switches or
/// deletes an alarm goes through it, and nothing else talks to the native alarm
/// channel (the implementation is `SystemAlarmManager`).
abstract class AlarmScheduler {
  /// The gap between an alarm and each of its "Ring again" rings.
  static const Duration ringAgainInterval = Duration(minutes: 5);

  /// The message played once an alarm is stopped (the native layer's own track).
  static const String messageTrack = 'morning_message';

  /// Whether the app may ring alarms (notification / alarm permission granted).
  Future<bool> hasAccess();

  /// Asks for that permission (the system prompt, or its settings page).
  Future<void> requestAccess();

  /// Sets [alarm] on the device (replacing whatever it held for it): every time of its
  /// week (its `sub_alarm` schedules) or its one ring at [Alarm.time], [title] as its
  /// text, its chosen alarm sound (the app's own tune when that file is not on the
  /// device), and [Alarm.ringAgain] more rings, [ringAgainInterval] apart, when it is
  /// stopped without unlocking the phone. A repeating alarm is set again for its next
  /// day by the device after each ring.
  Future<void> schedule(Alarm alarm, {required String title});

  /// Takes alarm [alarmId] off the device: every time of its week, its "Ring again"
  /// rings and their notifications. It never rings again until set again.
  Future<void> cancel(String alarmId);

  /// Makes the device hold exactly [alarms] (every alarm the app has): each switched-on
  /// one is set when it is missing there or anything about it changed (times, days,
  /// text, sound, ring again), each switched-off one is taken off, and anything else
  /// the device still holds (an alarm deleted while the app was away, a leftover) is
  /// removed. A one-off alarm whose ring is over at [now] is not set again.
  Future<void> sync(List<SystemAlarm> alarms, {required DateTime now});

  /// Rings [alarmId] once more at [at] (the ringing screen's Snooze), with [title].
  Future<void> snooze(
    String alarmId, {
    required DateTime at,
    required String title,
  });
}
