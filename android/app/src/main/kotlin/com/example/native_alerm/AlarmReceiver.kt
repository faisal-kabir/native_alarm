package com.example.native_alerm

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.PowerManager
import android.util.Log

class AlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val alarmId = intent.getStringExtra(AlarmAudioService.EXTRA_ALARM_ID) ?: "default_alarm"
        val audioTrackId = intent.getStringExtra(AlarmAudioService.EXTRA_AUDIO_TRACK_ID) ?: "morning_message"
        Log.d("AlarmReceiver", "Alarm triggered for ID: $alarmId, Track: $audioTrackId")

        // 1. Wake the physical screen from black standby
        try {
            val powerManager = context.getSystemService(Context.POWER_SERVICE) as PowerManager
            @Suppress("DEPRECATION")
            val screenWakeLock = powerManager.newWakeLock(
                PowerManager.SCREEN_BRIGHT_WAKE_LOCK or
                PowerManager.ACQUIRE_CAUSES_WAKEUP or
                PowerManager.ON_AFTER_RELEASE,
                "NativeAlarm:ScreenWakeLock"
            )
            screenWakeLock.acquire(15000L) // 15 seconds
        } catch (e: Exception) {
            Log.e("AlarmReceiver", "Error acquiring screen wake lock", e)
        }

        // 2. Start the foreground audio service (plays ringtone and posts notification)
        val serviceIntent = Intent(context, AlarmAudioService::class.java).apply {
            action = AlarmAudioService.ACTION_TRIGGER_ALARM
            putExtra(AlarmAudioService.EXTRA_ALARM_ID, alarmId)
            putExtra(AlarmAudioService.EXTRA_AUDIO_TRACK_ID, audioTrackId)
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            context.startForegroundService(serviceIntent)
        } else {
            context.startService(serviceIntent)
        }
    }
}
