/// Per-alarm behaviour sent to native code together with `scheduleAlarm`.
///
/// Both Android and iOS read the same keys, so an alarm behaves the same on
/// either platform.
class AlarmScheduleOptions {
  const AlarmScheduleOptions({
    this.repeatCount = 0,
    this.repeatIntervalSec = 300,
    this.tuneAsset,
    this.tuneFile,
    this.ringDays = const {},
    this.title,
    this.subtitle,
    this.stopHintText,
    this.signature,
  });

  /// Internal alarms scheduled when the user slides to stop without unlocking.
  /// `0` means no internal alarm is scheduled at all.
  final int repeatCount;

  /// Seconds between the internal alarms.
  final int repeatIntervalSec;

  /// Flutter asset path of the alarm tune (e.g. `assets/audio/tune.mp3`).
  /// `null` uses the platform default tune.
  final String? tuneAsset;

  /// Full path of a sound file on the device (a downloaded alarm sound). Native keeps
  /// its own copy when the alarm is set, so this file may change or go afterwards.
  /// Wins over [tuneAsset]; a missing or unplayable file rings the default tune.
  final String? tuneFile;

  /// A weekly alarm: weekday (1=Mon .. 7=Sun) → minutes after midnight. Native sets
  /// the next of these rings on its own after each ring. Empty = rings once.
  final Map<int, int> ringDays;

  /// Text next to the alarm icon on the alarm screen. Defaults to the mission text.
  final String? title;

  /// Small text under the clock (Android only; iOS shows the app name).
  final String? subtitle;

  /// Label inside the slider (Android only; iOS text is system-controlled).
  final String? stopHintText;

  /// The alarm's fingerprint (what it was set with); native keeps it and answers it on
  /// `syncAlarms`, so an unchanged alarm is not set again.
  final String? signature;

  Map<String, dynamic> toMap() => {
    'repeatCount': repeatCount,
    'repeatIntervalSec': repeatIntervalSec,
    if (tuneAsset != null) 'tuneAsset': tuneAsset,
    if (tuneFile != null) 'tuneFile': tuneFile,
    if (ringDays.isNotEmpty) 'ringDays': ringDays,
    if (title != null) 'title': title,
    if (subtitle != null) 'subtitle': subtitle,
    if (stopHintText != null) 'stopHintText': stopHintText,
    if (signature != null) 'signature': signature,
  };
}
