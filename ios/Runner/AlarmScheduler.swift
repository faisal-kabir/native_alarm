import Foundation
import AVFoundation
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

/// "Slide to stop". Runs in the background first, so the next internal alarm is set
/// the moment the user slides, even if the phone stays locked. Then it asks iOS to
/// unlock and open the app; only an unlock cancels that repeat and opens the message.
@available(iOS 26.0, *)
public struct StopAndPlayIntent: LiveActivityIntent {
    public static var title: LocalizedStringResource = "Stop & Play"
    public static var supportedModes: IntentModes { [.background, .foreground(.dynamic)] }

    @Parameter(title: "Alarm ID")
    public var alarmId: String

    @Parameter(title: "Audio Track ID")
    public var audioTrackId: String

    /// 0 = main alarm, 1...N = internal repeat number.
    @Parameter(title: "Run Index")
    public var runIndex: Int

    public init() {
        self.alarmId = ""
        self.audioTrackId = "morning_message"
        self.runIndex = 0
    }

    public init(alarmId: String, audioTrackId: String, runIndex: Int) {
        self.alarmId = alarmId
        self.audioTrackId = audioTrackId
        self.runIndex = runIndex
    }

    public func perform() async throws -> some IntentResult {
        AlarmFlowLogger.shared.log("StopAndPlayIntent.perform() entered for alarmId=\(alarmId), run=\(runIndex)")
        let stoppedAt = Date()
        // iOS already silenced this alarm. Ring again after the interval unless unlocked.
        await BackupAlarmManager.shared.scheduleNextRepeat(alarmId: alarmId, afterRun: runIndex)
        do {
            try await continueInForeground(nil, alwaysConfirm: false)
        } catch {
            AlarmFlowLogger.shared.log("StopAndPlayIntent: not unlocked (\(error)); next repeat stays scheduled")
            return .result()
        }
        await AlarmUnlockCoordinator.handleUnlocked(alarmId: alarmId, audioTrackId: audioTrackId, source: "StopAndPlayIntent", requestedAt: stoppedAt)
        return .result()
    }
}

/// "Start Morning Mission". The alarm keeps ringing until the user unlocks.
@available(iOS 26.0, *)
public struct OpenAndPlayIntent: LiveActivityIntent {
    public static var title: LocalizedStringResource = "Open & Play"
    public static var supportedModes: IntentModes { [.background, .foreground(.dynamic)] }

    @Parameter(title: "Alarm ID")
    public var alarmId: String

    @Parameter(title: "Audio Track ID")
    public var audioTrackId: String

    @Parameter(title: "Run Index")
    public var runIndex: Int

    public init() {
        self.alarmId = ""
        self.audioTrackId = "morning_message"
        self.runIndex = 0
    }

    public init(alarmId: String, audioTrackId: String, runIndex: Int) {
        self.alarmId = alarmId
        self.audioTrackId = audioTrackId
        self.runIndex = runIndex
    }

