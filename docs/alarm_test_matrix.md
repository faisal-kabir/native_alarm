# Alarm behaviour test matrix (Android + iOS must match)

Config under test: `repeatCount = 2`, `repeatIntervalSec = 10` unless noted.
Run every row on a real device with the phone **locked**.

| # | Scenario | Expected |
|---|----------|----------|
| 1 | Alarm fires, user slides to stop and **unlocks** | Alarm stops. No internal alarm is scheduled/rings. Message page opens with the alarm's `alarmId`. |
| 2 | Slide to stop, **cancel** unlock | Alarm stops. Notification "rings again in 10 seconds". Alarm rings again ~10s later. |
| 3 | Row 2, then slide + **unlock** on the repeat | Alarm stops, remaining internal alarms + notifications are cancelled, message page opens. Nothing rings afterwards. |
| 4 | Slide without unlock every time | Rings `1 + repeatCount` times in total, then stops for good. |
| 5 | `repeatCount = 0`, slide without unlock | Alarm stops. No notification, no further ring. |
| 6 | Tap Mission button, do not unlock | Alarm keeps ringing and vibrating until unlocked. |
| 7 | Mission button, then unlock | Alarm stops, message page opens with the `alarmId`. |
| 8 | Custom tune set from Flutter | Custom tune plays (loops) instead of the default. |
| 9 | Button/title texts set from Flutter | Mission button and title show Flutter text. (Slider text: Android only.) |
| 10 | After row 1/3, kill the app, reopen | No audio replays, no alarm repeats, no message page opens by itself. |
| 11 | Two alarms with different ids | Each opens the message page with its own `alarmId`. |

Known platform differences
- iOS: vibration, "slide to stop" text and screen layout are controlled by iOS (AlarmKit).
- iOS: internal alarms are pre-scheduled from the main alarm time (`time + interval * n`), because code cannot run on a locked, un-unlocked stop. Android schedules each repeat `interval` seconds after the slide.
- iOS < 26: no AlarmKit; repeats are time-sensitive notifications with the alarm sound (sound is limited to 30 s by iOS).
