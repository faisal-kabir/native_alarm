import Foundation
import UserNotifications
import ActivityKit
import AppIntents

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

        // Stop the alarm sound so custom audio and alarm ringtone never overlap
        if let uuid = UUID(uuidString: alarmId) {
            do {
                AlarmFlowLogger.shared.log("StopAndPlayIntent: Calling AlarmManager.shared.stop(id: \(uuid))")
                try AlarmManager.shared.stop(id: uuid)
                AlarmFlowLogger.shared.log("StopAndPlayIntent: AlarmManager.shared.stop succeeded for \(uuid)")
            } catch {
                AlarmFlowLogger.shared.log("StopAndPlayIntent: AlarmManager.shared.stop threw error: \(error)")
            }
        }

        // Cancel any backup alarms for this mission as app has unlocked
        BackupAlarmManager.shared.cancelBackupAlarms(for: alarmId)

        // Record persistent pending playback request
        PendingPlaybackManager.shared.recordRequest(alarmId: alarmId, trackId: audioTrackId)

        // Mark launchedFromAlarm on main app delegate
        await MainActor.run {
            AppDelegate.launchedFromAlarm = true
            AudioPlaybackManager.shared.start(audioTrackId: audioTrackId)
        }

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

        if let uuid = UUID(uuidString: alarmId) {
            do {
                AlarmFlowLogger.shared.log("OpenAndPlayIntent: Calling AlarmManager.shared.stop(id: \(uuid))")
                try AlarmManager.shared.stop(id: uuid)
                AlarmFlowLogger.shared.log("OpenAndPlayIntent: AlarmManager.shared.stop succeeded for \(uuid)")
            } catch {
                AlarmFlowLogger.shared.log("OpenAndPlayIntent: AlarmManager.shared.stop threw error: \(error)")
            }
        }

        // Cancel any backup alarms for this mission as app has unlocked
        BackupAlarmManager.shared.cancelBackupAlarms(for: alarmId)

        PendingPlaybackManager.shared.recordRequest(alarmId: alarmId, trackId: audioTrackId)

        await MainActor.run {
            AppDelegate.launchedFromAlarm = true
            AudioPlaybackManager.shared.start(audioTrackId: audioTrackId)
        }

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
// BackupAlarmManager  –  Case B: Additive Backup Re-Ring Mechanism
// ---------------------------------------------------------------------------

final class BackupAlarmManager {
    static let shared = BackupAlarmManager()

    private let mappingKey = "alarmflow.backupAlarmMapping"
    private let reverseMappingKey = "alarmflow.backupToMainMapping"
    private let lock = NSLock()

    // Backup offsets: +30s, +60s, +90s, +120s, +180s, +300s (6 alarms)
    // Documented limit: capped at 6 to prevent exceeding AlarmKit limits and avoid user annoyance.
    let backupOffsets: [TimeInterval] = [30, 60, 90, 120, 180, 300]

    private init() {}

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

