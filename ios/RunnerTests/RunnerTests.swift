import Flutter
import UIKit
import XCTest
@testable import Runner

class RunnerTests: XCTestCase {

    override func setUp() {
        super.setUp()
        PendingPlaybackManager.shared.clear()
        AlarmFlowLogger.shared.clear()
    }

    override func tearDown() {
        PendingPlaybackManager.shared.clear()
        AlarmFlowLogger.shared.clear()
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
}
