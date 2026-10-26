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
// AlarmScheduler
//
// • iOS 26+  → AlarmKit integration with StopAndPlayIntent & OpenAndPlayIntent.
// • iOS < 26 → Time-sensitive local notifications with bundled "demo.aiff"
//              and a single "Stop" action (STOP_AND_PLAY) that opens the app
//              and starts custom-audio playback via AudioPlaybackManager.
// ---------------------------------------------------------------------------

final class AlarmScheduler {

    static let shared = AlarmScheduler()

    // UNNotificationCategory / action identifiers
    static let alarmCategoryId = "ALARM_CATEGORY"
    static let stopActionId    = "STOP_AND_PLAY"

    private init() {}

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

    func schedule(alarmId: String, timeMs: Int64, audioTrackId: String) {
        #if canImport(AlarmKit)
        if #available(iOS 26.0, *) {
            Task {
                do {
                    let authState = AlarmManager.shared.authorizationState
                    if authState == .notDetermined {
                        _ = try? await AlarmManager.shared.requestAuthorization()
                    }

                    let triggerDate = Date(timeIntervalSince1970: Double(timeMs) / 1000.0)
                    let presentation: AlarmPresentation
                    if #available(iOS 26.1, *) {
                        presentation = AlarmPresentation(
                            alert: AlarmPresentation.Alert(title: "Alarm")
                        )
                    } else {
                        presentation = AlarmPresentation(
                            alert: AlarmPresentation.Alert(
                                title: "Alarm",
                                stopButton: AlarmButton(text: "Stop", textColor: .white, systemImageName: "stop.fill")
                            )
                        )
                    }

                    let attributes = AlarmAttributes<NativeAlarmMetadata>(
                        presentation: presentation,
                        metadata: NativeAlarmMetadata(alarmId: alarmId, audioTrackId: audioTrackId),
                        tintColor: .purple
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
                    return
                } catch {
                    print("[AlarmScheduler] AlarmKit failed (\(error)), falling back to UNNotification: \(alarmId)")
                    self.scheduleLocalNotification(alarmId: alarmId, timeMs: timeMs, audioTrackId: audioTrackId)
                }
            }
            return
        }
        #endif

        scheduleLocalNotification(alarmId: alarmId, timeMs: timeMs, audioTrackId: audioTrackId)
    }

    func scheduleLocalNotification(alarmId: String, timeMs: Int64, audioTrackId: String) {
        let triggerDate = Date(timeIntervalSince1970: Double(timeMs) / 1000.0)
        let delay = max(1.0, triggerDate.timeIntervalSinceNow)

        let content = UNMutableNotificationContent()
        content.title = "⏰ Alarm"
        content.body  = "Tap Stop to listen to your message."
        content.categoryIdentifier = AlarmScheduler.alarmCategoryId
        content.userInfo = [
            "alarmId":      alarmId,
            "audioTrackId": audioTrackId
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
        #if canImport(AlarmKit)
        if #available(iOS 26.0, *) {
            if let uuid = UUID(uuidString: alarmId) {
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
