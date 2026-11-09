import Flutter
import UIKit
import AVFoundation
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {

    static var launchedFromAlarm: Bool = false
    /// Identity of the alarm that opened the app; handed to Flutter once by consumeAlarmLaunch.
    static var launchAlarmId: String = ""

    private var eventSink: FlutterEventSink?
    private var currentAlarmId: String = ""

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        AlarmFlowLogger.shared.log("AppDelegate: application didFinishLaunchingWithOptions")

        // Set notification center delegate
        UNUserNotificationCenter.current().delegate = self

        // Register custom action category (e.g. "Stop" button that opens app and plays audio)
        AlarmScheduler.shared.registerNotificationCategory()

        // Hook up AudioPlaybackManager callbacks to send events to Flutter
        setupAudioCallbacks()

        // Start observing AlarmKit alarmUpdates for logging state transitions
        AlarmScheduler.shared.startObservingAlarmUpdates()

        // Check for pending playback request recorded by Stop intent
        checkAndHandlePendingPlayback()

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    override func applicationDidBecomeActive(_ application: UIApplication) {
        super.applicationDidBecomeActive(application)
        AlarmFlowLogger.shared.log("AppDelegate: applicationDidBecomeActive")
        checkAndHandlePendingPlayback()
    }

    func checkAndHandlePendingPlayback() {
        if let (alarmId, trackId) = PendingPlaybackManager.shared.consumePendingRequestIfValid() {
            AlarmFlowLogger.shared.log("AppDelegate: Handling valid pending request for alarmId=\(alarmId), trackId=\(trackId)")
            AppDelegate.launchedFromAlarm = true
            AppDelegate.launchAlarmId = alarmId
            self.currentAlarmId = alarmId
            BackupAlarmManager.shared.cancelBackupAlarms(for: alarmId)
            AudioPlaybackManager.shared.start(audioTrackId: trackId)
            sendEvent([
                "event": "customAudioStarted",
                "audioTrackId": trackId,
                "alarmId": alarmId,
                "durationMs": AudioPlaybackManager.shared.durationMs
            ])
        }
    }

    func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
        GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
        if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "NativeAlarmPlugin") {
            setupChannels(binaryMessenger: registrar.messenger())
        }
    }

    // MARK: – Audio Callbacks

    private func setupAudioCallbacks() {
        AudioPlaybackManager.shared.onPositionUpdate = { [weak self] pos, dur, track in
            self?.sendEvent([
                "event": "positionUpdate",
                "positionMs": pos,
                "durationMs": dur,
                "audioTrackId": track
            ])
        }

        AudioPlaybackManager.shared.onPlaybackStarted = { [weak self] track, dur in
            self?.sendEvent([
                "event": "customAudioStarted",
                "audioTrackId": track,
                "durationMs": dur
            ])
        }

        AudioPlaybackManager.shared.onPlaybackPaused = { [weak self] pos, track in
            self?.sendEvent([
                "event": "customAudioPaused",
                "positionMs": pos,
                "audioTrackId": track
            ])
        }

        AudioPlaybackManager.shared.onPlaybackResumed = { [weak self] pos, track in
            self?.sendEvent([
                "event": "customAudioResumed",
                "positionMs": pos,
                "audioTrackId": track
            ])
        }

        AudioPlaybackManager.shared.onPlaybackCompleted = { [weak self] track in
            self?.sendEvent([
                "event": "customAudioCompleted",
                "audioTrackId": track
            ])
        }

        AudioPlaybackManager.shared.onPlaybackStopped = { [weak self] in
            self?.sendEvent([
                "event": "customAudioStopped"
            ])
        }

        AudioPlaybackManager.shared.onError = { [weak self] msg in
            self?.sendEvent([
                "event": "error",
                "message": msg
            ])
        }
    }

    // MARK: – Method & Event Channels

    private func setupChannels(binaryMessenger: FlutterBinaryMessenger) {
        let appAlarmChannel = FlutterMethodChannel(name: "app/alarm", binaryMessenger: binaryMessenger)
        let ealaChannel = FlutterMethodChannel(name: "com.eala.app/alarm", binaryMessenger: binaryMessenger)
        let legacyChannel = FlutterMethodChannel(name: "com.native_alarm/alarm", binaryMessenger: binaryMessenger)

        let appAlarmEventChannel = FlutterEventChannel(name: "app/alarm_events", binaryMessenger: binaryMessenger)
        let ealaEventChannel = FlutterEventChannel(name: "com.eala.app/alarm_events", binaryMessenger: binaryMessenger)
        let legacyEventChannel = FlutterEventChannel(name: "com.native_alarm/alarm_events", binaryMessenger: binaryMessenger)

        appAlarmEventChannel.setStreamHandler(self)
        ealaEventChannel.setStreamHandler(self)
        legacyEventChannel.setStreamHandler(self)

        let handler: FlutterMethodCallHandler = { [weak self] (call, result) in
            guard let self = self else { return }
            self.handleMethodCall(call: call, result: result)
        }

        appAlarmChannel.setMethodCallHandler(handler)
        ealaChannel.setMethodCallHandler(handler)
        legacyChannel.setMethodCallHandler(handler)
    }

    private func handleMethodCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
        // getPlaybackState is polled every 120ms by the message page; logging it would
        // push every useful entry out of the debug log.
        if call.method != "getPlaybackState" {
            AlarmFlowLogger.shared.log("AppDelegate: MethodChannel call '\(call.method)'")
        }

        switch call.method {
        case "consumeAlarmLaunch":
            let launched = AppDelegate.launchedFromAlarm
            let launchAlarmId = AppDelegate.launchAlarmId
            // One-shot: a later cold start must never replay this launch.
            AppDelegate.launchedFromAlarm = false
            AppDelegate.launchAlarmId = ""
            PendingPlaybackManager.shared.clear()
            let trackId = AudioPlaybackManager.shared.currentTrackId ?? "demo_alarm_message"
            if !launchAlarmId.isEmpty {
                self.currentAlarmId = launchAlarmId
                BackupAlarmManager.shared.cancelBackupAlarms(for: launchAlarmId)
            }
            AlarmFlowLogger.shared.log("AppDelegate: consumeAlarmLaunch returning launchedFromAlarm=\(launched), alarmId=\(launchAlarmId), trackId=\(trackId)")
            result([
                "launchedFromAlarm": launched,
                "alarmId": launchAlarmId,
                "trackId": trackId,
                "isPlaying": AudioPlaybackManager.shared.isPlaying,
                "positionMs": AudioPlaybackManager.shared.positionMs,
                "durationMs": AudioPlaybackManager.shared.durationMs
            ])

        case "getDebugLogs":
            result(AlarmFlowLogger.shared.getLogs())

        case "scheduleAlarm":
            if let args = call.arguments as? [String: Any],
               let alarmId = args["alarmId"] as? String {
                let timeMs = (args["timeMs"] as? NSNumber)?.int64Value ?? Int64(Date().timeIntervalSince1970 * 1000 + 5000)
                let missionName = (args["missionName"] as? String).flatMap { $0.isEmpty ? nil : $0 } ?? "Start Morning Mission"
                let config = AlarmConfig(
                    alarmId: alarmId,
                    audioTrackId: args["audioTrackId"] as? String ?? "morning_message",
                    missionName: missionName,
                    repeatCount: (args["repeatCount"] as? NSNumber)?.intValue ?? 0,
                    repeatIntervalSec: (args["repeatIntervalSec"] as? NSNumber)?.intValue ?? 10,
                    tuneName: AlarmTuneStore.install(filePath: args["tuneFile"] as? String, alarmId: alarmId)
                        ?? installTune(assetPath: args["tuneAsset"] as? String),
                    title: (args["title"] as? String).flatMap { $0.isEmpty ? nil : $0 },
                    ringDays: AlarmConfig.parseRingDays(args["ringDays"])
                )
                self.currentAlarmId = alarmId
                AlarmScheduler.shared.schedule(config: config, timeMs: timeMs)
                self.sendEvent([
                    "event": "alarmScheduled",
                    "alarmId": alarmId,
                    "timeMs": timeMs
                ])
                result(nil)
            } else {
                result(FlutterError(code: "INVALID_ARGS", message: "Missing arguments", details: nil))
            }

        case "cancelAlarm":
            if let args = call.arguments as? [String: Any],
               let alarmId = args["alarmId"] as? String {
                AlarmScheduler.shared.cancel(alarmId: alarmId)
                self.sendEvent(["event": "alarmCancelled", "alarmId": alarmId])
                result(nil)
            } else {
                result(nil)
            }

        case "dismissAlarm":
            AudioPlaybackManager.shared.stop()
            if !self.currentAlarmId.isEmpty {
                AlarmScheduler.shared.finish(alarmId: self.currentAlarmId)
            }
            self.sendEvent(["event": "alarmDismissed", "alarmId": self.currentAlarmId])
            result(nil)

        case "stopAlarm":
            let args = call.arguments as? [String: Any]
            let audioTrackId = (args?["audioTrackId"] as? String) ?? "morning_message"
            AudioPlaybackManager.shared.start(audioTrackId: audioTrackId)
            result(nil)

        case "startCustomAudio":
            let args = call.arguments as? [String: Any]
            let audioTrackId = (args?["audioId"] as? String) ?? (args?["audioTrackId"] as? String) ?? "morning_message"
            AudioPlaybackManager.shared.start(audioTrackId: audioTrackId)
            result(nil)

        case "pause", "pauseCustomAudio":
            AudioPlaybackManager.shared.pause()
            result(nil)

        case "resume", "resumeCustomAudio":
            AudioPlaybackManager.shared.resume()
            result(nil)

        case "seek", "seekCustomAudio":
            if let args = call.arguments as? [String: Any],
               let positionMs = (args["positionMs"] as? NSNumber)?.intValue ?? (args["position"] as? NSNumber)?.intValue {
                AudioPlaybackManager.shared.seek(positionMs: positionMs)
            }
            result(nil)

        case "stop", "stopCustomAudio":
            AudioPlaybackManager.shared.stop()
            result(nil)

        case "getPlaybackState":
            result(self.getPlaybackState())

        case "requestNotificationPermission":
            AlarmScheduler.shared.requestPermission { granted in
                result(granted)
            }

        case "hasNotificationPermission":
            AlarmScheduler.shared.hasPermission { granted in
                result(granted)
            }

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    /// Copies a Flutter asset into Library/Sounds so AlarmKit / notifications can play it by name.
    private func installTune(assetPath: String?) -> String? {
        guard let assetPath = assetPath, !assetPath.isEmpty else { return nil }
        let key = FlutterDartProject.lookupKey(forAsset: assetPath)
        guard let source = Bundle.main.path(forResource: key, ofType: nil) else {
            AlarmFlowLogger.shared.log("AppDelegate: tune asset not found: \(assetPath)")
            return nil
        }
        let name = (assetPath as NSString).lastPathComponent
        let fm = FileManager.default
        guard let library = fm.urls(for: .libraryDirectory, in: .userDomainMask).first else { return nil }
        let soundsDir = library.appendingPathComponent("Sounds", isDirectory: true)
        let target = soundsDir.appendingPathComponent(name)
        do {
            try fm.createDirectory(at: soundsDir, withIntermediateDirectories: true)
            if fm.fileExists(atPath: target.path) { try fm.removeItem(at: target) }
            try fm.copyItem(atPath: source, toPath: target.path)
            return name
        } catch {
            AlarmFlowLogger.shared.log("AppDelegate: tune install failed: \(error)")
            return nil
        }
    }

    private func getPlaybackState() -> [String: Any] {
        let isPlaying = AudioPlaybackManager.shared.isPlaying
        let trackId = AudioPlaybackManager.shared.currentTrackId

        let state: String
        if isPlaying {
            state = "customAudioPlaying"
        } else if trackId != nil {
            state = "customAudioPaused"
        } else {
            state = "idle"
        }

        return [
            "state": state,
            "positionMs": AudioPlaybackManager.shared.positionMs,
            "durationMs": AudioPlaybackManager.shared.durationMs,
            "audioTrackId": trackId ?? "",
            "alarmId": currentAlarmId
        ]
    }

    private func sendEvent(_ event: [String: Any]) {
        DispatchQueue.main.async { [weak self] in
            self?.eventSink?(event)
        }
    }

    // MARK: – UNUserNotificationCenterDelegate

    // Present notification even when app is in the foreground
    override func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Only our alarm notifications are handled here. Everything else (push messages
        // from Firebase, local notifications from Flutter) goes to the Flutter plugins.
        guard isAlarmNotification(notification) else {
            super.userNotificationCenter(center, willPresent: notification, withCompletionHandler: completionHandler)
            return
        }
        if #available(iOS 14.0, *) {
            completionHandler([.banner, .sound, .badge, .list])
        } else {
            completionHandler([.alert, .sound, .badge])
        }
    }

    // Handle user tapping the notification banner or the "Stop" action
    override func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        guard isAlarmNotification(response.notification) else {
            super.userNotificationCenter(center, didReceive: response, withCompletionHandler: completionHandler)
            return
        }
        handleNotificationResponse(response)
        completionHandler()
    }

    /// Alarm notifications always carry the alarm's id in their userInfo.
    private func isAlarmNotification(_ notification: UNNotification) -> Bool {
        let alarmId = notification.request.content.userInfo["alarmId"] as? String
        return !(alarmId ?? "").isEmpty
    }

    private func handleNotificationResponse(_ response: UNNotificationResponse) {
        let userInfo = response.notification.request.content.userInfo
        let audioTrackId = (userInfo["audioTrackId"] as? String) ?? "morning_message"
        let alarmId = (userInfo["alarmId"] as? String) ?? ""
        self.currentAlarmId = alarmId

        AlarmFlowLogger.shared.log("AppDelegate: Received notification response for alarmId=\(alarmId), trackId=\(audioTrackId)")

        AppDelegate.launchedFromAlarm = true
        AppDelegate.launchAlarmId = alarmId
        BackupAlarmManager.shared.cancelBackupAlarms(for: alarmId)
        AudioPlaybackManager.shared.start(audioTrackId: audioTrackId)

        sendEvent([
            "event": "customAudioStarted",
            "audioTrackId": audioTrackId,
            "alarmId": alarmId,
            "durationMs": AudioPlaybackManager.shared.durationMs
        ])
    }
}

// MARK: – FlutterStreamHandler
extension AppDelegate: FlutterStreamHandler {
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        return nil
    }
}
