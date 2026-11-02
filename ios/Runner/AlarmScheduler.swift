import Foundation
import UserNotifications
import ActivityKit
import AppIntents
import CryptoKit

#if canImport(AlarmKit)
import AlarmKit
import SwiftUI

// ---------------------------------------------------------------------------
// AlarmKit AppIntents (iOS 26+)
// ---------------------------------------------------------------------------

@available(iOS 26.0, *)
public struct StopAndPlayIntent: LiveActivityIntent {
    public static var title: LocalizedStringResource = "Stop & Play"
    public static var openAppWhenRun: Bool = true

    @Parameter(title: "Alarm ID")
    public var alarmId: String

    @Parameter(title: "Audio Track ID")
    public var audioTrackId: String

    public init() {
        self.alarmId = ""
        self.audioTrackId = "morning_message"
    }

    public init(alarmId: String, audioTrackId: String) {
        self.alarmId = alarmId
        self.audioTrackId = audioTrackId
    }

    public func perform() async throws -> some IntentResult {
        AlarmFlowLogger.shared.log("StopAndPlayIntent.perform() entered for alarmId=\(alarmId), trackId=\(audioTrackId), bundle=\(Bundle.main.bundlePath)")
        await AlarmUnlockCoordinator.handleUnlocked(alarmId: alarmId, audioTrackId: audioTrackId, source: "StopAndPlayIntent")
        return .result()
    }
}

@available(iOS 26.0, *)
public struct OpenAndPlayIntent: LiveActivityIntent {
    public static var title: LocalizedStringResource = "Open & Play"
    public static var openAppWhenRun: Bool = true

    @Parameter(title: "Alarm ID")
    public var alarmId: String

    @Parameter(title: "Audio Track ID")
    public var audioTrackId: String

    public init() {
        self.alarmId = ""
        self.audioTrackId = "morning_message"
    }

    public init(alarmId: String, audioTrackId: String) {
        self.alarmId = alarmId
        self.audioTrackId = audioTrackId
    }

    public func perform() async throws -> some IntentResult {
        AlarmFlowLogger.shared.log("OpenAndPlayIntent.perform() entered for alarmId=\(alarmId), trackId=\(audioTrackId), bundle=\(Bundle.main.bundlePath)")
        await AlarmUnlockCoordinator.handleUnlocked(alarmId: alarmId, audioTrackId: audioTrackId, source: "OpenAndPlayIntent")
        return .result()
    }
}

@available(iOS 26.0, *)
public struct NativeAlarmMetadata: AlarmMetadata {
    public var alarmId: String
    public var audioTrackId: String

    public init(alarmId: String, audioTrackId: String) {
        self.alarmId = alarmId
        self.audioTrackId = audioTrackId
    }
}
#endif

// ---------------------------------------------------------------------------
// Shared helpers
// ---------------------------------------------------------------------------

/// Flutter alarm ids are arbitrary strings ("alarm_1"), but AlarmKit needs a UUID.
/// Always derive the same UUID from the same id, so stop/cancel can find the alarm
/// even after the app was killed.
enum AlarmIdMapper {
    static func uuid(for alarmId: String) -> UUID {
        if let existing = UUID(uuidString: alarmId) { return existing }
        var bytes = Array(SHA256.hash(data: Data(alarmId.utf8)).prefix(16))
        bytes[6] = (bytes[6] & 0x0F) | 0x50
        bytes[8] = (bytes[8] & 0x3F) | 0x80
        return UUID(uuid: (
            bytes[0], bytes[1], bytes[2], bytes[3], bytes[4], bytes[5], bytes[6], bytes[7],
            bytes[8], bytes[9], bytes[10], bytes[11], bytes[12], bytes[13], bytes[14], bytes[15]
        ))
    }
}

/// Everything Flutter told us about one alarm. Persisted so it is available when the
/// alarm fires while the app is not running.
struct AlarmConfig: Codable {
    var alarmId: String
    var audioTrackId: String
    var missionName: String
    var repeatCount: Int
    var repeatIntervalSec: Int
    var tuneName: String?
    var title: String?

    static let maxRepeatCount = 20
    static let minIntervalSec = 5

    var safeRepeatCount: Int { min(max(repeatCount, 0), AlarmConfig.maxRepeatCount) }
    var safeIntervalSec: Int { max(repeatIntervalSec, AlarmConfig.minIntervalSec) }
}

final class AlarmConfigStore {
    static let shared = AlarmConfigStore()
    private init() {}

    private func key(_ alarmId: String) -> String { "alarmflow.config.\(alarmId)" }

