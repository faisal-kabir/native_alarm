import Foundation
import AVFoundation
import Flutter
import os

// ---------------------------------------------------------------------------
// AlarmFlowLogger  –  os.Logger & UserDefaults debug logging
// ---------------------------------------------------------------------------

final class AlarmFlowLogger {
    static let shared = AlarmFlowLogger()
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.example.nativeAlerm", category: "AlarmFlow")
    private let userDefaultsKey = "alarmflow.debugLog"
    private let lock = NSLock()

    private init() {}

    func log(_ message: String) {
        logger.info("\(message, privacy: .public)")

        lock.lock()
        defer { lock.unlock() }

        let timestamp = ISO8601DateFormatter().string(from: Date())
        let entry = "[\(timestamp)] \(message)"

        var logs = UserDefaults.standard.stringArray(forKey: userDefaultsKey) ?? []
        logs.append(entry)
        if logs.count > 50 {
            logs = Array(logs.suffix(50))
        }
        UserDefaults.standard.set(logs, forKey: userDefaultsKey)
    }

    func getLogs() -> [String] {
        lock.lock()
        defer { lock.unlock() }
        return UserDefaults.standard.stringArray(forKey: userDefaultsKey) ?? []
    }

    func clear() {
        lock.lock()
        defer { lock.unlock() }
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
    }
}

// ---------------------------------------------------------------------------
// PendingPlaybackManager  –  Persistent pending playback request
// ---------------------------------------------------------------------------

final class PendingPlaybackManager {
    static let shared = PendingPlaybackManager()
    private let userDefaultsKey = "alarmflow.pendingRequest"
    private let lock = NSLock()

    private init() {}

    func recordRequest(alarmId: String, trackId: String, assetPath: String = "assets/audio/demo_alarm_message.mp3") {
        lock.lock()
        defer { lock.unlock() }

        let dict: [String: Any] = [
            "trackId": trackId,
            "assetPath": assetPath,
            "alarmId": alarmId,
            "requestedAt": Date().timeIntervalSince1970,
            "consumed": false
        ]
        UserDefaults.standard.set(dict, forKey: userDefaultsKey)
        AlarmFlowLogger.shared.log("PendingPlaybackManager: Recorded request for alarmId=\(alarmId), trackId=\(trackId)")
    }

    func consumePendingRequestIfValid(maxAgeSeconds: TimeInterval = 600) -> (alarmId: String, trackId: String)? {
        lock.lock()
        defer { lock.unlock() }

        guard var dict = UserDefaults.standard.dictionary(forKey: userDefaultsKey) else {
            return nil
        }

        let consumed = dict["consumed"] as? Bool ?? false
        if consumed {
            return nil
        }

        let requestedAt = dict["requestedAt"] as? TimeInterval ?? 0
        let age = Date().timeIntervalSince1970 - requestedAt

        if age > maxAgeSeconds {
            AlarmFlowLogger.shared.log("PendingPlaybackManager: Request expired (age: \(Int(age))s > \(Int(maxAgeSeconds))s)")
            dict["consumed"] = true
            UserDefaults.standard.set(dict, forKey: userDefaultsKey)
            return nil
        }

        dict["consumed"] = true
        UserDefaults.standard.set(dict, forKey: userDefaultsKey)

        let alarmId = dict["alarmId"] as? String ?? ""
        let trackId = dict["trackId"] as? String ?? "demo_alarm_message"
        AlarmFlowLogger.shared.log("PendingPlaybackManager: Consumed request for alarmId=\(alarmId), trackId=\(trackId) (age: \(Int(age))s)")
        return (alarmId, trackId)
    }

    func peekRequest() -> [String: Any]? {
        lock.lock()
        defer { lock.unlock() }
        return UserDefaults.standard.dictionary(forKey: userDefaultsKey)
    }

    func clear() {
        lock.lock()
        defer { lock.unlock() }
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
    }
}

// ---------------------------------------------------------------------------
// AudioPlaybackManager  –  Singleton that owns custom audio playback.
// ---------------------------------------------------------------------------

final class AudioPlaybackManager: NSObject {

    static let shared = AudioPlaybackManager()

    var onPositionUpdate:    ((_ positionMs: Int, _ durationMs: Int, _ trackId: String) -> Void)?
    var onPlaybackStarted:   ((_ trackId: String, _ durationMs: Int) -> Void)?
    var onPlaybackPaused:    ((_ positionMs: Int, _ trackId: String) -> Void)?
    var onPlaybackResumed:   ((_ positionMs: Int, _ trackId: String) -> Void)?
    var onPlaybackCompleted: ((_ trackId: String) -> Void)?
    var onPlaybackStopped:   (() -> Void)?
    var onError:             ((_ message: String) -> Void)?

