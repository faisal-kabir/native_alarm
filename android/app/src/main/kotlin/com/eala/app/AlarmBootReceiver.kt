package com.eala.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * A reboot or an app update clears every AlarmManager alarm: set each stored alarm again,
 * without the app being opened. (iOS keeps AlarmKit alarms and notifications by itself.)
 */
class AlarmBootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Intent.ACTION_BOOT_COMPLETED && intent.action != Intent.ACTION_MY_PACKAGE_REPLACED) return
        AlarmConfigStore.all(context).forEach { AlarmScheduler.restore(context, it) }
    }
}