    func save(_ config: AlarmConfig) {
        if let data = try? JSONEncoder().encode(config) {
            UserDefaults.standard.set(data, forKey: key(config.alarmId))
        }
    }

    func load(_ alarmId: String) -> AlarmConfig? {
        guard let data = UserDefaults.standard.data(forKey: key(alarmId)) else { return nil }
        return try? JSONDecoder().decode(AlarmConfig.self, from: data)
    }

    func remove(_ alarmId: String) {
        UserDefaults.standard.removeObject(forKey: key(alarmId))
    }
}

/// Single place that runs when the user got past the lock screen (Stop or Mission).
/// Stops the ringing alarm, cancels every internal repeat (alarms + notifications),
/// and hands the alarm id to Flutter exactly once.
enum AlarmUnlockCoordinator {
    static func handleUnlocked(alarmId: String, audioTrackId: String, source: String) async {
        #if canImport(AlarmKit)
        if #available(iOS 26.0, *) {
            let uuid = AlarmIdMapper.uuid(for: alarmId)
            do {
                try AlarmManager.shared.stop(id: uuid)
                AlarmFlowLogger.shared.log("\(source): AlarmManager.stop succeeded for \(uuid)")
            } catch {
                AlarmFlowLogger.shared.log("\(source): AlarmManager.stop threw: \(error)")
            }
        }
        #endif

        BackupAlarmManager.shared.cancelBackupAlarms(for: alarmId)
        PendingPlaybackManager.shared.recordRequest(alarmId: alarmId, trackId: audioTrackId)

        await MainActor.run {
            AppDelegate.launchedFromAlarm = true
            AppDelegate.launchAlarmId = alarmId
            AudioPlaybackManager.shared.start(audioTrackId: audioTrackId)
        }
    }
}

// ---------------------------------------------------------------------------
// BackupAlarmManager  –  internal repeat alarms (count/interval come from Flutter)
//
// iOS 26+  : extra AlarmKit alarms at trigger + interval * n, plus an info
//            notification before each one.
// iOS < 26 : extra time-sensitive notifications with the alarm sound.
// All of them are cancelled together as soon as the user unlocks.
// ---------------------------------------------------------------------------

final class BackupAlarmManager {
    static let shared = BackupAlarmManager()

    private let mappingKey = "alarmflow.backupAlarmMapping"
    private let reverseMappingKey = "alarmflow.backupToMainMapping"
    private let lock = NSLock()

    private init() {}

    static func notificationId(alarmId: String, index: Int) -> String {
        "backup_\(alarmId)_\(index)"
    }

    private func notificationIds(for alarmId: String) -> [String] {
        (1...AlarmConfig.maxRepeatCount).map { BackupAlarmManager.notificationId(alarmId: alarmId, index: $0) }
    }

    /// Notification shown for the n-th internal alarm. With AlarmKit it is informational
    /// (the alarm itself rings); on older iOS it is the ring itself.
    func scheduleNotification(config: AlarmConfig, index: Int, fireDate: Date, rings: Bool) {
        let delay = fireDate.timeIntervalSinceNow
        guard delay > 0 else { return }

        let content = UNMutableNotificationContent()
        if rings {
            content.title = config.missionName
            content.body = "Alarm \(index) of \(config.safeRepeatCount). Unlock your phone to stop it."
            content.categoryIdentifier = AlarmScheduler.alarmCategoryId
            content.sound = UNNotificationSound(named: UNNotificationSoundName(config.tuneName ?? "demo.aiff"))
        } else {
            content.title = "Alarm rings again in \(config.safeIntervalSec) seconds"
            content.body = "Repeat \(index) of \(config.safeRepeatCount). Unlock your phone to stop it."
        }
        content.userInfo = [
            "alarmId": config.alarmId,
            "audioTrackId": config.audioTrackId,
            "missionName": config.missionName
        ]
        if #available(iOS 15.0, *) {
            content.interruptionLevel = .timeSensitive
        }

