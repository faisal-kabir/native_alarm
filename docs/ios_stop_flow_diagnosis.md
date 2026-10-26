# iOS Alarm "Stop -> Open App + Play Audio" Flow Diagnosis

## 1. Intent Target Membership & Definition
- **Location**: `StopAndPlayIntent` and `OpenAndPlayIntent` are defined in [AlarmScheduler.swift](file:///Users/faisalkabir/StudioProjects/Client_Project/native_alerm/ios/Runner/AlarmScheduler.swift).
- **Target Membership**: `AlarmScheduler.swift` is a member of the **Runner** target in `ios/Runner.xcodeproj/project.pbxproj`.
- **Widget Extension**: No Widget Extension target exists in the Xcode project (`RunnerTests` and `Runner` are the only two native targets).

## 2. Root Cause Analysis

### Issue A: App Does NOT Open After Pressing Stop
1. **Missing `openAppWhenRun` on `StopAndPlayIntent`**:
   `OpenAndPlayIntent` had `static var openAppWhenRun: Bool = true`, but `StopAndPlayIntent` (the actual intent triggered when the user taps "Stop") did **not** have `openAppWhenRun = true`.
   As a consequence, iOS executed `StopAndPlayIntent` as a background LiveActivityIntent without foregrounding or launching the application.

### Issue B: Custom Audio Does NOT Play After Pressing Stop
1. **Alarm Sound Handoff (`AlarmManager.stop(id:)`)**:
   `StopAndPlayIntent.perform()` never called `AlarmManager.shared.stop(id: uuid)` to silence the ringing alarm. The system alarm sound remained active, competing for the audio session.
2. **Audio Asset Path Resolution in App Bundle**:
   In `AudioPlaybackManager.start`, asset resolution only attempted `Bundle.main.path(forResource: key, ofType: nil)`.
   In Flutter iOS apps, assets are located inside `Frameworks/App.framework/flutter_assets/assets/audio/demo_alarm_message.mp3` relative to `Bundle.main.bundlePath`. When `FlutterDartProject.lookupKey` does not resolve or if bundle path lookup fails, the method returned early via `guard let path` without fallback to direct file path checking or descriptive logging.
3. **AVAudioSession Activation & Mode**:
   `AVAudioSession` was set to `.default` mode instead of `.spokenAudio`. Additionally, `setActive(true)` was called without a retry mechanism. When the alarm tone is ending, the system audio session often requires a brief window (~300ms) before relinquishing exclusive audio routing to the application.
4. **No Persistent Pending Playback Request**:
   If the intent executes while the app is in the background or device is transitioning states, background execution time may expire before playback initializes. Without a persistent pending request written to `UserDefaults`, the application delegate had no mechanism to resume or start playback upon becoming active.
5. **Silent Failures with `try?`**:
   Errors thrown during intent execution and audio session activation were silenced via `try?` without logging to `os.Logger` or `UserDefaults`.

## 3. Required Fix Plan
1. **Intents**: Set `static var openAppWhenRun: Bool = true` on `StopAndPlayIntent`. Stop the alarm via `AlarmManager.shared.stop(id:)` before starting playback.
2. **Persistent Request**: Write a pending playback request to `UserDefaults` (key `"alarmflow.pendingRequest"`) in `perform()`.
3. **App Launch/Resume Lifecycle**: In `AppDelegate` and `SceneDelegate` (`didFinishLaunchingWithOptions`, `applicationDidBecomeActive`, `sceneDidBecomeActive`), consume unhandled pending requests newer than 10 minutes and start playback idempotently.
4. **Audio Engine**:
   - Resolve asset path using `FileManager` checking `Frameworks/App.framework/flutter_assets/...` as well as bundle lookups.
   - Set `AVAudioSession` category `.playback`, mode `.spokenAudio`. If `setActive(true)` fails, retry once after 300 ms.
   - Listen to `AVAudioSession.interruptionNotification` and route change notifications (pause on headphone disconnect).
5. **Flutter Bridge**:
   - Add `consumeAlarmLaunch` MethodChannel handler on `"app/alarm"` returning `{launchedFromAlarm, trackId, isPlaying, positionMs, durationMs}`.
   - In Flutter, call `consumeAlarmLaunch` on startup and on `AppLifecycleState.resumed`, navigating once to `SynchronizedTranscriptPage`.
   - Poll `positionMs` only while visible via binary search; provide a retry "Tap to play" button if playback was interrupted.
6. **Logging**:
   - Implement `AlarmFlowLogger` recording structured messages to `os.Logger(subsystem: bundleId, category: "AlarmFlow")` and `UserDefaults` (`"alarmflow.debugLog"`, last 50 entries).
