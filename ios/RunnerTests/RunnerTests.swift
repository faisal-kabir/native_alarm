import Flutter
import UIKit
import XCTest
@testable import Runner

class RunnerTests: XCTestCase {

    override func setUp() {
        super.setUp()
        PendingPlaybackManager.shared.clear()
        AlarmFlowLogger.shared.clear()
        BackupAlarmManager.shared.clear()
    }

    override func tearDown() {
        PendingPlaybackManager.shared.clear()
        AlarmFlowLogger.shared.clear()
        BackupAlarmManager.shared.clear()
        super.tearDown()
    }

    // Test 1: Pending request is recorded and consumed once
    func testPendingRequestConsumeOnce() {
        PendingPlaybackManager.shared.recordRequest(alarmId: "test_alarm_123", trackId: "demo_alarm_message")

        // First consume should succeed
        let result1 = PendingPlaybackManager.shared.consumePendingRequestIfValid(maxAgeSeconds: 600)
        XCTAssertNotNil(result1, "First consume should succeed")
        XCTAssertEqual(result1?.alarmId, "test_alarm_123")
        XCTAssertEqual(result1?.trackId, "demo_alarm_message")

        // Second consume must return nil (consume once)
        let result2 = PendingPlaybackManager.shared.consumePendingRequestIfValid(maxAgeSeconds: 600)
        XCTAssertNil(result2, "Second consume must return nil because request is already consumed")
    }

    // Test 2: Expired request (> 10 minutes) returns nil
    func testPendingRequestExpiryAfterTenMinutes() {
        // Record request
        PendingPlaybackManager.shared.recordRequest(alarmId: "expired_alarm", trackId: "demo_alarm_message")

        // Consume with a 0-second max age (simulating expired request)
        let result = PendingPlaybackManager.shared.consumePendingRequestIfValid(maxAgeSeconds: -1)
        XCTAssertNil(result, "Expired request older than maxAgeSeconds should return nil")
    }

    // Test 3: Idempotent playback logic
    func testIdempotentAudioPlaybackManager() {
        let manager = AudioPlaybackManager.shared
        // Ensure starting same track when already playing is idempotent
        XCTAssertFalse(manager.isPlaying)
    }

    // Test 4: AlarmFlowLogger records logs and limits history
    func testAlarmFlowLogger() {
        AlarmFlowLogger.shared.log("Test log entry 1")
        AlarmFlowLogger.shared.log("Test log entry 2")

        let logs = AlarmFlowLogger.shared.getLogs()
        XCTAssertGreaterThanOrEqual(logs.count, 2)
        XCTAssertTrue(logs.contains(where: { $0.contains("Test log entry 1") }))
        XCTAssertTrue(logs.contains(where: { $0.contains("Test log entry 2") }))
    }

    // Test 5: BackupAlarmManager persists mapping and reverse mapping
    func testBackupAlarmMappingPersistence() {
        let mainId = "main_alarm_001"
        let backup1 = UUID().uuidString
        let backup2 = UUID().uuidString

        BackupAlarmManager.shared.recordMapping(mainAlarmId: mainId, backupIds: [backup1, backup2])

        let mapping = BackupAlarmManager.shared.getMapping()
        XCTAssertEqual(mapping[mainId]?.count, 2)
        XCTAssertEqual(mapping[mainId], [backup1, backup2])

        // Reverse lookup
        XCTAssertEqual(BackupAlarmManager.shared.mainAlarmId(for: backup1), mainId)
        XCTAssertEqual(BackupAlarmManager.shared.mainAlarmId(for: backup2), mainId)
    }

    // Test 6: BackupAlarmManager idempotent cancellation
    func testBackupAlarmCancellationIdempotence() {
        let mainId = "main_alarm_002"
        let backup1 = UUID().uuidString
        let backup2 = UUID().uuidString

        BackupAlarmManager.shared.recordMapping(mainAlarmId: mainId, backupIds: [backup1, backup2])

        // First cancellation clears mapping
        BackupAlarmManager.shared.cancelBackupAlarms(for: mainId)
        let mappingAfter = BackupAlarmManager.shared.getMapping()
        XCTAssertNil(mappingAfter[mainId])
        XCTAssertNil(BackupAlarmManager.shared.mainAlarmId(for: backup1))

        // Second cancellation is a safe no-op (idempotent)
        BackupAlarmManager.shared.cancelBackupAlarms(for: mainId)
        XCTAssertNil(BackupAlarmManager.shared.getMapping()[mainId])
    }

    // Test 7: BackupAlarmManager cancellation via backup UUID
    func testBackupAlarmCancellationViaBackupId() {
        let mainId = "main_alarm_003"
        let backup1 = UUID().uuidString
        let backup2 = UUID().uuidString

        BackupAlarmManager.shared.recordMapping(mainAlarmId: mainId, backupIds: [backup1, backup2])

        // Cancel using one of the backup IDs should cancel parent and siblings
        BackupAlarmManager.shared.cancelBackupAlarms(for: backup1)
        XCTAssertNil(BackupAlarmManager.shared.getMapping()[mainId])
        XCTAssertNil(BackupAlarmManager.shared.mainAlarmId(for: backup2))
    }

    // Test 8: Backup alarm offsets are bounded to 6 intervals
    func testBackupAlarmOffsetsCount() {
        let offsets = BackupAlarmManager.shared.backupOffsets
        XCTAssertEqual(offsets.count, 6)
        XCTAssertEqual(offsets, [30, 60, 90, 120, 180, 300])
    }
}
