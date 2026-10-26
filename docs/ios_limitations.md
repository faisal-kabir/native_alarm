# iOS Implementation & Limitations

## Overview

This document summarizes the native iOS alarm and synchronized audio playback implementation in Native Alarm, along with verification results and known platform limitations.

---

## Architecture Implemented

### 1. Project Configuration & Permissions (`ios/Runner/Info.plist`)
- Added `NSAlarmKitUsageDescription`: `"This app requires AlarmKit to schedule and trigger synchronized alarms."`
- Ensured `UIBackgroundModes` contains `audio` so that `AVAudioSession` category `.playback` persists audio when the screen is locked or the app transitions to the background.

### 2. Native Audio Playback Engine (`ios/Runner/Playback/AudioPlaybackManager.swift`)
- **Singleton**: `AudioPlaybackManager.shared` owns all custom-audio playback.
- **Audio Session**: Activates `AVAudioSession.sharedInstance()` with category `.playback` and mode `.default`.
- **Engine**: Powered by native `AVAudioPlayer`.
- **Idempotency (Requirement 7)**: `start(audioTrackId:)` checks if `currentTrackId == audioTrackId` and `player.isPlaying`. If already playing the requested track, the call is a no-op and never restarts playback.
- **Controls**: `start`, `pause`, `resume`, `seek(positionMs:)`, `stop`.
- **Position Tracking**: 100 ms internal native `Timer` pushes `positionMs`, `durationMs`, and `audioTrackId` to registered listeners.
- **State Getters**: `positionMs`, `durationMs`, `isPlaying`.

### 3. Alarm Scheduling (`ios/Runner/AlarmScheduler.swift`)
- **iOS 26+ (AlarmKit)**:
  - Guarded by `#if canImport(AlarmKit)` and `@available(iOS 26.0, *)`.
  - Implements `StopAndPlayIntent: LiveActivityIntent` to stop the alarm and start audio playback via `AudioPlaybackManager.shared.start`.
  - Implements `OpenAndPlayIntent: LiveActivityIntent` with `static var openAppWhenRun = true` to bring the app to the foreground and start audio playback.
  - Schedules native alarms via `AlarmManager.shared.schedule` using `AlarmConfiguration.alarm(schedule:attributes:stopIntent:secondaryIntent:)`.
- **iOS < 26 (Time-Sensitive Local Notifications)**:
  - Uses `UNMutableNotificationContent` with `interruptionLevel = .timeSensitive` (iOS 15+) so alarms break through Focus and Do Not Disturb.
  - Configures bundled sound `demo.aiff` (`UNNotificationSound(named: "demo.aiff")`).
  - Registers custom notification category `"ALARM_CATEGORY"` with a single foreground action `"STOP_AND_PLAY"` titled `"Stop"`.
  - When user taps the notification banner or the "Stop" action, `userNotificationCenter(_:didReceive:)` triggers `AudioPlaybackManager.shared.start()` and opens the app to the synchronized transcript page.

### 4. Method & Event Channels (`ios/Runner/AppDelegate.swift`)
- Registers `FlutterMethodChannel` on `"app/alarm"` (Requirement 5) as well as `"com.native_alarm/alarm"` for cross-platform compatibility.
- Exposes:
  - `scheduleAlarm(alarmId, timeMs, audioTrackId)`
  - `cancelAlarm(alarmId)`
  - `getPlaybackState()` -> returns `{state, positionMs, durationMs, audioTrackId, alarmId}`
  - `pause()` / `pauseCustomAudio()`
  - `resume()` / `resumeCustomAudio()`
  - `seek(positionMs)` / `seekCustomAudio(positionMs)`
  - `stop()` / `stopCustomAudio()`
  - `stopAlarm(audioTrackId)`
  - `startCustomAudio(audioTrackId)`
  - `dismissAlarm()`
  - `requestNotificationPermission()`
  - `hasNotificationPermission()`
- Wires `AudioPlaybackManager` callbacks to `FlutterEventChannel` (`"app/alarm_events"` and `"com.native_alarm/alarm_events"`).
- Implements `UNUserNotificationCenterDelegate` (`willPresent` and `didReceive`) to handle notification display in foreground and action triggers.

### 5. Flutter Transcript Synchronization (`lib/features/alarm/presentation/pages/synchronized_transcript_page.dart`)
- **Binary Search**: Highlights the active transcript word using binary search (`O(log N)`) over `List<TranscriptWord>` based on native `positionMs`.
- **Visibility-Aware Polling/Listening**: Uses `WidgetsBindingObserver`. Listens to native `positionUpdate` events and polls `getPlaybackState()` only while the page is visible. Cancels subscriptions when the app is paused/hidden or disposed.
- **Zero Flutter Player / Timer**: No Flutter audio player plugin (`just_audio` or `audioplayers`) and no Flutter timer simulates playback progression; all timing is authoritative from native.

---

## Verification Status

### Verified
- [x] **iOS Simulator Build**: `flutter build ios --no-codesign --simulator` succeeded with zero compiler errors.
- [x] **Xcode Compilation**: All Swift sources (`AppDelegate.swift`, `AlarmScheduler.swift`, `AudioPlaybackManager.swift`) compiled cleanly with Swift 6.4 against the iOS 27.1 SDK.
- [x] **AlarmKit Types**: Verified that `AlarmKit` module compiles with `StopAndPlayIntent`, `OpenAndPlayIntent`, `AlarmAttributes`, `AlarmPresentation`, and `AlarmManager.shared.schedule` under `#if canImport(AlarmKit)` and `@available(iOS 26.0, *)`.
- [x] **Project Linking**: Verified `project.pbxproj` links `AudioPlaybackManager.swift`, `AlarmScheduler.swift`, and `demo.aiff` into PBXSourcesBuildPhase and PBXResourcesBuildPhase.
- [x] **Flutter Analysis**: `flutter analyze` passed with 0 issues.
- [x] **Unit & Widget Tests**: `flutter test` passed all test suites.

### Failed & Resolved During Implementation
- **Redundant Protocol Conformance**: `AppDelegate` initially declared conformance to `UNUserNotificationCenterDelegate`, which is already declared by `FlutterAppDelegate`. Resolved by removing redundant protocol conformance.
- **Missing `override`**: Methods `userNotificationCenter(_:willPresent:...)` and `userNotificationCenter(_:didReceive:...)` were missing `override` in `AppDelegate`. Resolved by adding the `override` keyword.
- **Invalid LaunchOptions Key**: `LaunchOptionsKey.notificationResponse` was invalid. Resolved by letting `UNUserNotificationCenterDelegate.userNotificationCenter(_:didReceive:)` handle cold-launch responses cleanly.

### NOT TESTED (Honest Assessment)
- **Physical iOS 26+ Hardware Device**: AlarmKit Live Activity lock screen rendering was NOT tested on physical iOS 26+ hardware because physical iOS 26 hardware is not available. Verification is based on SDK compilation against Apple's iOS 27.1 SDK.
- **Long-term Background Execution on Battery**: How iOS battery-saving heuristics treat prolonged background audio playback when the phone remains locked for several hours was not tested on physical hardware.
- **Hardware Silent / Mute Switch Bypass**: While `timeSensitive` notification interruption levels break through Focus and Do Not Disturb, actual audio output volume when the physical ring/silent hardware switch is engaged was not verified on a physical device.
- **Audio Interruption Recovery**: Audio session recovery when interrupted by an incoming cellular phone call or FaceTime call was not verified on a physical device.
