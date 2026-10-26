package com.example.native_alerm

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val METHOD_CHANNEL = "com.native_alarm/alarm"
    private val EVENT_CHANNEL = "com.native_alarm/alarm_events"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        unlockAndShowIfLocked()
        requestNotificationPermission()
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleIntent(intent)
    }

    private fun unlockAndShowIfLocked() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
            val km = getSystemService(Context.KEYGUARD_SERVICE) as? android.app.KeyguardManager
            km?.requestDismissKeyguard(this, null)
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(
                android.view.WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                android.view.WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                android.view.WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD
            )
        }
    }

    private fun handleIntent(intent: Intent?) {
        if (intent == null) return
        val action = intent.getStringExtra("action")
        val route = intent.getStringExtra("route")
        val audioTrackId = intent.getStringExtra(AlarmAudioService.EXTRA_AUDIO_TRACK_ID) ?: "morning_message"
        val alarmId = intent.getStringExtra(AlarmAudioService.EXTRA_ALARM_ID) ?: ""

        if (action == "stop_alarm_and_open_transcript") {
            AlarmPlugin.clearEvents("alarmRinging")
            unlockAndShowIfLocked()
            stopAlarmAndStartAudio(audioTrackId)
            AlarmPlugin.sendEvent(
                mapOf(
                    "event" to "openTranscript",
                    "audioTrackId" to audioTrackId
                )
            )
            intent.removeExtra("action")
        } else if (route == "/alarm" || action == "alarm_ringing") {
            val service = AlarmAudioService.currentService
            val isRingingNow = service?.isRingingNow() ?: false
            if (isRingingNow) {
                unlockAndShowIfLocked()
                AlarmPlugin.sendEvent(
                    mapOf(
                        "event" to "alarmRinging",
                        "alarmId" to alarmId,
                        "audioTrackId" to audioTrackId
                    )
                )
            }
            intent.removeExtra("route")
            intent.removeExtra("action")
        } else if (route == "/transcript") {
            unlockAndShowIfLocked()
            AlarmPlugin.sendEvent(
                mapOf(
                    "event" to "openTranscript",
                    "audioTrackId" to audioTrackId
                )
            )
            intent.removeExtra("route")
        }
    }

    private fun requestNotificationPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            if (checkSelfPermission(android.Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) {
                requestPermissions(arrayOf(android.Manifest.permission.POST_NOTIFICATIONS), 101)
            }
        }
        if (Build.VERSION.SDK_INT >= 34) {
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as? android.app.NotificationManager
            if (notificationManager?.canUseFullScreenIntent() == false) {
                try {
                    val intent = Intent(android.provider.Settings.ACTION_MANAGE_APP_USE_FULL_SCREEN_INTENT).apply {
                        data = android.net.Uri.parse("package:$packageName")
                    }
                    startActivity(intent)
                } catch (_: Exception) {}
            }
        }
    }

    private fun hasNotificationPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            checkSelfPermission(android.Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED
        } else {
            true
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    AlarmPlugin.eventSink = events
                    // Check if intent triggered while engine was initializing
                    intent?.let { handleIntent(it) }
                }

                override fun onCancel(arguments: Any?) {
                    AlarmPlugin.eventSink = null
                }
            }
        )

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "requestNotificationPermission" -> {
                    requestNotificationPermission()
                    result.success(null)
                }
                "hasNotificationPermission" -> {
                    result.success(hasNotificationPermission())
                }
                "scheduleAlarm" -> {
                    val alarmId = call.argument<String>("alarmId") ?: "default"
                    val timeMs = (call.argument<Number>("timeMs"))?.toLong() ?: (System.currentTimeMillis() + 5000)
                    val audioTrackId = call.argument<String>("audioTrackId") ?: "morning_message"
                    scheduleAlarm(alarmId, timeMs, audioTrackId)
                    result.success(null)
                }
                "cancelAlarm" -> {
                    val alarmId = call.argument<String>("alarmId") ?: "default"
                    cancelAlarm(alarmId)
                    result.success(null)
                }
                "dismissAlarm" -> {
                    dismissAlarm()
                    result.success(null)
                }
                "stopAlarm" -> {
                    val audioTrackId = call.argument<String>("audioTrackId") ?: "morning_message"
                    stopAlarmAndStartAudio(audioTrackId)
                    result.success(null)
                }
                "startCustomAudio" -> {
                    val audioTrackId = call.argument<String>("audioId")
                        ?: call.argument<String>("audioTrackId")
                        ?: "morning_message"
                    startCustomAudio(audioTrackId)
                    result.success(null)
                }
                "pauseCustomAudio" -> {
                    pauseCustomAudio()
                    result.success(null)
                }
                "resumeCustomAudio" -> {
                    resumeCustomAudio()
                    result.success(null)
                }
                "seekCustomAudio" -> {
                    val pos = (call.argument<Number>("positionMs"))?.toInt() ?: 0
                    seekCustomAudio(pos)
                    result.success(null)
                }
                "stopCustomAudio" -> {
                    dismissAlarm()
                    result.success(null)
                }
                "getPlaybackState" -> {
                    val state = AlarmAudioService.currentService?.getPlaybackState()
                        ?: mapOf(
                            "state" to "idle",
                            "positionMs" to 0,
                            "durationMs" to 0,
                            "audioTrackId" to "",
                            "alarmId" to ""
                        )
                    result.success(state)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun scheduleAlarm(alarmId: String, timeMs: Long, audioTrackId: String) {
        val alarmMgr = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(this, AlarmReceiver::class.java).apply {
            action = "com.native_alarm.ALARM_TRIGGER"
            putExtra(AlarmAudioService.EXTRA_ALARM_ID, alarmId)
            putExtra(AlarmAudioService.EXTRA_AUDIO_TRACK_ID, audioTrackId)
        }
        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
        val pendingIntent = PendingIntent.getBroadcast(this, alarmId.hashCode(), intent, flags)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            alarmMgr.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, timeMs, pendingIntent)
        } else {
            alarmMgr.setExact(AlarmManager.RTC_WAKEUP, timeMs, pendingIntent)
        }

        Log.d("MainActivity", "Alarm scheduled: $alarmId at $timeMs")
        AlarmPlugin.sendEvent(mapOf("event" to "alarmScheduled", "alarmId" to alarmId, "timeMs" to timeMs))
    }

    private fun cancelAlarm(alarmId: String) {
        val alarmMgr = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(this, AlarmReceiver::class.java)
        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
        val pendingIntent = PendingIntent.getBroadcast(this, alarmId.hashCode(), intent, flags)
        alarmMgr.cancel(pendingIntent)
        Log.d("MainActivity", "Alarm cancelled: $alarmId")
        AlarmPlugin.sendEvent(mapOf("event" to "alarmCancelled", "alarmId" to alarmId))
    }

    private fun dismissAlarm() {
        val service = AlarmAudioService.currentService
        if (service != null) {
            service.handleDismissAlarm()
        } else {
            val serviceIntent = Intent(this, AlarmAudioService::class.java).apply {
                action = AlarmAudioService.ACTION_DISMISS_ALARM
            }
            startService(serviceIntent)
        }
    }

    private fun stopAlarmAndStartAudio(audioTrackId: String) {
        val service = AlarmAudioService.currentService
        if (service != null) {
            service.startCustomAudio(audioTrackId)
        } else {
            val serviceIntent = Intent(this, AlarmAudioService::class.java).apply {
                action = AlarmAudioService.ACTION_STOP_ALARM
                putExtra(AlarmAudioService.EXTRA_AUDIO_TRACK_ID, audioTrackId)
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                startForegroundService(serviceIntent)
            } else {
                startService(serviceIntent)
            }
        }
    }

    private fun startCustomAudio(audioTrackId: String) {
        val serviceIntent = Intent(this, AlarmAudioService::class.java).apply {
            action = AlarmAudioService.ACTION_START_CUSTOM_AUDIO
            putExtra(AlarmAudioService.EXTRA_AUDIO_TRACK_ID, audioTrackId)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(serviceIntent)
        } else {
            startService(serviceIntent)
        }
    }

    private fun pauseCustomAudio() {
        val service = AlarmAudioService.currentService
        service?.pauseCustomAudio()
    }

    private fun resumeCustomAudio() {
        val service = AlarmAudioService.currentService
        service?.resumeCustomAudio()
    }

    private fun seekCustomAudio(positionMs: Int) {
        val service = AlarmAudioService.currentService
        service?.seekCustomAudio(positionMs)
    }
}
