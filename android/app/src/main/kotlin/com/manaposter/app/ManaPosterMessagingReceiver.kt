package com.manaposter.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import com.google.firebase.messaging.RemoteMessage

class ManaPosterMessagingReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val extras = intent.extras ?: return
        val pendingResult = goAsync()
        val appContext = context.applicationContext ?: context
        Thread {
            try {
                Log.i("ManaPosterNotif", "receiver got FCM broadcast")
                ManaPosterNotificationRenderer.show(appContext, RemoteMessage(extras))
            } catch (t: Throwable) {
                Log.e("ManaPosterNotif", "receiver render failed", t)
            } finally {
                pendingResult.finish()
            }
        }.start()
    }
}
