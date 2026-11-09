package com.eala.app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.content.res.AssetFileDescriptor
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import android.graphics.PixelFormat
import android.provider.Settings
import android.view.View
import android.view.WindowManager
import android.os.VibrationEffect
import android.os.Vibrator
import android.util.Log
import androidx.core.app.NotificationCompat

class AlarmAudioService : Service() {
    companion object {
        const val CHANNEL_ID = "alarm_notification_v5"
        const val NOTIFICATION_ID = 1001
        // Separate id so every ring is posted as a NEW notification. Android only fires the
        // full-screen intent (alarm screen over the lock screen) for a new notification,
        // never for an update of the service's existing one.
        const val RING_NOTIFICATION_ID = 1002

        const val ACTION_TRIGGER_ALARM = "com.eala.app.ACTION_TRIGGER_ALARM"
        const val ACTION_STOP_ALARM = "com.eala.app.ACTION_STOP_ALARM"
        const val ACTION_START_CUSTOM_AUDIO = "com.eala.app.ACTION_START_CUSTOM_AUDIO"
        const val ACTION_PAUSE_CUSTOM_AUDIO = "com.eala.app.ACTION_PAUSE_CUSTOM_AUDIO"
        const val ACTION_RESUME_CUSTOM_AUDIO = "com.eala.app.ACTION_RESUME_CUSTOM_AUDIO"
        const val ACTION_SEEK_CUSTOM_AUDIO = "com.eala.app.ACTION_SEEK_CUSTOM_AUDIO"
        const val ACTION_STOP_CUSTOM_AUDIO = "com.eala.app.ACTION_STOP_CUSTOM_AUDIO"
        const val ACTION_DISMISS_ALARM = "com.eala.app.ACTION_DISMISS_ALARM"

        const val EXTRA_ALARM_ID = "extra_alarm_id"
        const val EXTRA_AUDIO_TRACK_ID = "extra_audio_track_id"
        const val EXTRA_SEEK_MS = "extra_seek_ms"
        const val EXTRA_RUN_INDEX = "extra_run_index"

        var currentService: AlarmAudioService? = null
    }

    private var ringtonePlayer: MediaPlayer? = null
    private var customAudioPlayer: MediaPlayer? = null
    private var wakeLock: PowerManager.WakeLock? = null
    private val handler = Handler(Looper.getMainLooper())
    private var isPlayingCustomAudio = false
    private var isRinging = false
    private var currentAlarmId: String = ""
    private var currentAudioTrackId: String = "morning_message"
    private var currentRunIndex: Int = 0
    private var vibrator: Vibrator? = null

    private val tickerRunnable = object : Runnable {
        override fun run() {
            val player = customAudioPlayer
            if (player != null && isPlayingCustomAudio) {
                try {
                    val pos = player.currentPosition
                    val dur = player.duration
                    AlarmPlugin.sendEvent(
                        mapOf(
                            "event" to "positionUpdate",
                            "positionMs" to pos,
                            "durationMs" to dur,
                            "audioTrackId" to currentAudioTrackId
                        )
                    )
                } catch (e: Exception) {
                    Log.e("AlarmAudioService", "Error reading position", e)
                }
                handler.postDelayed(this, 100)
            }
        }
    }

    override fun onCreate() {
        super.onCreate()
        currentService = this
        createNotificationChannel()

        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
        wakeLock = powerManager.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "Eala:AudioWakeLock")
        wakeLock?.acquire(30 * 60 * 1000L /* 30 minutes */)

        // Immediately start foreground with initial notification to satisfy Android foreground service requirement
        val initialNotification = createNotification("Alarm Service Running", "Ready", isRinging = false)
        startForegroundWithCompat(initialNotification)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val action = intent?.action ?: return START_NOT_STICKY

        val alarmId = intent.getStringExtra(EXTRA_ALARM_ID) ?: currentAlarmId
        val audioTrackId = intent.getStringExtra(EXTRA_AUDIO_TRACK_ID) ?: currentAudioTrackId
        currentAlarmId = alarmId
        currentAudioTrackId = audioTrackId
        currentRunIndex = intent.getIntExtra(EXTRA_RUN_INDEX, currentRunIndex)