    public func perform() async throws -> some IntentResult {
        AlarmFlowLogger.shared.log("OpenAndPlayIntent.perform() entered for alarmId=\(alarmId), run=\(runIndex)")
        let requestedAt = Date()
        do {
            try await continueInForeground(nil, alwaysConfirm: false)
        } catch {
            AlarmFlowLogger.shared.log("OpenAndPlayIntent: not unlocked (\(error))")
            // If iOS dismissed the alert anyway, behave like Slide to stop.
            let stillRinging = (try? AlarmManager.shared.alarms)?.contains { $0.state == .alerting } ?? false
            if !stillRinging {
                await BackupAlarmManager.shared.scheduleNextRepeat(alarmId: alarmId, afterRun: runIndex)
            }
            return .result()
        }
        await AlarmUnlockCoordinator.handleUnlocked(alarmId: alarmId, audioTrackId: audioTrackId, source: "OpenAndPlayIntent", requestedAt: requestedAt)
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
    /// A weekly alarm: weekday (1 = Mon ... 7 = Sun) -> minutes after midnight. The
    /// system rings it every week by itself. nil = rings once, at `timeMs`.
    var ringDays: [Int: Int]?

    static let maxRepeatCount = 20
    static let minIntervalSec = 5

    var safeRepeatCount: Int { min(max(repeatCount, 0), AlarmConfig.maxRepeatCount) }
    var safeIntervalSec: Int { max(repeatIntervalSec, AlarmConfig.minIntervalSec) }

    /// The weekly alarm's times, earliest first, each with the weekdays that ring at it.
    var weeklyTimes: [(minutes: Int, weekdays: [Int])] {
        guard let ringDays = ringDays else { return [] }
        return Dictionary(grouping: ringDays.keys, by: { ringDays[$0]! })
            .map { (minutes: $0.key, weekdays: $0.value.sorted()) }
            .sorted { $0.minutes < $1.minutes }
    }

    /// AlarmKit ids of the main alarm, one per entry of `weeklyTimes` (AlarmKit repeats
    /// one time on several weekdays per alarm): the first is the alarm id's own.
    var mainIds: [UUID] {
        [AlarmIdMapper.uuid(for: alarmId)]
            + weeklyTimes.dropFirst().map { AlarmIdMapper.uuid(for: "\(alarmId)@\($0.minutes)") }
    }

    /// Notification ids of the main ring (iOS < 26): one per weekday of a weekly alarm.
    static func notificationIds(alarmId: String) -> [String] {
        [alarmId] + (1...7).map { "\(alarmId)#\($0)" }
    }

    /// `ringDays` from Flutter: weekday (1...7) -> minutes (0..<1440); anything else is dropped.
    static func parseRingDays(_ value: Any?) -> [Int: Int]? {
        guard let map = value as? [AnyHashable: Any] else { return nil }
        var days: [Int: Int] = [:]
        for (key, value) in map {
            guard let day = (key as? NSNumber)?.intValue ?? Int("\(key)"), (1...7).contains(day),
                  let minutes = (value as? NSNumber)?.intValue, (0..<1440).contains(minutes) else { continue }
            days[day] = minutes
        }
        return days.isEmpty ? nil : days
    }
}

/// The alarm's own copy of its sound (a downloaded alarm sound from Flutter), in
/// Library/Sounds where AlarmKit and notifications find it by name. Converted to CAF
/// (IMA4), a format both can play. The copy belongs to the alarm, so Flutter may
/// replace or delete the original afterwards.
enum AlarmTuneStore {
    private static var soundsDir: URL? {
        FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first?
            .appendingPathComponent("Sounds", isDirectory: true)
    }

    private static func prefix(_ alarmId: String) -> String {
        "eala-" + alarmId.map { $0.isLetter || $0.isNumber ? String($0) : "_" }.joined() + "-"
    }

    /// Installs [filePath] for [alarmId] and returns the sound's name, or nil (missing or
    /// unplayable file: the default tune rings). Downloaded file names change with their
    /// content, so an unchanged file is not converted again.
    static func install(filePath: String?, alarmId: String) -> String? {
        guard let filePath = filePath, !filePath.isEmpty, let dir = soundsDir else { return nil }
        let fm = FileManager.default
        guard fm.fileExists(atPath: filePath) else {
            AlarmFlowLogger.shared.log("AlarmTuneStore: file not found: \(filePath)")
            return nil
        }
        let source = URL(fileURLWithPath: filePath)
        let name = prefix(alarmId) + source.deletingPathExtension().lastPathComponent + ".caf"
        let target = dir.appendingPathComponent(name)
        remove(alarmId: alarmId, keeping: name)
        if fm.fileExists(atPath: target.path) { return name }
        do {
            try fm.createDirectory(at: dir, withIntermediateDirectories: true)
            try convert(source, to: target)
            return name
        } catch {
            try? fm.removeItem(at: target)
            AlarmFlowLogger.shared.log("AlarmTuneStore: could not install \(filePath): \(error)")
            return nil
        }
    }

    /// Deletes the alarm's copies (all but [keeping]).
    static func remove(alarmId: String, keeping: String? = nil) {
        guard let dir = soundsDir,
              let names = try? FileManager.default.contentsOfDirectory(atPath: dir.path) else { return }
        for name in names where name.hasPrefix(prefix(alarmId)) && name != keeping {
            try? FileManager.default.removeItem(at: dir.appendingPathComponent(name))
        }
    }

