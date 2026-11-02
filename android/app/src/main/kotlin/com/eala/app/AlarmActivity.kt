package com.eala.app

import android.app.Activity
import android.app.KeyguardManager
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.Bundle
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextClock
import android.widget.TextView

/**
 * Full-screen alarm screen shown over the lock screen. Mirrors the iOS AlarmKit screen:
 * title, big clock, app name, orange mission button and a "slide to stop" slider.
 *
 * - Slide to stop: ask the user to unlock. Unlocked -> stop everything and open the message
 *   page. Not unlocked -> stop ringing and schedule the next internal alarm (if any left).
 * - Mission button: ask the user to unlock. The alarm keeps ringing until they do.
 */
class AlarmActivity : Activity() {
    private lateinit var alarmId: String
    private var runIndex = 0
    private lateinit var config: AlarmConfig
    private var slider: SlideToStopView? = null
    private var finishedFlow = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        showOverLockScreen()

        alarmId = intent.getStringExtra(AlarmAudioService.EXTRA_ALARM_ID) ?: ""
        runIndex = intent.getIntExtra(AlarmAudioService.EXTRA_RUN_INDEX, 0)
        config = AlarmConfigStore.load(this, alarmId) ?: AlarmConfig(alarmId = alarmId)

        setContentView(buildContent())
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        // A new ring (internal alarm) reuses this screen.
        alarmId = intent.getStringExtra(AlarmAudioService.EXTRA_ALARM_ID) ?: alarmId
        runIndex = intent.getIntExtra(AlarmAudioService.EXTRA_RUN_INDEX, 0)
        finishedFlow = false
        slider?.reset()
    }

    private fun showOverLockScreen() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                    WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON,
            )
        }
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
    }

    private fun dp(value: Int) = (value * resources.displayMetrics.density).toInt()

    private fun buildContent(): View {
        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setBackgroundColor(Color.BLACK)
            setPadding(dp(20), dp(96), dp(20), dp(32))
        }

        // Title row: alarm icon + title
        val titleRow = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
        }
        titleRow.addView(
            ImageView(this).apply {
                setImageResource(R.drawable.ic_alarm_white)
                setColorFilter(Color.parseColor("#8E8E93"))
            },
            LinearLayout.LayoutParams(dp(40), dp(40)),
        )
        titleRow.addView(
            TextView(this).apply {
                text = config.title ?: config.missionName
                setTextColor(Color.parseColor("#8E8E93"))
                textSize = 28f
                typeface = Typeface.create("sans-serif-medium", Typeface.NORMAL)
                maxLines = 1
            },
            LinearLayout.LayoutParams(LinearLayout.LayoutParams.WRAP_CONTENT, LinearLayout.LayoutParams.WRAP_CONTENT)
                .apply { leftMargin = dp(12) },
        )
        root.addView(titleRow)

        // Big clock
        root.addView(
            TextClock(this).apply {
                format12Hour = "h:mm"
                format24Hour = "H:mm"
                setTextColor(Color.WHITE)
                textSize = 120f
                typeface = Typeface.create("sans-serif", Typeface.BOLD)
                gravity = Gravity.CENTER
                includeFontPadding = false
            },
            LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT)
                .apply { topMargin = dp(24) },
        )

        // App name
        root.addView(
            TextView(this).apply {
                text = config.subtitle ?: applicationInfo.loadLabel(packageManager).toString()
                setTextColor(Color.parseColor("#8E8E93"))
                textSize = 18f
                gravity = Gravity.CENTER
            },
            LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT)
                .apply { topMargin = dp(12) },
        )

        // Spacer
        root.addView(View(this), LinearLayout.LayoutParams(0, 0, 1f))

        // Mission button (orange pill)
        root.addView(
            Button(this).apply {
                text = config.missionName
                isAllCaps = false
                setTextColor(Color.WHITE)
                textSize = 22f
                typeface = Typeface.create("sans-serif-medium", Typeface.BOLD)
                background = GradientDrawable().apply {
                    setColor(Color.parseColor("#FF9500"))
                    cornerRadius = dp(40).toFloat()
                }
                stateListAnimator = null
                setOnClickListener { requestUnlock(stopRingingIfNotUnlocked = false) }
            },
            LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, dp(80)),
        )

        // Slide to stop
        val slide = SlideToStopView(this, config.stopHintText) {
            requestUnlock(stopRingingIfNotUnlocked = true)
        }
        slider = slide
        root.addView(
            slide,
            LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, dp(72)).apply { topMargin = dp(16) },
        )
        return root
    }

    /**
     * Asks the system to dismiss the lock screen.
     * [stopRingingIfNotUnlocked] is true for "slide to stop": the ring stops even if the user
     * does not unlock, and the next internal alarm is scheduled.
     */
    private fun requestUnlock(stopRingingIfNotUnlocked: Boolean) {
        if (finishedFlow) return
        val keyguard = getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager

        if (!keyguard.isKeyguardLocked) {
            onUnlocked()
            return
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            keyguard.requestDismissKeyguard(
                this,
                object : KeyguardManager.KeyguardDismissCallback() {
                    override fun onDismissSucceeded() = onUnlocked()
                    override fun onDismissCancelled() = onNotUnlocked(stopRingingIfNotUnlocked)
                    override fun onDismissError() = onNotUnlocked(stopRingingIfNotUnlocked)
                },
            )
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD)
            window.decorView.postDelayed({
                if (!keyguard.isKeyguardLocked) onUnlocked() else onNotUnlocked(stopRingingIfNotUnlocked)
            }, 1500)
        }
    }

    private fun onUnlocked() {
        if (finishedFlow) return
        finishedFlow = true
        AlarmFlow.onUnlocked(applicationContext, alarmId)
        finish()
    }

    private fun onNotUnlocked(stopRinging: Boolean) {
        if (!stopRinging) {
            // Mission button: keep ringing and vibrating until the user unlocks.
            slider?.reset()
            return
        }
        if (finishedFlow) return
        finishedFlow = true
        AlarmAudioService.currentService?.handleDismissAlarm()
        AlarmFlow.onStoppedWithoutUnlock(applicationContext, alarmId, runIndex)
        finish()
    }

    @Deprecated("Back must not silence the alarm")
    override fun onBackPressed() {
        // Intentionally ignored: the alarm only stops through the two controls.
    }
}
