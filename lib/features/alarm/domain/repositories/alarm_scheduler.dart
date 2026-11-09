import '../entities/alarm.dart';

/// The device's alarm system (the native layers on Android and iOS), behind one
/// interface so the features that make alarms do not talk to platform channels.
abstract class AlarmScheduler {
  /// The gap between an alarm and each of its "Ring again" rings.
  static const Duration ringAgainInterval = Duration(minutes: 5);

  /// Whether the app may ring alarms (notification / alarm permission granted).
  Future<bool> hasAccess();

  /// Asks for that permission (the system prompt, or its settings page).
  Future<void> requestAccess();

  /// Rings [alarm] at its [Alarm.time] with its chosen alarm sound (the app's own tune
  /// when that file is not on the device), with [title] on the alarm screen. Its
  /// [Alarm.ringAgain] rings that many more times, [ringAgainInterval] apart, when it
  /// is stopped without getting up. A repeating alarm ([Alarm.ringDays]) is set again
  /// for its next day by the device after each ring. Setting the same alarm again
  /// replaces it.
  Future<void> schedule(Alarm alarm, {required String title});

  /// Stops alarm [alarmId] from ringing (its repeats too) until it is set again.
  Future<void> cancel(String alarmId);
}