    private static func convert(_ source: URL, to target: URL) throws {
        let input = try AVAudioFile(forReading: source)
        let format = input.processingFormat
        let output = try AVAudioFile(
            forWriting: target,
            settings: [
                AVFormatIDKey: kAudioFormatAppleIMA4,
                AVSampleRateKey: format.sampleRate,
                AVNumberOfChannelsKey: format.channelCount,
            ],
            commonFormat: format.commonFormat,
            interleaved: format.isInterleaved
        )
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 32_768) else {
            throw NSError(domain: "AlarmTuneStore", code: 1)
        }
        while input.framePosition < input.length {
            try input.read(into: buffer)
            if buffer.frameLength == 0 { break }
            try output.write(from: buffer)
        }
    }
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
    /// An unlock that comes this long after the alarm was acted on is not an answer to
    /// it (iOS can deliver a waiting intent at a much later unlock); it only cleans up.
    static let maxUnlockDelay: TimeInterval = 180

    static func handleUnlocked(alarmId: String, audioTrackId: String, source: String, requestedAt: Date = Date()) async {
        #if canImport(AlarmKit)
        if #available(iOS 26.0, *) {
            // The ringing alarm may be the main alarm or an internal repeat (which has its
            // own random UUID). Stopping only the main UUID left a repeat stuck in
            // "alerting", and iOS rang it again hours later. Stop everything that rings.
            // Only what is ringing: a weekly alarm stays set for its next day.
            var toStop: Set<UUID> = []
            if let alarms = try? AlarmManager.shared.alarms {
                for alarm in alarms where alarm.state == .alerting {
                    toStop.insert(alarm.id)
                }
            } else {
                toStop.insert(AlarmIdMapper.uuid(for: alarmId))
            }
            for uuid in toStop {
                do {
                    try AlarmManager.shared.stop(id: uuid)
                    AlarmFlowLogger.shared.log("\(source): AlarmManager.stop succeeded for \(uuid)")
                } catch {
                    AlarmFlowLogger.shared.log("\(source): AlarmManager.stop(\(uuid)) note: \(error)")
                }
            }
        }
        #endif

        BackupAlarmManager.shared.cancelBackupAlarms(for: alarmId)

        let delay = Date().timeIntervalSince(requestedAt)
        guard delay <= maxUnlockDelay else {
            AlarmFlowLogger.shared.log("\(source): unlock came \(Int(delay))s late; not starting the message")
            return
        }
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
// iOS 26+  : one AlarmKit alarm at a time, set `interval` seconds after each
//            "Slide to stop" (scheduleNextRepeat), plus an info notification.
// iOS < 26 : time-sensitive notifications with the alarm sound, set up front.
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