    private(set) var currentTrackId: String?
    private var player: AVAudioPlayer?
    private var ticker: Timer?

    var positionMs: Int { Int((player?.currentTime ?? 0) * 1000) }
    var durationMs: Int { Int((player?.duration  ?? 0) * 1000) }
    var isPlaying:  Bool { player?.isPlaying ?? false }

    private override init() {
        super.init()
        setupAudioNotifications()
    }

    // MARK: – Asset Resolution

    func resolveAssetPath(for trackId: String) throws -> String {
        let bundlePath = Bundle.main.bundlePath
        AlarmFlowLogger.shared.log("AudioPlaybackManager: Resolving asset for trackId='\(trackId)', main bundlePath='\(bundlePath)'")

        let candidateNames: [String] = [
            trackId.hasSuffix(".mp3") ? trackId : "\(trackId).mp3",
            trackId,
            "demo_alarm_message.mp3"
        ]

        let fileManager = FileManager.default

        for name in candidateNames {
            let assetKey = "assets/audio/\(name)"

            // 1. FlutterDartProject lookupKey
            if let lookupKey = FlutterDartProject.lookupKey(forAsset: assetKey) as String? {
                if let path = Bundle.main.path(forResource: lookupKey, ofType: nil),
                   fileManager.fileExists(atPath: path) {
                    AlarmFlowLogger.shared.log("AudioPlaybackManager: Resolved via FlutterDartProject.lookupKey -> \(path)")
                    return path
                }
            }

            // 2. Direct path: Frameworks/App.framework/flutter_assets/<assetPath>
            let appFrameworkPath = (bundlePath as NSString)
                .appendingPathComponent("Frameworks/App.framework/flutter_assets/\(assetKey)")
            if fileManager.fileExists(atPath: appFrameworkPath) {
                AlarmFlowLogger.shared.log("AudioPlaybackManager: Resolved via Frameworks/App.framework direct path -> \(appFrameworkPath)")
                return appFrameworkPath
            }

            // 3. Direct path in root flutter_assets/
            let flutterAssetsPath = (bundlePath as NSString)
                .appendingPathComponent("flutter_assets/\(assetKey)")
            if fileManager.fileExists(atPath: flutterAssetsPath) {
                AlarmFlowLogger.shared.log("AudioPlaybackManager: Resolved via flutter_assets direct path -> \(flutterAssetsPath)")
                return flutterAssetsPath
            }

            // 4. Bundle resource by name
            let baseName = (name as NSString).deletingPathExtension
            let ext = (name as NSString).pathExtension.isEmpty ? "mp3" : (name as NSString).pathExtension
            if let directResource = Bundle.main.path(forResource: baseName, ofType: ext),
               fileManager.fileExists(atPath: directResource) {
                AlarmFlowLogger.shared.log("AudioPlaybackManager: Resolved via Bundle.main.path(forResource) -> \(directResource)")
                return directResource
            }
        }

        let errMsg = "Audio asset could not be found in bundle. Tried candidate names: \(candidateNames) in \(bundlePath)"
        AlarmFlowLogger.shared.log("AudioPlaybackManager ERROR: \(errMsg)")
        throw NSError(domain: "AudioPlaybackManager", code: 404, userInfo: [NSLocalizedDescriptionKey: errMsg])
    }

    // MARK: – Audio Session

    func configureAndActivateSession(isRetry: Bool = false) throws {
        let session = AVAudioSession.sharedInstance()
        AlarmFlowLogger.shared.log("AudioPlaybackManager: Configuring AVAudioSession (.playback, mode: .spokenAudio)")
        try session.setCategory(.playback, mode: .spokenAudio, options: [])

        do {
            AlarmFlowLogger.shared.log("AudioPlaybackManager: Activating AVAudioSession (isRetry=\(isRetry))...")
            try session.setActive(true)
            AlarmFlowLogger.shared.log("AudioPlaybackManager: AVAudioSession activated successfully.")
        } catch let error as NSError {
            AlarmFlowLogger.shared.log("AudioPlaybackManager: AVAudioSession setActive failed (code \(error.code)): \(error.localizedDescription)")
            throw error
        }
    }

    // MARK: – Start (Idempotent)

    func start(audioTrackId: String) {
        AlarmFlowLogger.shared.log("AudioPlaybackManager.start() called for audioTrackId='\(audioTrackId)'")

        // Idempotent: Never restart the same track if already playing
        if currentTrackId == audioTrackId, let p = player, p.isPlaying {
            AlarmFlowLogger.shared.log("AudioPlaybackManager: Track '\(audioTrackId)' is already playing. No-op (idempotent).")
            return
        }

        stop()
        currentTrackId = audioTrackId

        let resolvedPath: String
        do {
            resolvedPath = try resolveAssetPath(for: audioTrackId)
        } catch {
            onError?(error.localizedDescription)
            return
        }

        performStart(resolvedPath: resolvedPath, audioTrackId: audioTrackId, isRetry: false)
    }

