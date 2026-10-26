import Flutter
import UIKit
import AVFoundation
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate, AVAudioPlayerDelegate {
    private var eventSink: FlutterEventSink?
    private var audioPlayer: AVAudioPlayer?
    private var ringtonePlayer: AVAudioPlayer?
    private var tickerTimer: Timer?
    private var currentAudioTrackId: String = "morning_message"
    private var currentAlarmId: String = ""

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        setupAudioSession()
        requestNotificationPermission()
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
        GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
        if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "NativeAlarmPlugin") {
            setupChannels(binaryMessenger: registrar.messenger())
        }
    }

    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set AVAudioSession category: \(error)")
        }
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            print("Notification permission granted: \(granted)")
        }
    }

    private func setupChannels(binaryMessenger: FlutterBinaryMessenger) {
        let methodChannel = FlutterMethodChannel(name: "com.native_alarm/alarm", binaryMessenger: binaryMessenger)
        let eventChannel = FlutterEventChannel(name: "com.native_alarm/alarm_events", binaryMessenger: binaryMessenger)

        eventChannel.setStreamHandler(self)

        methodChannel.setMethodCallHandler { [weak self] (call, result) in
            guard let self = self else { return }
            switch call.method {
            case "scheduleAlarm":
                if let args = call.arguments as? [String: Any],
                   let alarmId = args["alarmId"] as? String {
                    let timeMs = (args["timeMs"] as? NSNumber)?.int64Value ?? Int64(Date().timeIntervalSince1970 * 1000 + 5000)
                    let audioTrackId = args["audioTrackId"] as? String ?? "morning_message"
                    self.scheduleAlarm(alarmId: alarmId, timeMs: timeMs, audioTrackId: audioTrackId)
                    result(nil)
                } else {
                    result(FlutterError(code: "INVALID_ARGS", message: "Missing arguments", details: nil))
                }
            case "cancelAlarm":
                if let args = call.arguments as? [String: Any],
                   let alarmId = args["alarmId"] as? String {
                    self.cancelAlarm(alarmId: alarmId)
                    result(nil)
                } else {
                    result(nil)
                }
            case "dismissAlarm":
                self.stopRingtone()
                self.stopCustomAudio()
                self.sendEvent(["event": "alarmDismissed", "alarmId": self.currentAlarmId])
                result(nil)
            case "stopAlarm":
                let args = call.arguments as? [String: Any]
                let audioTrackId = args?["audioTrackId"] as? String ?? self.currentAudioTrackId
                self.stopAlarmAndPlayAudio(audioTrackId: audioTrackId)
                result(nil)
            case "startCustomAudio":
                let args = call.arguments as? [String: Any]
                let audioTrackId = (args?["audioId"] as? String) ?? (args?["audioTrackId"] as? String) ?? "morning_message"
                self.startCustomAudio(audioTrackId: audioTrackId)
                result(nil)
            case "pauseCustomAudio":
                self.pauseCustomAudio()
                result(nil)
            case "resumeCustomAudio":
                self.resumeCustomAudio()
                result(nil)
            case "seekCustomAudio":
                if let args = call.arguments as? [String: Any],
                   let positionMs = (args["positionMs"] as? NSNumber)?.intValue {
                    self.seekCustomAudio(positionMs: positionMs)
                }
                result(nil)
            case "stopCustomAudio":
                self.stopCustomAudio()
                result(nil)
            case "getPlaybackState":
                result(self.getPlaybackState())
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }

    private func scheduleAlarm(alarmId: String, timeMs: Int64, audioTrackId: String) {
        currentAlarmId = alarmId
        currentAudioTrackId = audioTrackId
        let triggerDate = Date(timeIntervalSince1970: Double(timeMs) / 1000.0)
        let delay = max(1.0, triggerDate.timeIntervalSinceNow)

        // Schedule local notification
        let content = UNMutableNotificationContent()
        content.title = "Alarm Ringing"
        content.body = "Tap to stop alarm and listen to message."
        content.sound = UNNotificationSound.default
        content.userInfo = ["alarmId": alarmId, "audioTrackId": audioTrackId]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
        let request = UNNotificationRequest(identifier: alarmId, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)

        // Also schedule timer to trigger audio playback or ringtone in app
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.triggerAlarm(alarmId: alarmId, audioTrackId: audioTrackId)
        }

        sendEvent([
            "event": "alarmScheduled",
            "alarmId": alarmId,
            "timeMs": timeMs
        ])
    }

    private func cancelAlarm(alarmId: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [alarmId])
        sendEvent(["event": "alarmCancelled", "alarmId": alarmId])
    }

    private func triggerAlarm(alarmId: String, audioTrackId: String) {
        sendEvent([
            "event": "alarmRinging",
            "alarmId": alarmId,
            "audioTrackId": audioTrackId
        ])
    }

    private func stopAlarmAndPlayAudio(audioTrackId: String) {
        stopRingtone()
        startCustomAudio(audioTrackId: audioTrackId)
    }

    private func stopRingtone() {
        ringtonePlayer?.stop()
        ringtonePlayer = nil
    }

    private func startCustomAudio(audioTrackId: String) {
        currentAudioTrackId = audioTrackId
        stopCustomAudio()

        // Lookup asset path
        let key = FlutterDartProject.lookupKey(forAsset: "assets/audio/demo_alarm_message.mp3")
        guard let path = Bundle.main.path(forResource: key, ofType: nil) ??
                        Bundle.main.path(forResource: "assets/audio/demo_alarm_message.mp3", ofType: nil) else {
            sendEvent(["event": "error", "message": "Audio asset not found"])
            return
        }

        do {
            setupAudioSession()
            audioPlayer = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: path))
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()

            let durationMs = Int((audioPlayer?.duration ?? 0) * 1000)
            sendEvent([
                "event": "customAudioStarted",
                "audioTrackId": audioTrackId,
                "durationMs": durationMs
            ])

            startTicker()
        } catch {
            sendEvent(["event": "error", "message": error.localizedDescription])
        }
    }

    private func startTicker() {
        stopTicker()
        tickerTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let player = self.audioPlayer, player.isPlaying else { return }
            let posMs = Int(player.currentTime * 1000)
            let durMs = Int(player.duration * 1000)
            self.sendEvent([
                "event": "positionUpdate",
                "positionMs": posMs,
                "durationMs": durMs,
                "audioTrackId": self.currentAudioTrackId
            ])
        }
    }

    private func stopTicker() {
        tickerTimer?.invalidate()
        tickerTimer = nil
    }

    private func pauseCustomAudio() {
        if let player = audioPlayer, player.isPlaying {
            player.pause()
            stopTicker()
            let posMs = Int(player.currentTime * 1000)
            sendEvent([
                "event": "customAudioPaused",
                "positionMs": posMs,
                "audioTrackId": currentAudioTrackId
            ])
        }
    }

    private func resumeCustomAudio() {
        if let player = audioPlayer, !player.isPlaying {
            player.play()
            startTicker()
            let posMs = Int(player.currentTime * 1000)
            sendEvent([
                "event": "customAudioResumed",
                "positionMs": posMs,
                "audioTrackId": currentAudioTrackId
            ])
        }
    }

    private func seekCustomAudio(positionMs: Int) {
        if let player = audioPlayer {
            player.currentTime = Double(positionMs) / 1000.0
            sendEvent([
                "event": "positionUpdate",
                "positionMs": positionMs,
                "durationMs": Int(player.duration * 1000),
                "audioTrackId": currentAudioTrackId
            ])
        }
    }

    private func stopCustomAudio() {
        stopTicker()
        audioPlayer?.stop()
        audioPlayer = nil
        sendEvent(["event": "customAudioStopped"])
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        stopTicker()
        sendEvent([
            "event": "customAudioCompleted",
            "audioTrackId": currentAudioTrackId
        ])
    }

    private func getPlaybackState() -> [String: Any] {
        let isPlaying = audioPlayer?.isPlaying ?? false
        let isRinging = ringtonePlayer?.isPlaying ?? false
        let state: String
        if isRinging {
            state = "ringing"
        } else if isPlaying {
            state = "customAudioPlaying"
        } else if audioPlayer != nil {
            state = "customAudioPaused"
        } else {
            state = "idle"
        }

        return [
            "state": state,
            "positionMs": Int((audioPlayer?.currentTime ?? 0) * 1000),
            "durationMs": Int((audioPlayer?.duration ?? 0) * 1000),
            "audioTrackId": currentAudioTrackId,
            "alarmId": currentAlarmId
        ]
    }

    private func sendEvent(_ event: [String: Any]) {
        DispatchQueue.main.async { [weak self] in
            self?.eventSink?(event)
        }
    }
}

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
