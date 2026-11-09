package com.eala.app

import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import androidx.core.app.NotificationCompat

/**
 * Schedules the main alarm and the internal repeat alarms (run index 1..N).
 * Run index 0 is the main alarm.
 */
object AlarmScheduler {
    private const val TAG = "AlarmScheduler"
    private const val INFO_CHANNEL_ID = "alarm_repeat_info"

    private fun requestCode(alarmId: String, runIndex: Int) = alarmId.hashCode() * 31 + runIndex

    private fun pendingIntent(context: Context, alarmId: String, runIndex: Int): PendingIntent {
        val intent = Intent(context, AlarmReceiver::class.java).apply {
            action = AlarmAudioService.ACTION_TRIGGER_ALARM
            putExtra(AlarmAudioService.EXTRA_ALARM_ID, alarmId)
            putExtra(AlarmAudioService.EXTRA_RUN_INDEX, runIndex)
        }
        val flags = PendingIntent.FLAG_UPDATE_CURRENT or
            (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0)
        return PendingIntent.getBroadcast(context, requestCode(alarmId, runIndex), intent, flags)
    }

    fun canScheduleExact(context: Context): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return true
        return (context.getSystemService(Context.ALARM_SERVICE) as AlarmManager).canScheduleExactAlarms()
    }

    /** Schedules the main alarm. Replaces and cleans up anything scheduled before for this id. */
    fun schedule(context: Context, config: AlarmConfig, timeMs: Long) {
        cancelAll(context, config.alarmId)
        AlarmConfigStore.save(context, config.copy(ringTimeMs = timeMs))
        setExact(context, config.alarmId, 0, timeMs)
        Log.d(TAG, "Main alarm scheduled: ${config.alarmId} at $timeMs")
    }

    /**
     * A weekly alarm's main alarm just rang: set its next day now, so it rings next week even
     * if the app is never opened (iOS repeats weekly alarms by itself). Leaves the repeats alone.
     */
    fun scheduleNextWeeklyRing(context: Context, config: AlarmConfig) {
        val next = config.nextWeeklyRing(System.currentTimeMillis()) ?: return
        setExact(context, config.alarmId, 0, next)
        Log.d(TAG, "Weekly alarm ${config.alarmId} set again for $next")
    }

    /**
     * After a reboot or app update (AlarmManager forgets its alarms, see [AlarmBootReceiver]):
     * sets the main alarm again — a weekly alarm on its next day, a one-off alarm only if its
     * time is still ahead. Ring-again repeats that were waiting are not set again.
     */
    fun restore(context: Context, config: AlarmConfig) {
        val now = System.currentTimeMillis()
        val next = config.nextWeeklyRing(now) ?: config.ringTimeMs?.takeIf { it > now } ?: return
        setExact(context, config.alarmId, 0, next)
        Log.d(TAG, "Main alarm ${config.alarmId} set again for $next")
    }

    /** Schedules internal repeat number [runIndex] (1-based) and shows its notification. */
    fun scheduleInternal(context: Context, config: AlarmConfig, runIndex: Int) {
        val delayMs = config.safeIntervalSec * 1000L
        setExact(context, config.alarmId, runIndex, System.currentTimeMillis() + delayMs)
        showRepeatNotification(context, config, runIndex)
        Log.d(TAG, "Internal alarm $runIndex/${config.safeRepeatCount} scheduled for ${config.alarmId}")
    }

    private fun setExact(context: Context, alarmId: String, runIndex: Int, timeMs: Long) {
        val alarmMgr = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val pending = pendingIntent(context, alarmId, runIndex)
        try {
            val showIntent = PendingIntent.getActivity(
                context, 0, Intent(context, MainActivity::class.java),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            // setAlarmClock is exempt from Doze and from battery optimisation.
            alarmMgr.setAlarmClock(AlarmManager.AlarmClockInfo(timeMs, showIntent), pending)
        } catch (e: SecurityException) {
            Log.e(TAG, "Exact alarm not permitted, falling back", e)
            alarmMgr.set(AlarmManager.RTC_WAKEUP, timeMs, pending)
        }
    }

    /** Cancels the main alarm, every internal repeat and their notifications. */
    fun cancelAll(context: Context, alarmId: String) {
        val alarmMgr = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        for (index in 0..AlarmConfig.MAX_REPEAT_COUNT) {
            alarmMgr.cancel(pendingIntent(context, alarmId, index))
        }
        cancelRepeatNotification(context, alarmId)
    }

    /** Cancels only the internal repeats (main alarm already fired). */
    fun cancelInternal(context: Context, alarmId: String) {
        val alarmMgr = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        for (index in 1..AlarmConfig.MAX_REPEAT_COUNT) {
            alarmMgr.cancel(pendingIntent(context, alarmId, index))
        }
        cancelRepeatNotification(context, alarmId)
    }

    private fun notificationId(alarmId: String) = 2000 + (alarmId.hashCode() and 0xFFF)

    private fun showRepeatNotification(context: Context, config: AlarmConfig, runIndex: Int) {
        val manager = context.getSystemService(NotificationManager::class.java) ?: return
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            manager.createNotificationChannel(
                NotificationChannel(INFO_CHANNEL_ID, "Alarm repeats", NotificationManager.IMPORTANCE_HIGH),
            )
        }
        val openApp = PendingIntent.getActivity(
            context, 0, Intent(context, MainActivity::class.java),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val notification = NotificationCompat.Builder(context, INFO_CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_alarm_white)
            .setContentTitle("Alarm rings again in ${config.safeIntervalSec} seconds")
            .setContentText("Repeat $runIndex of ${config.safeRepeatCount}. Unlock your phone to stop it.")
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setOnlyAlertOnce(true)
            .setContentIntent(openApp)
            .build()
        try {
            manager.notify(notificationId(config.alarmId), notification)
        } catch (e: SecurityException) {
            Log.w(TAG, "Notification permission missing", e)
        }
    }

    private fun cancelRepeatNotification(context: Context, alarmId: String) {
        context.getSystemService(NotificationManager::class.java)?.cancel(notificationId(alarmId))
    }
}

/** What happens after the user acts on the alarm screen. Same rules as iOS. */
object AlarmFlow {
    /** The user got past the lock screen: stop everything and open the message page. */
    fun onUnlocked(context: Context, alarmId: String) {
        AlarmScheduler.cancelInternal(context, alarmId)
        AlarmLaunchState.pendingAlarmId = alarmId
        val config = AlarmConfigStore.load(context, alarmId)
        val open = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra("action", "stop_alarm_and_open_transcript")
            putExtra(AlarmAudioService.EXTRA_ALARM_ID, alarmId)
            putExtra(AlarmAudioService.EXTRA_AUDIO_TRACK_ID, config?.audioTrackId ?: "morning_message")
        }
        context.startActivity(open)
    }

    /** Slide to stop, but no unlock: ring again after the interval while repeats remain. */
    fun onStoppedWithoutUnlock(context: Context, alarmId: String, runIndex: Int) {
        val config = AlarmConfigStore.load(context, alarmId) ?: return
        if (runIndex < config.safeRepeatCount) {
            AlarmScheduler.scheduleInternal(context, config, runIndex + 1)
        }
    }
}
