/// Per-alarm behaviour sent to native code together with `scheduleAlarm`.
///
/// Both Android and iOS read the same keys, so an alarm behaves the same on
/// either platform.
class AlarmScheduleOptions {
  const AlarmScheduleOptions({
    this.repeatCount = 2,
    this.repeatIntervalSec = 10,
    this.tuneAsset,
    this.title,
    this.subtitle,
    this.stopHintText,
  });

  /// Internal alarms scheduled when the user slides to stop without unlocking.
  /// `0` means no internal alarm is scheduled at all.
  final int repeatCount;

  /// Seconds between the internal alarms.
  final int repeatIntervalSec;

  /// Flutter asset path of the alarm tune (e.g. `assets/audio/tune.mp3`).
  /// `null` uses the platform default tune.
  final String? tuneAsset;

  /// Text next to the alarm icon on the alarm screen. Defaults to the mission text.
  final String? title;

  /// Small text under the clock (Android only; iOS shows the app name).
  final String? subtitle;

  /// Label inside the slider (Android only; iOS text is system-controlled).
  final String? stopHintText;

  Map<String, dynamic> toMap() => {
    'repeatCount': repeatCount,
    'repeatIntervalSec': repeatIntervalSec,
    if (tuneAsset != null) 'tuneAsset': tuneAsset,
    if (title != null) 'title': title,
    if (subtitle != null) 'subtitle': subtitle,
    if (stopHintText != null) 'stopHintText': stopHintText,
  };
}
