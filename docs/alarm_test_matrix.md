# Alarm behaviour test matrix (Android + iOS must match)

Config under test: `repeatCount = 2`, `repeatIntervalSec = 10` unless noted.
Run every row on a real device with the phone **locked**.

| # | Scenario | Expected |
|---|----------|----------|
| 1 | Alarm fires, user slides to stop and **unlocks** | Alarm stops. No internal alarm is scheduled/rings. Message page opens with the alarm's `alarmId`. |
| 2 | Slide to stop, **cancel** unlock | Alarm stops. Notification "rings again in 5 minutes". Alarm rings again ~5 min later (as many times as the alarm's Ring again / `number_of_ring`). |
| 3 | Row 2, then slide + **unlock** on the repeat | Alarm stops, remaining internal alarms + notifications are cancelled, message page opens. Nothing rings afterwards. |
| 4 | Slide without unlock every time | Rings `1 + repeatCount` times in total, then stops for good. |
| 5 | `repeatCount = 0`, slide without unlock | Alarm stops. No notification, no further ring. |
| 6 | Tap Mission button, do not unlock | Alarm keeps ringing and vibrating until unlocked. |
| 7 | Mission button, then unlock | Alarm stops, message page opens with the `alarmId`. |
| 8 | Custom tune set from Flutter | Custom tune plays (loops) instead of the default. |
| 9 | Button/title texts set from Flutter | Mission button and title show Flutter text. (Slider text: Android only.) |
| 10 | After row 1/3, kill the app, reopen | No audio replays, no alarm repeats, no message page opens by itself. |
| 11 | Two alarms with different ids | Each opens the message page with its own `alarmId`. |
| 12 | Alarm with a chosen alarm sound (`tuneFile`) | That sound rings (loops). Delete/replace the original file afterwards: it still rings (native copy). Missing file: default tune. |
| 13 | Weekly alarm (`ringDays`), slide without unlock, never open the app | It rings again on its next day at that day's time. |
| 14 | Weekly alarm, unlock, finish the message | The ring-again repeats are gone; the alarm still rings on its next day. |
| 15 | Weekly alarm with two times (e.g. Mon 6:30, Sun 8:00) | Each day rings at its own time. |
| 16 | One-off and weekly alarm set, restart the phone (or install an app update) before their time, never open the app | Both still ring at their time. |

Known platform differences
- iOS: vibration, "slide to stop" text and screen layout are controlled by iOS (AlarmKit).
- iOS: internal alarms are pre-scheduled from the main alarm time (`time + interval * n`), because code cannot run on a locked, un-unlocked stop. Android schedules each repeat `interval` seconds after the slide.
- iOS < 26: no AlarmKit; repeats are time-sensitive notifications with the alarm sound (sound is limited to 30 s by iOS).
- iOS < 26: a weekly alarm's main ring repeats by itself, but its ring-again notifications are set only from the next `timeMs`; the app sets them again for the next day when it opens.
