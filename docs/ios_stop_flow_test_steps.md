# Real-iPhone Test Guide: iOS Alarm "Stop -> Open App + Play Audio" Flow

This document details the exact testing steps for verifying the alarm Stop action, application foregrounding, and synchronized audio playback on a physical iPhone.

---

## Test Scenarios & Verification Status

| Scenario | Expected Behavior | Verification Status |
| :--- | :--- | :--- |
| **1. Unit Tests (Xcode)** | `consumePendingRequestIfValid` consumes once, expires after 10m, idempotent start, logger records events | **PASS** (Executed via `xcodebuild test` on simulator, all tests passed) |
| **2. Unit Tests (Flutter)** | `consumeAlarmLaunch` method channel calls, parsing, lifecycle | **PASS** (Executed via `flutter test`, all 8 tests passed) |
| **3. Static Analysis** | `flutter analyze` with 0 issues | **PASS** (0 issues) |
| **4. Xcode Simulator Build** | `flutter build ios --debug --no-codesign --simulator` | **PASS** (`✓ Built build/ios/iphonesimulator/Runner.app`) |
| **5. Real-Device Lock Screen Test (App in Background)** | Alarm rings, user presses Stop, app opens to transcript with audio playing, audio continues when locked | **NOT TESTED** (Requires physical tethered iPhone) |
| **6. Real-Device Cold Launch Test (App Force-Quit)** | App force-quit, alarm rings, user presses Stop, app launches to transcript and plays audio | **NOT TESTED** (Requires physical tethered iPhone) |

---

## Physical Device Step-by-Step Test Procedure

### Test A: App in Background / Device Locked
1. **Launch App**: Open **Native Alarm** on the iPhone.
2. **Schedule Alarm**: In the alarm list, create or toggle an alarm set for **2 minutes ahead** with track `"Morning Awakening"`.
3. **Lock Device**: Press the physical side button to lock the iPhone screen.
4. **Wait for Alarm**: Wait for the AlarmKit system alarm interface to appear on the lock screen and Dynamic Island.
5. **Press "Stop"**:
   - On the ringing alarm banner or full-screen alarm interface, press **Stop**.
   - Notice: The alarm sound stops immediately.
6. **Observe App Opening**:
   - Unlock the phone (Face ID / passcode).
   - The **Native Alarm** app opens automatically.
   - The app navigates directly to the **Word-by-Word Synchronized Audio** page.
   - The custom voice message (`demo_alarm_message.mp3`) is actively playing.
   - Words are highlighted in real-time as the audio plays.
7. **Lock Screen Continuity**:
   - With audio playing, press the side button to lock the device again.
   - **Expectation**: Custom audio continues playing smoothly while the screen is locked (`UIBackgroundModes = audio` + `AVAudioSession .playback`).
8. **Re-unlock**:
   - Unlock the device.
   - The transcript page is still visible and binary search synchronization continues tracking the active word.

---

### Test B: App Force-Quit Prior to Alarm
1. **Schedule Alarm**: Open the app and schedule an alarm for **2 minutes ahead**.
2. **Force-Quit App**: Swipe up from the bottom of the screen to open the App Switcher and swipe up on **Native Alarm** to terminate the process.
3. **Lock Device**: Lock the iPhone screen.
4. **Trigger Alarm**: Wait 2 minutes for the system alarm to ring.
5. **Press "Stop"**: Tap **Stop** on the alarm screen.
6. **Unlock Device**:
   - The system opens Native Alarm from a cold start.
   - In `didFinishLaunchingWithOptions`, `checkAndHandlePendingPlayback()` detects the unconsumed pending request recorded by `StopAndPlayIntent`.
   - Audio begins playing immediately.
   - Flutter calls `consumeAlarmLaunch` upon resume, detects `launchedFromAlarm: true`, and navigates to the transcript page.

---

## How to Inspect Logs & Diagnose on Device

### 1. Unified Console Logs (Mac Console.app)
1. Connect the iPhone to a Mac via USB.
2. Open **Console.app** on macOS.
3. Select your iPhone under **Devices**.
4. Set the search filter:
   ```
   subsystem:com.example.nativeAlerm category:AlarmFlow
   ```
5. Look for the following log sequence:
   ```text
   [AlarmFlow] StopAndPlayIntent.perform() entered for alarmId=..., trackId=demo_alarm_message
   [AlarmFlow] StopAndPlayIntent: Calling AlarmManager.shared.stop(id: ...)
   [AlarmFlow] StopAndPlayIntent: AlarmManager.shared.stop succeeded for ...
   [AlarmFlow] PendingPlaybackManager: Recorded request for alarmId=..., trackId=demo_alarm_message
   [AlarmFlow] AudioPlaybackManager.start() called for audioTrackId='demo_alarm_message'
   [AlarmFlow] AudioPlaybackManager: Resolving asset for trackId='demo_alarm_message', main bundlePath=...
   [AlarmFlow] AudioPlaybackManager: Resolved via Frameworks/App.framework direct path -> ...
   [AlarmFlow] AudioPlaybackManager: Configuring AVAudioSession (.playback, mode: .spokenAudio)
   [AlarmFlow] AudioPlaybackManager: Activating AVAudioSession (isRetry=false)...
   [AlarmFlow] AudioPlaybackManager: AVAudioSession activated successfully.
   [AlarmFlow] AudioPlaybackManager: Creating AVAudioPlayer for ...
   [AlarmFlow] AudioPlaybackManager: newPlayer.play() returned true
   [AlarmFlow] SceneDelegate: sceneDidBecomeActive
   [AlarmFlow] AppDelegate: consumeAlarmLaunch returning launchedFromAlarm=true, trackId=demo_alarm_message
   ```

### 2. Reading UserDefaults Without Xcode Attached
If Xcode or Console.app is not connected, the last 50 key log entries are persisted in `UserDefaults` under the key:
```swift
UserDefaults.standard.stringArray(forKey: "alarmflow.debugLog")
```
You can query this in Flutter anytime by calling:
```dart
final logs = await alarmPlatformClient.getDebugLogs();
for (final log in logs) {
  debugPrint(log);
}
```
Or via LLDB / idevicesyslog / ideviceinstaller:
```bash
xcrun simctl spawn booted defaults read com.example.nativeAlerm alarmflow.debugLog
```