    func scheduleBackupAlarms(mainAlarmId: String, timeMs: Int64, audioTrackId: String, missionName: String) {
        #if canImport(AlarmKit)
        if #available(iOS 26.0, *) {
            Task {
                // Cancel any previous backups for this alarm (idempotent)
                self.cancelBackupAlarms(for: mainAlarmId)

                let baseDate = Date(timeIntervalSince1970: Double(timeMs) / 1000.0)
                var scheduledBackupIds: [String] = []

                for offset in self.backupOffsets {
                    let backupDate = baseDate.addingTimeInterval(offset)
                    if backupDate.timeIntervalSinceNow <= 0 { continue }

                    let backupUUID = UUID()
                    let missionButton = AlarmButton(
                        text: LocalizedStringResource(stringLiteral: missionName),
                        textColor: .white,
                        systemImageName: "sun.max.fill"
                    )

                    let presentation: AlarmPresentation
                    if #available(iOS 26.1, *) {
                        presentation = AlarmPresentation(
                            alert: AlarmPresentation.Alert(
                                title: LocalizedStringResource(stringLiteral: missionName),
                                stopButton: missionButton,
                                secondaryButton: missionButton,
                                secondaryButtonBehavior: .custom
                            )
                        )
                    } else {
                        presentation = AlarmPresentation(
                            alert: AlarmPresentation.Alert(
                                title: LocalizedStringResource(stringLiteral: missionName),
                                stopButton: missionButton
                            )
                        )
                    }

                    let attributes = AlarmAttributes<NativeAlarmMetadata>(
                        presentation: presentation,
                        metadata: NativeAlarmMetadata(alarmId: mainAlarmId, audioTrackId: audioTrackId),
                        tintColor: .orange
                    )

                    let config = AlarmManager.AlarmConfiguration.alarm(
                        schedule: .fixed(backupDate),
                        attributes: attributes,
                        stopIntent: StopAndPlayIntent(alarmId: mainAlarmId, audioTrackId: audioTrackId),
                        secondaryIntent: OpenAndPlayIntent(alarmId: mainAlarmId, audioTrackId: audioTrackId)
                    )

                    do {
                        _ = try await AlarmManager.shared.schedule(id: backupUUID, configuration: config)
                        scheduledBackupIds.append(backupUUID.uuidString)
                        AlarmFlowLogger.shared.log("BackupAlarmManager: Scheduled backup alarm +\(Int(offset))s (id=\(backupUUID.uuidString)) for mainAlarmId=\(mainAlarmId)")
                    } catch {
                        AlarmFlowLogger.shared.log("BackupAlarmManager: Failed to schedule backup +\(Int(offset))s: \(error)")
                    }
                }

                self.recordMapping(mainAlarmId: mainAlarmId, backupIds: scheduledBackupIds)
            }
        }
        #endif
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

    func schedule(alarmId: String, timeMs: Int64, audioTrackId: String, missionName: String? = nil) {
        let resolvedMissionName = (missionName?.isEmpty == false) ? missionName! : "Start Morning Mission"

        #if canImport(AlarmKit)
        if #available(iOS 26.0, *) {
            Task {
                do {
                    let authState = AlarmManager.shared.authorizationState
                    if authState == .notDetermined {
                        _ = try? await AlarmManager.shared.requestAuthorization()
                    }

                    let triggerDate = Date(timeIntervalSince1970: Double(timeMs) / 1000.0)
                    let missionButton = AlarmButton(
                        text: LocalizedStringResource(stringLiteral: resolvedMissionName),
                        textColor: .white,
                        systemImageName: "sun.max.fill"
                    )

                    let presentation: AlarmPresentation
                    if #available(iOS 26.1, *) {
                        presentation = AlarmPresentation(
                            alert: AlarmPresentation.Alert(
                                title: LocalizedStringResource(stringLiteral: resolvedMissionName),
                                stopButton: missionButton,
                                secondaryButton: missionButton,
                                secondaryButtonBehavior: .custom
                            )
                        )
                    } else {
                        presentation = AlarmPresentation(
                            alert: AlarmPresentation.Alert(
                                title: LocalizedStringResource(stringLiteral: resolvedMissionName),
                                stopButton: missionButton
                            )
                        )
                    }

                    let attributes = AlarmAttributes<NativeAlarmMetadata>(
                        presentation: presentation,
                        metadata: NativeAlarmMetadata(alarmId: alarmId, audioTrackId: audioTrackId),
                        tintColor: .orange
                    )

                    let config = AlarmManager.AlarmConfiguration.alarm(
                        schedule: .fixed(triggerDate),
                        attributes: attributes,
                        stopIntent: StopAndPlayIntent(alarmId: alarmId, audioTrackId: audioTrackId),
                        secondaryIntent: OpenAndPlayIntent(alarmId: alarmId, audioTrackId: audioTrackId)
                    )

                    let uuid = UUID(uuidString: alarmId) ?? UUID()
                    _ = try await AlarmManager.shared.schedule(id: uuid, configuration: config)
                    print("[AlarmScheduler] Scheduled via AlarmKit: \(alarmId)")

                    // Case B: Additive backup re-ring chain
                    BackupAlarmManager.shared.scheduleBackupAlarms(
                        mainAlarmId: alarmId,
                        timeMs: timeMs,
                        audioTrackId: audioTrackId,
                        missionName: resolvedMissionName
                    )
                    return
                } catch {
                    print("[AlarmScheduler] AlarmKit failed (\(error)), falling back to UNNotification: \(alarmId)")
                    self.scheduleLocalNotification(alarmId: alarmId, timeMs: timeMs, audioTrackId: audioTrackId, missionName: resolvedMissionName)
                }
            }
            return
        }
        #endif

        scheduleLocalNotification(alarmId: alarmId, timeMs: timeMs, audioTrackId: audioTrackId, missionName: resolvedMissionName)
    }

    func scheduleLocalNotification(alarmId: String, timeMs: Int64, audioTrackId: String, missionName: String? = nil) {
        let triggerDate = Date(timeIntervalSince1970: Double(timeMs) / 1000.0)
        let delay = max(1.0, triggerDate.timeIntervalSinceNow)
        let resolvedTitle = missionName ?? "⏰ Alarm"

        let content = UNMutableNotificationContent()
        content.title = resolvedTitle
        content.body  = "Tap to start your morning mission."
        content.categoryIdentifier = AlarmScheduler.alarmCategoryId
        content.userInfo = [
            "alarmId":      alarmId,
            "audioTrackId": audioTrackId,
            "missionName":  resolvedTitle
        ]

        // Bundled sound file for custom notification ring tone
        content.sound = UNNotificationSound(named: UNNotificationSoundName("demo.aiff"))

        // Time-sensitive notification breaks through DND / Focus (iOS 15+)
        if #available(iOS 15.0, *) {
            content.interruptionLevel = .timeSensitive
        }

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: delay, repeats: false
        )
        let request = UNNotificationRequest(
            identifier: alarmId, content: content, trigger: trigger
        )
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("[AlarmScheduler] schedule error: \(error)")
            } else {
                print("[AlarmScheduler] UNNotification scheduled for alarmId=\(alarmId), delay=\(delay)s")
            }
        }
    }

    func cancel(alarmId: String) {
        BackupAlarmManager.shared.cancelBackupAlarms(for: alarmId)

        #if canImport(AlarmKit)
        if #available(iOS 26.0, *) {
            if let uuid = UUID(uuidString: alarmId) {
                AlarmFlowLogger.shared.log("AlarmScheduler.cancel: Calling AlarmManager.shared.cancel(id: \(uuid))")
                try? AlarmManager.shared.cancel(id: uuid)
            }
        }
        #endif

        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [alarmId])
        UNUserNotificationCenter.current()
            .removeDeliveredNotifications(withIdentifiers: [alarmId])
    }
}
