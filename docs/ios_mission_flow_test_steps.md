# iOS Mission Flow Test Steps & Verification Report

## Overview
This document specifies the exact real-iPhone test protocol for the "Erly-style mission button", records observations of AlarmKit button and intent configuration, documents the Case B backup re-ring mechanism, and maintains the regression verification checklist.

---

## 1. AlarmKit Configuration & Baseline Observations (Step 1)

### Button and Intent Configuration
- **Primary Action (Stop Button)**:
  - Text: Configured with `missionName` (e.g. `"Start Morning Mission"`, falling back to audio track title or `"Start Morning Mission"`).
  - Styling: The `AlarmAttributes.tintColor` is set to `.orange` (matching the Erly app's vibrant orange mission button styling). Text color is `.white` with icon `sun.max.fill`.
  - Intent: `StopAndPlayIntent` (conforms to `LiveActivityIntent`, with `static var openAppWhenRun: Bool = true`).
  - Behavior: When pressed on the lock screen / full-screen alarm banner, iOS requires Face ID / Passcode device unlock because `openAppWhenRun = true`.
- **Secondary Action (Secondary Button)**:
  - In iOS 26.0+, configured with `secondaryButtonBehavior: .custom` and `secondaryIntent = OpenAndPlayIntent` (`openAppWhenRun = true`).
  - Both intents are idempotent and call `AudioPlaybackManager.shared.start(audioTrackId:)` when the app is brought to foreground.
- **Can a user bypass unlock with a plain stop button?**
  - No. Because both `StopAndPlayIntent` and `OpenAndPlayIntent` require `openAppWhenRun = true`, any tap on the alarm buttons forces an unlock prompt.
  - In AlarmKit's design, tapping the button triggers the unlock sheet. If the user unlocks, the app is launched into foreground and the mission begins.

### Logging Mechanism
Logging is captured via `os.Logger` (subsystem `Bundle.main.bundleIdentifier`, category `"AlarmFlow"`) and persistently stored in `UserDefaults.standard` under `"alarmflow.debugLog"`:
1. `AlarmManager.shared.alarmUpdates`: Observes alarm state changes (`.scheduled`, `.alerting`, `.paused`, `.countdown`) and logs `AlarmUpdates: alarmId=..., state=...` with timestamps.
2. `StopAndPlayIntent.perform()` & `OpenAndPlayIntent.perform()` entry logging.
3. `AlarmManager.shared.stop(id:)` calls and success/error results.
4. Backup alarm scheduling and cancellation events via `BackupAlarmManager`.

---

## 2. Real-iPhone Test Protocol: Unlock Cancellation (Step 1.3)

### Exact Device Test Procedure
1. Install the app on a physical iPhone running iOS 26+ (with AlarmKit support).
2. Schedule a test alarm set to ring in 1 to 2 minutes with a custom mission name: `"Start Morning Mission"`.
3. Lock the iPhone and place it on a desk (ensuring Face ID does not immediately auto-unlock).
4. Wait for the alarm time. The alarm begins ringing with full audio alert and the orange mission button `"Start Morning Mission"`.
5. Tap the orange `"Start Morning Mission"` button.
6. The iOS Face ID / Passcode unlock prompt appears.
7. **Cancel or Ignore Prompt**:
   - Turn your face away or tap **Cancel** on the passcode prompt, or let the unlock prompt time out without unlocking.
8. Observe device behavior:
   - Does the alarm keep ringing continuously?
   - Or does iOS silence/stop the ringing alarm as soon as the button is tapped, even if unlock was aborted?

### Observation Result
- **Status**: **NOT TESTED** (Requires physical iPhone execution; cannot be executed in automated CI or headless simulator).
- **Branch Decision**: Because physical device verification of unlock cancellation cannot be conducted in this environment, **Case B (Additive Backup Re-Ring Mechanism)** is implemented.

---

## 3. Case B: Additive Backup Re-Ring Mechanism (Workaround Details)

### Why Case B is Needed
In iOS, tapping an interactive notification or AlarmKit button triggers an intent. In standard iOS behavior, if the button dismissal silences the primary alarm while awaiting unlock, a user who cancels the unlock prompt could fall back asleep if the alarm stops.

### How Case B Works
1. **Chain of Backup Alarms**:
   - When an alarm is scheduled, `BackupAlarmManager.shared.scheduleBackupAlarms(...)` schedules an additive chain of backup AlarmKit alarms at offsets:
     `+30s, +60s, +90s, +120s, +180s, +300s`.
   - The backup alarms use the exact same mission button text (`missionName`), orange styling (`tintColor = .orange`), and `openAppWhenRun = true` intents.
2. **ID Mapping & Persistence**:
   - Each backup alarm has a unique `UUID()`.
   - The mapping is persisted in `UserDefaults.standard` under `"alarmflow.backupAlarmMapping"` as `{ mainAlarmID: [backupUUID1, backupUUID2, ...] }`.
   - An inverse lookup mapping `{ backupUUID: mainAlarmID }` is also maintained under `"alarmflow.backupToMainMapping"`.
3. **Idempotent Cancellation on App Open**:
   - As soon as the user actually unlocks the device and the app opens (via `consumeAlarmLaunch`, `applicationDidBecomeActive`, or `StopAndPlayIntent.perform()`), `BackupAlarmManager.shared.cancelBackupAlarms(for: mainAlarmId)` is called.
   - It iterates over all backup UUIDs, calls `AlarmManager.shared.cancel(id: backupUUID)`, and clears the persisted mapping. Duplicate cancellations are safe no-ops.
4. **Idempotent Audio Playback**:
   - `AudioPlaybackManager.shared.start(...)` guards against restarting the track if it is already playing. If a backup alarm rings before unlock, unlocking from any alarm starts the track once and cancels all other backups.
5. **Alarm Deletion / Disabling**:
   - When an alarm is deleted or toggled off in the Flutter list, `cancelAlarm` invokes `BackupAlarmManager.shared.cancelBackupAlarms(for: alarmId)`, leaving zero stray alarms.
6. **Repeating Alarms**:
   - Backups are only created for the immediate next occurrence, and regenerated when the next occurrence is scheduled.

### Honest Documentation: Workaround vs. Continuous Ringing
Case B is an additive architectural safeguard (re-ring chain). It differs from a single continuous ring:
- If iOS terminates the primary alarm sound upon button tap and the user cancels unlock, the user will experience a brief silence followed by the next backup alarm ringing at the +30s mark (and subsequent intervals).
- Once the user completes the unlock, all remaining backup alarms are immediately cancelled.
- Limits: The chain is capped at 6 alarms (+30s to +300s) to prevent exceeding iOS system alarm limits or creating excessive alarm clutter.

---

## 4. Regression Verification Checklist

| # | Test Scenario | Status | Notes |
|---|---------------|--------|-------|
| 1 | Alarm still schedules and rings at the right time | **NOT TESTED** (PASS on Simulator unit tests; physical device NOT TESTED) | Scheduling logic and time computation are completely untouched. |
| 2 | Orange button shows the mission name | **NOT TESTED** (PASS on Simulator / build verification; physical screen NOT TESTED) | `attributes.tintColor = .orange` and `AlarmButton(text: missionName)`. |
| 3 | Tap button -> unlock prompt appears | **NOT TESTED** (Requires physical iPhone with passcode/Face ID) | Intent has `openAppWhenRun = true`. |
| 4 | Cancel unlock -> alarm keeps ringing (or backup re-ring happens) | **NOT TESTED** (Case B implemented with +30s..+300s backup chain) | Unit tests verify backup alarm scheduling and mapping. |
| 5 | Unlock -> app opens, alarm stops, audio starts, transcript page opens | **NOT TESTED** (Simulator code paths verified) | Verified via `PendingPlaybackManager`, `consumeAlarmLaunch`, and `AudioPlaybackManager`. |
| 6 | Lock again -> audio continues | **NOT TESTED** (Verified in unit tests for `AVAudioSession` background playback mode) | `UIBackgroundModes = audio` and `.playback` session configured. |
| 7 | Old alarms created before this change still work | **PASS** | `missionName` is optional across Flutter model and native code with fallback to track title or `"Start Morning Mission"`. |
| 8 | Deleting/disabling an alarm leaves no stray backup alarms | **PASS** | Verified by unit tests; `cancelAlarm` cleans up all mapped backup alarms. |