    private func performStart(resolvedPath: String, audioTrackId: String, isRetry: Bool) {
        do {
            try configureAndActivateSession(isRetry: isRetry)

            AlarmFlowLogger.shared.log("AudioPlaybackManager: Creating AVAudioPlayer for \(resolvedPath)...")
            let newPlayer = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: resolvedPath))
            newPlayer.delegate = self
            newPlayer.prepareToPlay()

            let didPlay = newPlayer.play()
            AlarmFlowLogger.shared.log("AudioPlaybackManager: newPlayer.play() returned \(didPlay)")

            if didPlay {
                self.player = newPlayer
                self.onPlaybackStarted?(audioTrackId, durationMs)
                self.startTicker()
            } else {
                let err = "AVAudioPlayer.play() returned false"
                AlarmFlowLogger.shared.log("AudioPlaybackManager ERROR: \(err)")
                onError?(err)
            }
        } catch let error as NSError {
            if !isRetry {
                AlarmFlowLogger.shared.log("AudioPlaybackManager: Session activation failed with code \(error.code). Scheduling retry in 300ms...")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                    guard let self = self, self.currentTrackId == audioTrackId else { return }
                    self.performStart(resolvedPath: resolvedPath, audioTrackId: audioTrackId, isRetry: true)
                }
            } else {
                AlarmFlowLogger.shared.log("AudioPlaybackManager: Retry also failed: \(error.localizedDescription)")
                onError?(error.localizedDescription)
            }
        }
    }

    // MARK: – Controls

    func pause() {
        guard let p = player, p.isPlaying else { return }
        p.pause()
        stopTicker()
        AlarmFlowLogger.shared.log("AudioPlaybackManager: Paused at position \(positionMs)ms")
        onPlaybackPaused?(positionMs, currentTrackId ?? "")
    }

    func resume() {
        guard let p = player, !p.isPlaying else { return }
        do {
            try configureAndActivateSession()
            let didPlay = p.play()
            AlarmFlowLogger.shared.log("AudioPlaybackManager.resume() play() returned \(didPlay)")
            if didPlay {
                startTicker()
                onPlaybackResumed?(positionMs, currentTrackId ?? "")
            }
        } catch {
            AlarmFlowLogger.shared.log("AudioPlaybackManager.resume() session error: \(error)")
        }
    }

    func seek(positionMs ms: Int) {
        player?.currentTime = Double(ms) / 1000.0
        AlarmFlowLogger.shared.log("AudioPlaybackManager: Seek to \(ms)ms")
    }

    func stop() {
        stopTicker()
        player?.stop()
        player = nil
        let had = currentTrackId != nil
        currentTrackId = nil
        if had {
            AlarmFlowLogger.shared.log("AudioPlaybackManager: Stopped playback.")
            onPlaybackStopped?()
        }
    }

    // MARK: – Notifications & Ticker

    private func setupAudioNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAudioInterruption(_:)),
            name: AVAudioSession.interruptionNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRouteChange(_:)),
            name: AVAudioSession.routeChangeNotification,
            object: nil
        )
    }

    @objc private func handleAudioInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        if type == .began {
            AlarmFlowLogger.shared.log("AudioPlaybackManager: Audio interruption began. Pausing.")
            pause()
        } else if type == .ended {
            AlarmFlowLogger.shared.log("AudioPlaybackManager: Audio interruption ended.")
            if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume) {
                    AlarmFlowLogger.shared.log("AudioPlaybackManager: Interruption options contain .shouldResume -> resuming.")
                    resume()
                }
            }
        }
    }

    @objc private func handleRouteChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
            return
        }
        if reason == .oldDeviceUnavailable {
            AlarmFlowLogger.shared.log("AudioPlaybackManager: Audio route change (oldDeviceUnavailable / headphones unplugged). Pausing.")
            pause()
        }
    }

    private func startTicker() {
        stopTicker()
        ticker = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, self.isPlaying else { return }
            self.onPositionUpdate?(self.positionMs, self.durationMs, self.currentTrackId ?? "")
        }
    }

    private func stopTicker() {
        ticker?.invalidate()
        ticker = nil
    }
}

extension AudioPlaybackManager: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        AlarmFlowLogger.shared.log("AudioPlaybackManager: audioPlayerDidFinishPlaying successfully=\(flag)")
        stopTicker()
        let trackId = currentTrackId ?? ""
        currentTrackId = nil
        onPlaybackCompleted?(trackId)
    }
}
