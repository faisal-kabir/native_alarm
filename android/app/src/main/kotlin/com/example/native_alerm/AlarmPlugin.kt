package com.example.native_alerm

import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.EventChannel

object AlarmPlugin {
    private val pendingEvents = mutableListOf<Map<String, Any?>>()
    private val mainHandler = Handler(Looper.getMainLooper())

    var eventSink: EventChannel.EventSink? = null
        set(value) {
            field = value
            if (value != null && pendingEvents.isNotEmpty()) {
                val toSend = ArrayList(pendingEvents)
                pendingEvents.clear()
                for (event in toSend) {
                    try {
                        value.success(event)
                    } catch (_: Exception) {}
                }
            }
        }

    fun clearEvents(vararg types: String) {
        mainHandler.post {
            pendingEvents.removeAll { it["event"] in types }
        }
    }

    fun sendEvent(event: Map<String, Any?>) {
        mainHandler.post {
            val type = event["event"] as? String
            if (type == "openTranscript" || type == "customAudioStarted") {
                pendingEvents.removeAll { it["event"] == "alarmRinging" }
            }

            val sink = eventSink
            if (sink != null) {
                try {
                    sink.success(event)
                } catch (_: Exception) {}
            } else {
                if (type == "openTranscript" || type == "alarmRinging" || type == "customAudioStarted") {
                    pendingEvents.add(event)
                }
            }
        }
    }
}