        let request = UNNotificationRequest(
            identifier: BackupAlarmManager.notificationId(alarmId: config.alarmId, index: index),
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
        )
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                AlarmFlowLogger.shared.log("BackupAlarmManager: notification \(index) failed: \(error)")
            }
        }
    }

    /// iOS < 26 path: repeats are plain notifications that ring.
    func scheduleFallbackRepeats(config: AlarmConfig, timeMs: Int64) {
        let base = Date(timeIntervalSince1970: Double(timeMs) / 1000.0)
        for n in stride(from: 1, through: config.safeRepeatCount, by: 1) {
            scheduleNotification(
                config: config,
                index: n,
                fireDate: base.addingTimeInterval(TimeInterval(config.safeIntervalSec * n)),
                rings: true
            )
        }
    }

    func getMapping() -> [String: [String]] {
        lock.lock()
        defer { lock.unlock() }
        return UserDefaults.standard.dictionary(forKey: mappingKey) as? [String: [String]] ?? [:]
    }

    func mainAlarmId(for backupId: String) -> String? {
        lock.lock()
        defer { lock.unlock() }
        let rev = UserDefaults.standard.dictionary(forKey: reverseMappingKey) as? [String: String] ?? [:]
        return rev[backupId]
    }

    func recordMapping(mainAlarmId: String, backupIds: [String]) {
        lock.lock()
        defer { lock.unlock() }

        var mapping = UserDefaults.standard.dictionary(forKey: mappingKey) as? [String: [String]] ?? [:]
        mapping[mainAlarmId] = backupIds
        UserDefaults.standard.set(mapping, forKey: mappingKey)

        var rev = UserDefaults.standard.dictionary(forKey: reverseMappingKey) as? [String: String] ?? [:]
        for bId in backupIds {
            rev[bId] = mainAlarmId
        }
        UserDefaults.standard.set(rev, forKey: reverseMappingKey)

        AlarmFlowLogger.shared.log("BackupAlarmManager: Recorded \(backupIds.count) backups for mainAlarmId=\(mainAlarmId)")
    }

    func scheduleBackupAlarms(config: AlarmConfig, timeMs: Int64) {
        // Always start from a clean slate (idempotent).
        cancelBackupAlarms(for: config.alarmId)

        // repeatCount == 0 from Flutter means: no internal alarms at all.
        guard config.safeRepeatCount > 0 else { return }

        #if canImport(AlarmKit)
        if #available(iOS 26.0, *) {
            Task {
                let baseDate = Date(timeIntervalSince1970: Double(timeMs) / 1000.0)
                var scheduledBackupIds: [String] = []

                for n in stride(from: 1, through: config.safeRepeatCount, by: 1) {
                    let backupDate = baseDate.addingTimeInterval(TimeInterval(config.safeIntervalSec * n))
                    if backupDate.timeIntervalSinceNow <= 0 { continue }

                    let backupUUID = UUID()
                    let config26 = AlarmScheduler.shared.makeConfiguration(
                        config: config,
                        fireDate: backupDate
                    )

                    do {
                        _ = try await AlarmManager.shared.schedule(id: backupUUID, configuration: config26)
                        scheduledBackupIds.append(backupUUID.uuidString)
                        // Info notification right before this internal alarm rings.
                        self.scheduleNotification(
                            config: config,
                            index: n,
                            fireDate: backupDate.addingTimeInterval(-TimeInterval(config.safeIntervalSec)).addingTimeInterval(0.5),
                            rings: false
                        )
                        AlarmFlowLogger.shared.log("BackupAlarmManager: Scheduled internal alarm #\(n) (id=\(backupUUID.uuidString)) for mainAlarmId=\(config.alarmId)")
                    } catch {
                        AlarmFlowLogger.shared.log("BackupAlarmManager: Failed to schedule internal alarm #\(n): \(error)")
                    }
                }

                self.recordMapping(mainAlarmId: config.alarmId, backupIds: scheduledBackupIds)
            }
            return
        }
        #endif

        scheduleFallbackRepeats(config: config, timeMs: timeMs)
    }

    func cancelBackupAlarms(for alarmId: String) {
        lock.lock()
        var mapping = UserDefaults.standard.dictionary(forKey: mappingKey) as? [String: [String]] ?? [:]
        var rev = UserDefaults.standard.dictionary(forKey: reverseMappingKey) as? [String: String] ?? [:]

        let targetMainId: String
        if let parent = rev[alarmId] {
            targetMainId = parent
        } else {
            targetMainId = alarmId
        }

        let backupIds = mapping[targetMainId] ?? []
        mapping.removeValue(forKey: targetMainId)
        for bId in backupIds {
            rev.removeValue(forKey: bId)
        }
        UserDefaults.standard.set(mapping, forKey: mappingKey)
        UserDefaults.standard.set(rev, forKey: reverseMappingKey)
        lock.unlock()

        // Internal-alarm notifications (info on iOS 26+, ringing on older iOS).
        let notifIds = notificationIds(for: targetMainId)
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: notifIds)
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: notifIds)

        if backupIds.isEmpty { return }

        AlarmFlowLogger.shared.log("BackupAlarmManager: Cancelling \(backupIds.count) backups for mainAlarmId=\(targetMainId)")

        #if canImport(AlarmKit)
        if #available(iOS 26.0, *) {
            for bId in backupIds {
                if let uuid = UUID(uuidString: bId) {
                    do {
                        AlarmFlowLogger.shared.log("BackupAlarmManager: Calling AlarmManager.shared.cancel(id: \(uuid))")
                        try AlarmManager.shared.cancel(id: uuid)
                        AlarmFlowLogger.shared.log("BackupAlarmManager: Cancelled backup alarm \(bId)")
                    } catch {
                        // Idempotent: safe if already cancelled or completed
                        AlarmFlowLogger.shared.log("BackupAlarmManager: Cancel backup \(bId) note: \(error)")
                    }
                }
            }
        }
        #endif
    }

    func clear() {
        lock.lock()
        defer { lock.unlock() }
        UserDefaults.standard.removeObject(forKey: mappingKey)
        UserDefaults.standard.removeObject(forKey: reverseMappingKey)
    }
}

