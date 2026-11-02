package com.eala.app

import android.content.Context
import org.json.JSONObject

/**
 * Everything Flutter told us about one alarm. Persisted so the alarm can ring
 * (and repeat) correctly even when the app process is not running.
 */
data class AlarmConfig(
    val alarmId: String,
    val audioTrackId: String = "morning_message",
    val missionName: String = "Start Morning Mission",
    val title: String? = null,
    val subtitle: String? = null,
    val stopHintText: String = "slide to stop",
    val repeatCount: Int = 0,
    val repeatIntervalSec: Int = 10,
    val tuneAsset: String? = null,
) {
    val safeRepeatCount: Int get() = repeatCount.coerceIn(0, MAX_REPEAT_COUNT)
    val safeIntervalSec: Int get() = repeatIntervalSec.coerceAtLeast(MIN_INTERVAL_SEC)

    fun toJson(): String = JSONObject().apply {
        put("alarmId", alarmId)
        put("audioTrackId", audioTrackId)
        put("missionName", missionName)
        put("title", title)
        put("subtitle", subtitle)
        put("stopHintText", stopHintText)
        put("repeatCount", repeatCount)
        put("repeatIntervalSec", repeatIntervalSec)
        put("tuneAsset", tuneAsset)
    }.toString()

    companion object {
        const val MAX_REPEAT_COUNT = 20
        const val MIN_INTERVAL_SEC = 5

        fun fromJson(json: String): AlarmConfig? = try {
            val o = JSONObject(json)
            AlarmConfig(
                alarmId = o.getString("alarmId"),
                audioTrackId = o.optString("audioTrackId", "morning_message"),
                missionName = o.optString("missionName", "Start Morning Mission"),
                title = if (o.isNull("title")) null else o.optString("title"),
                subtitle = if (o.isNull("subtitle")) null else o.optString("subtitle"),
                stopHintText = o.optString("stopHintText", "slide to stop"),
                repeatCount = o.optInt("repeatCount", 0),
                repeatIntervalSec = o.optInt("repeatIntervalSec", 10),
                tuneAsset = if (o.isNull("tuneAsset")) null else o.optString("tuneAsset"),
            )
        } catch (_: Exception) {
            null
        }
    }
}

object AlarmConfigStore {
    private const val PREFS = "eala_alarm_config"

    fun save(context: Context, config: AlarmConfig) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit().putString(config.alarmId, config.toJson()).apply()
    }

    fun load(context: Context, alarmId: String): AlarmConfig? {
        val json = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getString(alarmId, null) ?: return null
        return AlarmConfig.fromJson(json)
    }

    fun remove(context: Context, alarmId: String) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit().remove(alarmId).apply()
    }
}

/** One-shot hand-off of "which alarm opened the app" to Flutter (consumeAlarmLaunch). */
object AlarmLaunchState {
    @Volatile var pendingAlarmId: String? = null

    fun consume(): String? {
        val id = pendingAlarmId
        pendingAlarmId = null
        return id
    }
}
