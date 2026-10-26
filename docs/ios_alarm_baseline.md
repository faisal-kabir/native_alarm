# iOS Alarm Scheduling Baseline

This document captures the EXACT baseline implementation of alarm scheduling in `ios/Runner/AlarmScheduler.swift` prior to fixing the "Stop -> open app + play audio" flow.

As mandated by strict protection rules, the functions below must remain **byte-for-byte unchanged**:

```swift
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
```