// ---------------------------------------------------------------------------
// AlarmScheduler
//
// • iOS 26+  → AlarmKit integration with StopAndPlayIntent & OpenAndPlayIntent.
//              Main button shows mission name in orange, requires unlock.
//              Case B: Additive backup re-ring chain via BackupAlarmManager.
// • iOS < 26 → Time-sensitive local notifications with bundled "demo.aiff"
//              and a single "Stop" action (STOP_AND_PLAY) that opens the app
//              and starts custom-audio playback via AudioPlaybackManager.
// ---------------------------------------------------------------------------

final class AlarmScheduler {

    static let shared = AlarmScheduler()

    // UNNotificationCategory / action identifiers
    static let alarmCategoryId = "ALARM_CATEGORY"
    static let stopActionId    = "STOP_AND_PLAY"

    private var isObservingUpdates = false

    private init() {}

    // MARK: – AlarmUpdates Observer

    func startObservingAlarmUpdates() {
        #if canImport(AlarmKit)
        if #available(iOS 26.0, *) {
            guard !isObservingUpdates else { return }
            isObservingUpdates = true
            Task {
                AlarmFlowLogger.shared.log("AlarmScheduler: Starting AlarmManager.shared.alarmUpdates observer")
                for await alarms in AlarmManager.shared.alarmUpdates {
                    for alarm in alarms {
                        let stateStr: String
                        switch alarm.state {
                        case .scheduled: stateStr = "scheduled"
                        case .countdown: stateStr = "countdown"
                        case .paused: stateStr = "paused"
                        case .alerting: stateStr = "alerting"
                        @unknown default: stateStr = "unknown"
                        }
                        AlarmFlowLogger.shared.log("AlarmUpdates: alarmId=\(alarm.id), state=\(stateStr)")
                    }
                }
            }
        }
        #endif
    }

    // MARK: – Notification Category Setup

    /// Registers the "Stop" action so the lock-screen notification shows
    /// a single button that opens the app and triggers custom audio playback.
    func registerNotificationCategory() {
        let stopAction = UNNotificationAction(
            identifier: AlarmScheduler.stopActionId,
            title: "Stop",
            options: [.foreground] // opens app to foreground
        )

        let category = UNNotificationCategory(
            identifier: AlarmScheduler.alarmCategoryId,
            actions: [stopAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )

        UNUserNotificationCenter.current()
            .setNotificationCategories([category])
    }

    /// Requests notification authorization (alert + sound + badge).
    func requestPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { granted, _ in
            completion(granted)
        }
    }

    /// Checks current notification authorization status.
    func hasPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            let authorized = (settings.authorizationStatus == .authorized ||
                              settings.authorizationStatus == .provisional)
            completion(authorized)
        }
    }

    // MARK: – Scheduling

    #if canImport(AlarmKit)
    @available(iOS 26.0, *)
    func makeConfiguration(config: AlarmConfig, fireDate: Date) -> AlarmManager.AlarmConfiguration<NativeAlarmMetadata> {
        let missionButton = AlarmButton(
            text: LocalizedStringResource(stringLiteral: config.missionName),
            textColor: .white,
            systemImageName: "sun.max.fill"
        )

        let presentation: AlarmPresentation
        if #available(iOS 26.1, *) {
            presentation = AlarmPresentation(
                alert: AlarmPresentation.Alert(
                    title: LocalizedStringResource(stringLiteral: config.title ?? config.missionName),
                    stopButton: missionButton,
                    secondaryButton: missionButton,
                    secondaryButtonBehavior: .custom
                )
            )
        } else {
            presentation = AlarmPresentation(
                alert: AlarmPresentation.Alert(
                    title: LocalizedStringResource(stringLiteral: config.title ?? config.missionName),
                    stopButton: missionButton
                )
            )
        }

        let attributes = AlarmAttributes<NativeAlarmMetadata>(
            presentation: presentation,
            metadata: NativeAlarmMetadata(alarmId: config.alarmId, audioTrackId: config.audioTrackId),
            tintColor: .orange
        )

        let sound: ActivityKit.AlertConfiguration.AlertSound =
            config.tuneName.map { .named($0) } ?? .default

        return AlarmManager.AlarmConfiguration.alarm(
            schedule: .fixed(fireDate),
            attributes: attributes,
            stopIntent: StopAndPlayIntent(alarmId: config.alarmId, audioTrackId: config.audioTrackId),
            secondaryIntent: OpenAndPlayIntent(alarmId: config.alarmId, audioTrackId: config.audioTrackId),
            sound: sound
        )
    }
    #endif

    func schedule(config: AlarmConfig, timeMs: Int64) {
        AlarmConfigStore.shared.save(config)

        #if canImport(AlarmKit)
        if #available(iOS 26.0, *) {
            Task {
                do {
                    if AlarmManager.shared.authorizationState == .notDetermined {
                        _ = try? await AlarmManager.shared.requestAuthorization()
                    }

                    let triggerDate = Date(timeIntervalSince1970: Double(timeMs) / 1000.0)
                    let uuid = AlarmIdMapper.uuid(for: config.alarmId)
                    // Re-scheduling the same alarm replaces the old one.
                    try? AlarmManager.shared.cancel(id: uuid)
                    _ = try await AlarmManager.shared.schedule(
                        id: uuid,
                        configuration: self.makeConfiguration(config: config, fireDate: triggerDate)
                    )
                    AlarmFlowLogger.shared.log("AlarmScheduler: Scheduled via AlarmKit alarmId=\(config.alarmId) uuid=\(uuid)")

                    BackupAlarmManager.shared.scheduleBackupAlarms(config: config, timeMs: timeMs)
                    return
                } catch {
                    AlarmFlowLogger.shared.log("AlarmScheduler: AlarmKit failed (\(error)), falling back to notifications")
                    self.scheduleLocalNotification(config: config, timeMs: timeMs)
                    BackupAlarmManager.shared.scheduleBackupAlarms(config: config, timeMs: timeMs)
                }
            }
            return
        }
        #endif

        scheduleLocalNotification(config: config, timeMs: timeMs)
        BackupAlarmManager.shared.scheduleBackupAlarms(config: config, timeMs: timeMs)
    }

    func scheduleLocalNotification(config: AlarmConfig, timeMs: Int64) {
        let triggerDate = Date(timeIntervalSince1970: Double(timeMs) / 1000.0)
        let delay = max(1.0, triggerDate.timeIntervalSinceNow)

        let content = UNMutableNotificationContent()
        content.title = config.missionName
        content.body  = "Tap to start your morning mission."
        content.categoryIdentifier = AlarmScheduler.alarmCategoryId
        content.userInfo = [
            "alarmId":      config.alarmId,
            "audioTrackId": config.audioTrackId,
            "missionName":  config.missionName
        ]
        content.sound = UNNotificationSound(named: UNNotificationSoundName(config.tuneName ?? "demo.aiff"))

        // Time-sensitive notification breaks through DND / Focus (iOS 15+)
        if #available(iOS 15.0, *) {
            content.interruptionLevel = .timeSensitive
        }

        let request = UNNotificationRequest(
            identifier: config.alarmId,
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
        )
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                AlarmFlowLogger.shared.log("AlarmScheduler: notification schedule error: \(error)")
            }
        }
    }

    func cancel(alarmId: String) {
        BackupAlarmManager.shared.cancelBackupAlarms(for: alarmId)

        #if canImport(AlarmKit)
        if #available(iOS 26.0, *) {
            let uuid = AlarmIdMapper.uuid(for: alarmId)
            do {
                try AlarmManager.shared.cancel(id: uuid)
            } catch {
                AlarmFlowLogger.shared.log("AlarmScheduler.cancel: \(error)")
            }
        }
        #endif

        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [alarmId])
        UNUserNotificationCenter.current()
            .removeDeliveredNotifications(withIdentifiers: [alarmId])
    }
}
