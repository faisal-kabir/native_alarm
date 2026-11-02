package com.eala.app

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
    private val METHOD_CHANNEL = "com.eala.app/alarm"
    private val EVENT_CHANNEL = "com.eala.app/alarm_events"
    private val LEGACY_METHOD_CHANNEL = "com.native_alarm/alarm"
    private val LEGACY_EVENT_CHANNEL = "com.native_alarm/alarm_events"

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
                    "alarmId" to alarmId,
                    "audioTrackId" to audioTrackId
                )
            )
            intent.removeExtra("action")
        } else if (route == "/alarm" || action == "alarm_ringing") {
            // The native AlarmActivity shows the ringing alarm; nothing to do in Flutter.
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

    /** What the alarm screen needs to appear over the lock screen and over other apps. */
    private fun alarmScreenPermissions(): Map<String, Boolean> {
        val nm = getSystemService(Context.NOTIFICATION_SERVICE) as android.app.NotificationManager
        return mapOf(
            "notifications" to hasNotificationPermission(),
            "fullScreenIntent" to fullScreenIntentAllowed(nm),
            "overlay" to overlayAllowed(),
            "exactAlarm" to AlarmScheduler.canScheduleExact(this),
        )
    }

    /**
     * On Android 14+ the manifest grant alone is not enough: some devices keep the app-op at
     * "default" (not confirmed by the user) and then silently refuse full-screen intents.
     * Only an explicit "allowed" counts.
     */
    private fun fullScreenIntentAllowed(nm: android.app.NotificationManager): Boolean {
        if (Build.VERSION.SDK_INT < 34) return true
        if (!nm.canUseFullScreenIntent()) return false
        val appOps = getSystemService(Context.APP_OPS_SERVICE) as android.app.AppOpsManager
        val mode = appOps.unsafeCheckOpNoThrow(
            "android:use_full_screen_intent",
            android.os.Process.myUid(),
            packageName,
        )
        return mode == android.app.AppOpsManager.MODE_ALLOWED
    }

    private fun overlayAllowed(): Boolean {
        if (android.provider.Settings.canDrawOverlays(this)) return true
        // Some vendor builds report false here although the user allowed it in settings.
        val appOps = getSystemService(Context.APP_OPS_SERVICE) as android.app.AppOpsManager
        val mode = appOps.unsafeCheckOpNoThrow(
            "android:system_alert_window",
            android.os.Process.myUid(),
            packageName,
        )
        return mode == android.app.AppOpsManager.MODE_ALLOWED
    }

    /** Opens the settings screen of the first missing permission (one per call). */
    private fun requestMissingAlarmScreenPermission() {
        val p = alarmScreenPermissions()
        val uri = android.net.Uri.parse("package:$packageName")
        try {
            when {
                p["notifications"] == false -> requestNotificationPermission()
                p["fullScreenIntent"] == false ->
                    startActivity(Intent(android.provider.Settings.ACTION_MANAGE_APP_USE_FULL_SCREEN_INTENT, uri))
                p["overlay"] == false ->
                    startActivity(Intent(android.provider.Settings.ACTION_MANAGE_OVERLAY_PERMISSION, uri))
                p["exactAlarm"] == false && Build.VERSION.SDK_INT >= Build.VERSION_CODES.S ->
                    startActivity(Intent(android.provider.Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM, uri))
            }
        } catch (e: Exception) {
            Log.w("MainActivity", "Could not open permission settings", e)
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

        val streamHandler = object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                AlarmPlugin.eventSink = events
                // Check if intent triggered while engine was initializing
                intent?.let { handleIntent(it) }
            }

            override fun onCancel(arguments: Any?) {
                AlarmPlugin.eventSink = null
            }
        }
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL).setStreamHandler(streamHandler)
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, LEGACY_EVENT_CHANNEL).setStreamHandler(streamHandler)

        val methodHandler: MethodChannel.MethodCallHandler = MethodChannel.MethodCallHandler { call, result ->
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
                    val config = AlarmConfig(
                        alarmId = alarmId,
                        audioTrackId = call.argument<String>("audioTrackId") ?: "morning_message",
                        missionName = call.argument<String>("missionName")?.takeIf { it.isNotEmpty() }
                            ?: "Start Morning Mission",
                        title = call.argument<String>("title")?.takeIf { it.isNotEmpty() },
                        subtitle = call.argument<String>("subtitle")?.takeIf { it.isNotEmpty() },
                        stopHintText = call.argument<String>("stopHintText")?.takeIf { it.isNotEmpty() }
                            ?: "slide to stop",
                        repeatCount = call.argument<Number>("repeatCount")?.toInt() ?: 0,
                        repeatIntervalSec = call.argument<Number>("repeatIntervalSec")?.toInt() ?: 10,
                        tuneAsset = call.argument<String>("tuneAsset")?.takeIf { it.isNotEmpty() },
                    )
                    scheduleAlarm(config, timeMs)
                    result.success(null)
                }
                "cancelAlarm" -> {
                    val alarmId = call.argument<String>("alarmId") ?: "default"
                    cancelAlarm(alarmId)
                    result.success(null)
                }
                "getAlarmScreenPermissions" -> {
                    result.success(alarmScreenPermissions())
                }
                "requestAlarmScreenPermissions" -> {
                    requestMissingAlarmScreenPermission()
                    result.success(null)
                }
                "consumeAlarmLaunch" -> {
                    val launchAlarmId = AlarmLaunchState.consume()
                    result.success(
                        mapOf(
                            "launchedFromAlarm" to (launchAlarmId != null),
                            "alarmId" to (launchAlarmId ?: ""),
                        )
                    )
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
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL).setMethodCallHandler(methodHandler)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, LEGACY_METHOD_CHANNEL).setMethodCallHandler(methodHandler)
    }

    private fun scheduleAlarm(config: AlarmConfig, timeMs: Long) {
        AlarmScheduler.schedule(this, config, timeMs)
        AlarmPlugin.sendEvent(mapOf("event" to "alarmScheduled", "alarmId" to config.alarmId, "timeMs" to timeMs))
    }

    private fun cancelAlarm(alarmId: String) {
        AlarmScheduler.cancelAll(this, alarmId)
        AlarmConfigStore.remove(this, alarmId)
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
