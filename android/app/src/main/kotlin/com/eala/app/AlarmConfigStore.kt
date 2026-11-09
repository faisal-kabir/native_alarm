package com.eala.app

import android.content.Context
import android.util.Log
import org.json.JSONObject
import java.io.File
import java.util.Calendar

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
    /** The alarm's own copy of its sound (see [AlarmTuneStore]); wins over [tuneAsset]. */
    val tuneFile: String? = null,
    /** A weekly alarm: weekday (1 = Mon .. 7 = Sun) -> minutes after midnight. Null = rings once. */
    val ringDays: Map<Int, Int>? = null,
    /** When the main alarm rings (a one-off alarm is set again from it after a reboot); null = not set. */
    val ringTimeMs: Long? = null,
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
        put("tuneFile", tuneFile)
        put("ringDays", ringDays?.let { days -> JSONObject().apply { days.forEach { (d, m) -> put(d.toString(), m) } } })
        put("ringTimeMs", ringTimeMs)
    }.toString()

    /** The weekly alarm's next ring strictly after [nowMs], or null for a one-off alarm. */
    fun nextWeeklyRing(nowMs: Long): Long? {
        val days = ringDays ?: return null
        val day = Calendar.getInstance().apply { timeInMillis = nowMs }
        for (offset in 0..7) {
            // Calendar: 1 = Sun .. 7 = Sat -> 1 = Mon .. 7 = Sun
            val minutes = days[(day.get(Calendar.DAY_OF_WEEK) + 5) % 7 + 1]
            if (minutes != null) {
                val ring = (day.clone() as Calendar).apply {
                    set(Calendar.HOUR_OF_DAY, minutes / 60)
                    set(Calendar.MINUTE, minutes % 60)
                    set(Calendar.SECOND, 0)
                    set(Calendar.MILLISECOND, 0)
                }.timeInMillis
                if (ring > nowMs) return ring
            }
            day.add(Calendar.DAY_OF_YEAR, 1)
        }
        return null
    }

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
                tuneFile = if (o.isNull("tuneFile")) null else o.optString("tuneFile"),
                ringDays = o.optJSONObject("ringDays")?.let { days ->
                    days.keys().asSequence().associate { it.toInt() to days.getInt(it) }
                },
                ringTimeMs = if (o.isNull("ringTimeMs")) null else o.optLong("ringTimeMs"),
            )
        } catch (_: Exception) {
            null
        }

        /** `ringDays` from Flutter: weekday (1..7) -> minutes (0 until 1440); anything else is dropped. */
        fun parseRingDays(value: Any?): Map<Int, Int>? {
            val map = value as? Map<*, *> ?: return null
            val days = mutableMapOf<Int, Int>()
            for ((k, v) in map) {
                val day = (k as? Number)?.toInt() ?: k?.toString()?.toIntOrNull() ?: continue
                val minutes = (v as? Number)?.toInt() ?: continue
                if (day in 1..7 && minutes in 0 until 1440) days[day] = minutes
            }
            return days.ifEmpty { null }
        }
    }
}

/**
 * The alarm's own copy of its sound (a downloaded alarm sound from Flutter), in the app's
 * `alarm_tunes` folder. The copy belongs to the alarm, so Flutter may replace or delete the
 * original afterwards. Same rule as iOS (AlarmTuneStore in AlarmScheduler.swift).
 */
object AlarmTuneStore {
    private fun dir(context: Context) = File(context.filesDir, "alarm_tunes")

    private fun prefix(alarmId: String) = "eala-" + alarmId.map { if (it.isLetterOrDigit()) it else '_' }.joinToString("") + "-"

    /**
     * Copies [filePath] for [alarmId] and returns the copy's path, or null (missing file: the
     * default tune rings). Downloaded file names change with their content, so an unchanged
     * file is not copied again.
     */
    fun install(context: Context, filePath: String?, alarmId: String): String? {
        if (filePath.isNullOrEmpty()) return null
        val source = File(filePath)
        if (!source.isFile) {
            Log.w("AlarmTuneStore", "File not found: $filePath")
            return null
        }
        val target = File(dir(context), prefix(alarmId) + source.name)
        remove(context, alarmId, keeping = target.name)
        if (target.isFile) return target.path
        return try {
            target.parentFile?.mkdirs()
            source.copyTo(target, overwrite = true)
            target.path
        } catch (e: Exception) {
            target.delete()
            Log.w("AlarmTuneStore", "Could not copy $filePath", e)
            null
        }
    }

    /** Deletes the alarm's copies (all but [keeping]). */
    fun remove(context: Context, alarmId: String, keeping: String? = null) {
        dir(context).listFiles()
            ?.filter { it.name.startsWith(prefix(alarmId)) && it.name != keeping }
            ?.forEach { it.delete() }
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

    /** Every stored alarm. */
    fun all(context: Context): List<AlarmConfig> =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).all.values
            .mapNotNull { (it as? String)?.let(AlarmConfig::fromJson) }
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