        scheduleFallbackRepeats(config: config, timeMs: timeMs)
    }

    /// AlarmKit path: sets the single next internal alarm, `interval` seconds from now,
    /// right after the user slid the alarm away. (Pre-scheduling them all at trigger time
    /// made the repeats ring on top of the main alarm while it was still ringing.)
    func scheduleNextRepeat(alarmId: String, afterRun runIndex: Int) async {
        #if canImport(AlarmKit)
        if #available(iOS 26.0, *) {
            guard let config = AlarmConfigStore.shared.load(alarmId) else { return }
            let next = runIndex + 1
            guard next <= config.safeRepeatCount else {
                AlarmFlowLogger.shared.log("BackupAlarmManager: no repeats left for \(alarmId) after run \(runIndex)")
                return
            }
            let fireDate = Date().addingTimeInterval(TimeInterval(config.safeIntervalSec))
            let uuid = UUID()
            do {
                _ = try await AlarmManager.shared.schedule(
                    id: uuid,
                    configuration: AlarmScheduler.shared.makeConfiguration(config: config, schedule: .fixed(fireDate), runIndex: next)
                )
                appendMapping(mainAlarmId: alarmId, backupId: uuid.uuidString)
                scheduleNotification(config: config, index: next, fireDate: Date().addingTimeInterval(0.5), rings: false)
                AlarmFlowLogger.shared.log("BackupAlarmManager: Scheduled internal alarm #\(next) (id=\(uuid)) for \(alarmId) at \(fireDate)")
            } catch {
                AlarmFlowLogger.shared.log("BackupAlarmManager: Failed to schedule internal alarm #\(next): \(error)")
            }
        }
        #endif
    }

    private func appendMapping(mainAlarmId: String, backupId: String) {
        lock.lock()
        defer { lock.unlock() }
        var mapping = UserDefaults.standard.dictionary(forKey: mappingKey) as? [String: [String]] ?? [:]
        mapping[mainAlarmId, default: []].append(backupId)
        UserDefaults.standard.set(mapping, forKey: mappingKey)
        var rev = UserDefaults.standard.dictionary(forKey: reverseMappingKey) as? [String: String] ?? [:]
        rev[backupId] = mainAlarmId
        UserDefaults.standard.set(rev, forKey: reverseMappingKey)
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
                    // A repeat that is ringing right now must be stopped, not only cancelled.
                    try? AlarmManager.shared.stop(id: uuid)
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
            cleanUpOrphanAlarms()
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

    #if canImport(AlarmKit)
    /// Logs every AlarmKit alarm the system holds for this app and cancels scheduled ones
    /// that no Flutter alarm or internal repeat owns any more (leftovers of old runs).
    @available(iOS 26.0, *)
    private func cleanUpOrphanAlarms() {
        guard let alarms = try? AlarmManager.shared.alarms else { return }
        let configPrefix = "alarmflow.config."
        var owners: [UUID: String] = [:]
        for key in UserDefaults.standard.dictionaryRepresentation().keys where key.hasPrefix(configPrefix) {
            let alarmId = String(key.dropFirst(configPrefix.count))
            owners[AlarmIdMapper.uuid(for: alarmId)] = alarmId
            for uuid in AlarmConfigStore.shared.load(alarmId)?.mainIds ?? [] {
                owners[uuid] = alarmId
            }
        }
        for (mainId, backupIds) in BackupAlarmManager.shared.getMapping() {
            for bId in backupIds {
                if let uuid = UUID(uuidString: bId) { owners[uuid] = "\(mainId) (repeat)" }
            }
        }

        AlarmFlowLogger.shared.log("AlarmScheduler: system holds \(alarms.count) AlarmKit alarm(s)")
        for alarm in alarms {
            let owner = owners[alarm.id]
            AlarmFlowLogger.shared.log("AlarmScheduler: alarm \(alarm.id) state=\(alarm.state) owner=\(owner ?? "none") schedule=\(String(describing: alarm.schedule))")
            if owner == nil && alarm.state == .scheduled {
                try? AlarmManager.shared.cancel(id: alarm.id)
                AlarmFlowLogger.shared.log("AlarmScheduler: cancelled orphan alarm \(alarm.id)")
            }
        }
    }
    #endif

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
    func makeConfiguration(config: AlarmConfig, schedule: Alarm.Schedule, runIndex: Int = 0) -> AlarmManager.AlarmConfiguration<NativeAlarmMetadata> {
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
            schedule: schedule,
            attributes: attributes,
            stopIntent: StopAndPlayIntent(alarmId: config.alarmId, audioTrackId: config.audioTrackId, runIndex: runIndex),
            secondaryIntent: OpenAndPlayIntent(alarmId: config.alarmId, audioTrackId: config.audioTrackId, runIndex: runIndex),
            sound: sound
        )
    }

    /// The main alarm's AlarmKit schedules with their ids: one fixed ring, or one weekly
    /// schedule per time of the week.
    @available(iOS 26.0, *)
    private func mainSchedules(config: AlarmConfig, timeMs: Int64) -> [(UUID, Alarm.Schedule)] {
        let times = config.weeklyTimes
        if times.isEmpty {
            let triggerDate = Date(timeIntervalSince1970: Double(timeMs) / 1000.0)
            return [(AlarmIdMapper.uuid(for: config.alarmId), .fixed(triggerDate))]
        }
        let weekdays: [Locale.Weekday] = [.monday, .tuesday, .wednesday, .thursday, .friday, .saturday, .sunday]
        return zip(config.mainIds, times).map { id, time in
            (id, .relative(Alarm.Schedule.Relative(
                time: Alarm.Schedule.Relative.Time(hour: time.minutes / 60, minute: time.minutes % 60),
                repeats: .weekly(time.weekdays.map { weekdays[$0 - 1] })
            )))
        }
    }
    #endif

    func schedule(config: AlarmConfig, timeMs: Int64) {
        let previous = AlarmConfigStore.shared.load(config.alarmId)
        AlarmConfigStore.shared.save(config)

        #if canImport(AlarmKit)
        if #available(iOS 26.0, *) {
            Task {
                do {
                    if AlarmManager.shared.authorizationState == .notDetermined {
                        _ = try? await AlarmManager.shared.requestAuthorization()
                    }

                    // Re-scheduling the same alarm replaces the old one (and times of the
                    // week it no longer has).
                    for uuid in Set((previous?.mainIds ?? []) + config.mainIds) {
                        try? AlarmManager.shared.cancel(id: uuid)
                    }
                    for (uuid, schedule) in self.mainSchedules(config: config, timeMs: timeMs) {
                        _ = try await AlarmManager.shared.schedule(
                            id: uuid,
                            configuration: self.makeConfiguration(config: config, schedule: schedule)
                        )
                        AlarmFlowLogger.shared.log("AlarmScheduler: Scheduled via AlarmKit alarmId=\(config.alarmId) uuid=\(uuid) schedule=\(schedule)")
                    }

                    // Repeats are set one by one after each Slide to stop (scheduleNextRepeat).
                    BackupAlarmManager.shared.cancelBackupAlarms(for: config.alarmId)
                    return
                } catch {
                    AlarmFlowLogger.shared.log("AlarmScheduler: AlarmKit failed (\(error)), falling back to notifications")
                    // Times of the week already set would ring twice.
                    for uuid in config.mainIds { try? AlarmManager.shared.cancel(id: uuid) }
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
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: AlarmConfig.notificationIds(alarmId: config.alarmId))
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

        // A weekly alarm rings every week on each of its days by itself.
        var requests: [UNNotificationRequest] = []
        if let ringDays = config.ringDays {
            for (day, minutes) in ringDays {
                var when = DateComponents()
                when.weekday = day % 7 + 1 // 1 = Mon ... 7 = Sun -> Calendar's 1 = Sun ... 7 = Sat
                when.hour = minutes / 60
                when.minute = minutes % 60
                requests.append(UNNotificationRequest(
                    identifier: "\(config.alarmId)#\(day)",
                    content: content,
                    trigger: UNCalendarNotificationTrigger(dateMatching: when, repeats: true)
                ))
            }
        } else {
            requests.append(UNNotificationRequest(
                identifier: config.alarmId,
                content: content,
                trigger: UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
            ))
        }
        for request in requests {
            center.add(request) { error in
                if let error = error {
                    AlarmFlowLogger.shared.log("AlarmScheduler: notification schedule error: \(error)")
                }
            }
        }
    }

    /// The message after a ring is over. A weekly alarm stays set for its next day (only
    /// its ring-again repeats go, as on Android); a one-off alarm is done.
    func finish(alarmId: String) {
        if AlarmConfigStore.shared.load(alarmId)?.ringDays != nil {
            BackupAlarmManager.shared.cancelBackupAlarms(for: alarmId)
        } else {
            cancel(alarmId: alarmId)
        }
    }

    func cancel(alarmId: String) {
        BackupAlarmManager.shared.cancelBackupAlarms(for: alarmId)
        let config = AlarmConfigStore.shared.load(alarmId)

        #if canImport(AlarmKit)
        if #available(iOS 26.0, *) {
            for uuid in config?.mainIds ?? [AlarmIdMapper.uuid(for: alarmId)] {
                do {
                    try AlarmManager.shared.cancel(id: uuid)
                } catch {
                    AlarmFlowLogger.shared.log("AlarmScheduler.cancel: \(error)")
                }
            }
        }
        #endif

        let ids = AlarmConfig.notificationIds(alarmId: alarmId)
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ids)
        UNUserNotificationCenter.current()
            .removeDeliveredNotifications(withIdentifiers: ids)
        AlarmTuneStore.remove(alarmId: alarmId)
    }
}