        when (action) {
            ACTION_TRIGGER_ALARM -> handleTriggerAlarm(alarmId, audioTrackId)
            ACTION_STOP_ALARM -> handleStopAlarmAndPlayCustom(audioTrackId)
            ACTION_DISMISS_ALARM -> handleDismissAlarm()
            ACTION_START_CUSTOM_AUDIO -> startCustomAudio(audioTrackId)
            ACTION_PAUSE_CUSTOM_AUDIO -> pauseCustomAudio()
            ACTION_RESUME_CUSTOM_AUDIO -> resumeCustomAudio()
            ACTION_SEEK_CUSTOM_AUDIO -> {
                val seekMs = intent.getIntExtra(EXTRA_SEEK_MS, 0)
                seekCustomAudio(seekMs)
            }
            ACTION_STOP_CUSTOM_AUDIO -> handleDismissAlarm()
        }

        return START_NOT_STICKY
    }

    /** Drops the foreground notification; the service keeps playing while the app is open. */
    private fun hideServiceNotification() {
        try {
            stopForeground(STOP_FOREGROUND_REMOVE)
            val manager = getSystemService(NotificationManager::class.java)
            manager?.cancel(NOTIFICATION_ID)
            manager?.cancel(RING_NOTIFICATION_ID)
        } catch (e: Exception) {
            Log.w("AlarmAudioService", "Could not hide notification", e)
        }
    }

    private fun startForegroundWithCompat(notification: Notification, id: Int = NOTIFICATION_ID) {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                startForeground(id, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK)
            } else {
                startForeground(id, notification)
            }
        } catch (e: Exception) {
            Log.e("AlarmAudioService", "Error in startForeground", e)
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Alarm Alerts",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "High priority alarm alerts and background synchronized audio playback"
                setSound(null, null) // CRITICAL: Managed by MediaPlayer exclusively to prevent double sound on notification updates
                enableVibration(true)
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
                setShowBadge(true)
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager?.createNotificationChannel(channel)
        }
    }

    private fun createNotification(title: String, text: String, isRinging: Boolean): Notification {
        val openAppIntent = if (isRinging) {
            alarmScreenIntent()
        } else {
            Intent(this, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
                putExtra("route", "/transcript")
                putExtra(EXTRA_AUDIO_TRACK_ID, currentAudioTrackId)
                putExtra(EXTRA_ALARM_ID, currentAlarmId)
            }
        }
        val openPendingIntent = PendingIntent.getActivity(
            this,
            0,
            openAppIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val builder = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(if (isRinging) "Alarm" else title)
            .setContentText(if (isRinging) "Alarm ringing" else text)
            .setSmallIcon(R.drawable.ic_alarm_white)
            .setContentIntent(openPendingIntent)
            .setOngoing(true)
            .setAutoCancel(false)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)

        if (isRinging) {
            // Full-screen intent shows the alarm screen over the lock screen.
            val fullScreenPending = PendingIntent.getActivity(
                this,
                2,
                alarmScreenIntent(),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            builder.setFullScreenIntent(fullScreenPending, true)
        } else if (isPlayingCustomAudio) {
            // Action 1: Pause / Resume
            val pauseIntent = Intent(this, AlarmAudioService::class.java).apply {
                action = ACTION_PAUSE_CUSTOM_AUDIO
            }
            val pausePending = PendingIntent.getService(
                this,
                3,
                pauseIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            builder.addAction(android.R.drawable.ic_media_pause, "Pause", pausePending)

            // Action 2: Dismiss / Stop
            val stopIntent = Intent(this, AlarmAudioService::class.java).apply {
                action = ACTION_DISMISS_ALARM
            }
            val stopPending = PendingIntent.getService(
                this,
                4,
                stopIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            builder.addAction(android.R.drawable.ic_menu_close_clear_cancel, "Dismiss", stopPending)
        } else {
            // Stopped or idle
            val stopIntent = Intent(this, AlarmAudioService::class.java).apply {
                action = ACTION_DISMISS_ALARM
            }
            val stopPending = PendingIntent.getService(
                this,
                5,
                stopIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            builder.addAction(android.R.drawable.ic_menu_close_clear_cancel, "Dismiss", stopPending)
        }

        return builder.build()
    }

    private fun alarmScreenIntent(): Intent =
        Intent(this, AlarmActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                Intent.FLAG_ACTIVITY_NO_USER_ACTION or
                Intent.FLAG_ACTIVITY_SINGLE_TOP or
                Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra(EXTRA_ALARM_ID, currentAlarmId)
            putExtra(EXTRA_AUDIO_TRACK_ID, currentAudioTrackId)
            putExtra(EXTRA_RUN_INDEX, currentRunIndex)
        }

    private var overlayAnchor: View? = null

    /**
     * Opens the alarm screen from the background. Newer Android versions only allow that for
     * an app that currently shows an overlay window, so a 1px invisible overlay is shown for
     * a moment first. The full-screen intent on the notification is the second path.
     */
    private fun launchAlarmScreen() {
        val intent = alarmScreenIntent()
        if (Settings.canDrawOverlays(this)) {
            try {
                val wm = getSystemService(Context.WINDOW_SERVICE) as WindowManager
                val anchor = View(this)
                @Suppress("DEPRECATION")
                val params = WindowManager.LayoutParams(
                    1, 1,
                    WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
                    WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                        WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE or
                        WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED,
                    PixelFormat.TRANSLUCENT
                )
                removeOverlayAnchor()
                wm.addView(anchor, params)
                overlayAnchor = anchor
                handler.postDelayed({ removeOverlayAnchor() }, 4000)
            } catch (e: Exception) {
                Log.w("AlarmAudioService", "Overlay anchor failed", e)
            }
        }
        handler.postDelayed({
            try {
                startActivity(intent)
                Log.d("AlarmAudioService", "Alarm screen start requested")
            } catch (e: Exception) {
                Log.w("AlarmAudioService", "Could not start alarm screen directly", e)
            }
        }, 200)
    }

    private fun removeOverlayAnchor() {
        val v = overlayAnchor ?: return
        overlayAnchor = null
        try {
            (getSystemService(Context.WINDOW_SERVICE) as WindowManager).removeView(v)
        } catch (_: Exception) {}
    }

    private fun handleTriggerAlarm(alarmId: String, audioTrackId: String) {
        isRinging = true
        isPlayingCustomAudio = false
        val config = AlarmConfigStore.load(this, alarmId)
        val notification = createNotification(
            config?.title ?: config?.missionName ?: "Alarm",
            "Alarm ringing",
            isRinging = true
        )
        val manager = getSystemService(NotificationManager::class.java)
        // Drop any previous ring so this one is posted fresh (required for the full-screen intent).
        manager?.cancel(RING_NOTIFICATION_ID)
        startForegroundWithCompat(notification, RING_NOTIFICATION_ID)
        manager?.cancel(NOTIFICATION_ID)
        playRingtone(config?.tuneFile, config?.tuneAsset)
        startVibration()

        launchAlarmScreen()
    }

    private fun playRingtone(tuneFile: String? = null, tuneAsset: String? = null) {
        stopRingtone()
        val alarmAttributes = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_ALARM)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()

        // 1) The alarm's own sound file (a downloaded alarm sound chosen in Flutter)
        if (!tuneFile.isNullOrEmpty() && java.io.File(tuneFile).isFile) {
            try {
                ringtonePlayer = MediaPlayer().apply {
                    setDataSource(tuneFile)
                    setAudioAttributes(alarmAttributes)
                    isLooping = true
                    prepare()
                    start()
                }
                return
            } catch (e: Exception) {
                Log.e("AlarmAudioService", "Alarm sound file failed, using the next tune", e)
                ringtonePlayer?.release()
                ringtonePlayer = null
            }
        }

        // 2) Custom tune asset chosen in Flutter
        if (!tuneAsset.isNullOrEmpty()) {
            val afd = findAssetFileDescriptor(tuneAsset)
            if (afd != null) {
                try {
                    ringtonePlayer = MediaPlayer().apply {
                        setDataSource(afd.fileDescriptor, afd.startOffset, afd.length)
                        afd.close()
                        setAudioAttributes(alarmAttributes)
                        isLooping = true
                        prepare()
                        start()
                    }
                    return
                } catch (e: Exception) {
                    Log.e("AlarmAudioService", "Custom tune failed, using default", e)
                    ringtonePlayer?.release()
                    ringtonePlayer = null
                }
            }
        }

        // 3) System default alarm sound
        try {
            val alertUri: Uri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
                ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)

            ringtonePlayer = MediaPlayer().apply {
                setDataSource(applicationContext, alertUri)
                setAudioAttributes(alarmAttributes)
                isLooping = true
                prepare()
                start()
            }
        } catch (e: Exception) {
            Log.e("AlarmAudioService", "Error playing ringtone", e)
        }
    }

    /** Strong repeating vibration (full amplitude) for as long as the alarm rings. */
    private fun startVibration() {
        stopVibration()
        val v = getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator ?: return
        if (!v.hasVibrator()) return
        vibrator = v
        val timings = longArrayOf(0, 900, 300)
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val effect = VibrationEffect.createWaveform(timings, intArrayOf(0, 255, 0), 0)
                @Suppress("DEPRECATION")
                v.vibrate(
                    effect,
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build()
                )
            } else {
                @Suppress("DEPRECATION")
                v.vibrate(timings, 0)
            }
        } catch (e: Exception) {
            Log.e("AlarmAudioService", "Vibration failed", e)
        }
    }

    private fun stopVibration() {
        try {
            vibrator?.cancel()
        } catch (_: Exception) {}
        vibrator = null
    }

    fun isRingingNow(): Boolean {
        return isRinging && ringtonePlayer?.isPlaying == true
    }

    private fun stopRingtone() {
        isRinging = false
        stopVibration()
        try {
            ringtonePlayer?.stop()
            ringtonePlayer?.release()
        } catch (e: Exception) {
            Log.e("AlarmAudioService", "Error stopping ringtone", e)
        }
        ringtonePlayer = null
    }

    private fun handleStopAlarmAndPlayCustom(audioTrackId: String) {
        AlarmPlugin.clearEvents("alarmRinging")
        stopRingtone()
        startCustomAudio(audioTrackId)
    }

    fun handleDismissAlarm() {
        AlarmPlugin.clearEvents("alarmRinging")
        stopRingtone()
        stopCustomAudio()
        try {
            if (wakeLock?.isHeld == true) {
                wakeLock?.release()
            }
        } catch (_: Exception) {}

        stopForeground(STOP_FOREGROUND_REMOVE)
        val manager = getSystemService(NotificationManager::class.java)
        manager?.cancel(NOTIFICATION_ID)
        manager?.cancel(RING_NOTIFICATION_ID)
        stopSelf()

        AlarmPlugin.sendEvent(
            mapOf(
                "event" to "alarmDismissed",
                "alarmId" to currentAlarmId
            )
        )
    }

    fun startCustomAudio(audioTrackId: String) {
        AlarmPlugin.clearEvents("alarmRinging")
        stopRingtone()
        stopCustomAudio()

        try {
            val afd: AssetFileDescriptor = findAssetFileDescriptor("assets/audio/demo_alarm_message.mp3")
                ?: findAssetFileDescriptor("demo_alarm_message.mp3")
                ?: assets.openFd("flutter_assets/assets/audio/demo_alarm_message.mp3")

            customAudioPlayer = MediaPlayer().apply {
                setDataSource(afd.fileDescriptor, afd.startOffset, afd.length)
                afd.close()
                setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_MEDIA)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
                        .build()
                )
                setOnCompletionListener {
                    isPlayingCustomAudio = false
                    handler.removeCallbacks(tickerRunnable)
                    AlarmPlugin.sendEvent(
                        mapOf(
                            "event" to "customAudioCompleted",
                            "audioTrackId" to currentAudioTrackId
                        )
                    )
                    handleDismissAlarm()
                }
                prepare()
                start()
            }

            isPlayingCustomAudio = true
            val dur = customAudioPlayer?.duration ?: 0
            // The message page has its own controls: no notification while the message plays.
            hideServiceNotification()

            AlarmPlugin.sendEvent(
                mapOf(
                    "event" to "customAudioStarted",
                    "audioTrackId" to currentAudioTrackId,
                    "durationMs" to dur
                )
            )

            handler.removeCallbacks(tickerRunnable)
            handler.post(tickerRunnable)
        } catch (e: Exception) {
            Log.e("AlarmAudioService", "Error starting custom audio", e)
            AlarmPlugin.sendEvent(mapOf("event" to "error", "message" to (e.localizedMessage ?: "Audio error")))
        }
    }

    private fun findAssetFileDescriptor(path: String): AssetFileDescriptor? {
        val candidates = listOf(
            path,
            "flutter_assets/$path",
            "assets/$path"
        )
        for (c in candidates) {
            try {
                return assets.openFd(c)
            } catch (_: Exception) {}
        }
        return null
    }

    fun pauseCustomAudio() {
        if (customAudioPlayer?.isPlaying == true) {
            customAudioPlayer?.pause()
            isPlayingCustomAudio = false

            AlarmPlugin.sendEvent(
                mapOf(
                    "event" to "customAudioPaused",
                    "positionMs" to (customAudioPlayer?.currentPosition ?: 0),
                    "audioTrackId" to currentAudioTrackId
                )
            )
        }
    }

    fun resumeCustomAudio() {
        if (customAudioPlayer != null && !isPlayingCustomAudio) {
            customAudioPlayer?.start()
            isPlayingCustomAudio = true
            handler.post(tickerRunnable)

            AlarmPlugin.sendEvent(
                mapOf(
                    "event" to "customAudioResumed",
                    "positionMs" to (customAudioPlayer?.currentPosition ?: 0),
                    "audioTrackId" to currentAudioTrackId
                )
            )
        }
    }

    fun seekCustomAudio(positionMs: Int) {
        customAudioPlayer?.seekTo(positionMs)
        AlarmPlugin.sendEvent(
            mapOf(
                "event" to "positionUpdate",
                "positionMs" to positionMs,
                "durationMs" to (customAudioPlayer?.duration ?: 0),
                "audioTrackId" to currentAudioTrackId
            )
        )
    }

    fun getPlaybackState(): Map<String, Any> {
        val player = customAudioPlayer
        val isRingingNow = isRinging || ringtonePlayer?.isPlaying == true
        val isCustomPlaying = isPlayingCustomAudio && player?.isPlaying == true
        val state = when {
            isRingingNow -> "ringing"
            isCustomPlaying -> "customAudioPlaying"
            player != null && !isCustomPlaying -> "customAudioPaused"
            else -> "idle"
        }
        return mapOf(
            "state" to state,
            "positionMs" to (player?.currentPosition ?: 0),
            "durationMs" to (player?.duration ?: 0),
            "audioTrackId" to currentAudioTrackId,
            "alarmId" to currentAlarmId
        )
    }

    private fun stopCustomAudio() {
        handler.removeCallbacks(tickerRunnable)
        isPlayingCustomAudio = false
        try {
            customAudioPlayer?.stop()
            customAudioPlayer?.release()
        } catch (_: Exception) {}
        customAudioPlayer = null
    }

    fun stopAll() {
        handleDismissAlarm()
    }

    override fun onDestroy() {
        super.onDestroy()
        removeOverlayAnchor()
        currentService = null
        stopAll()
    }

    override fun onBind(intent: Intent?): IBinder? = null
}
