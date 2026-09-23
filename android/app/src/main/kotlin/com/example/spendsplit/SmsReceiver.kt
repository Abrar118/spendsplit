package com.example.spendsplit

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.Looper
import android.provider.Telephony
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel

/**
 * Wakes the Dart SMS importer when a Trust Bank SMS arrives. Doesn't parse:
 * the importer reads the inbox itself, so there is one code path.
 */
class SmsReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Telephony.Sms.Intents.SMS_RECEIVED_ACTION) return
        val fromBank = Telephony.Sms.Intents.getMessagesFromIntent(intent)
            ?.any { it?.originatingAddress.equals(SmsBridge.SENDER, ignoreCase = true) } == true
        if (!fromBank) return

        // goAsync() in both branches: invokeMethod and the headless run are async.
        val pending = goAsync()
        val app = context.applicationContext
        val handler = Handler(Looper.getMainLooper())
        var engine: FlutterEngine? = null
        var finished = false
        lateinit var timeout: Runnable

        fun finish() {
            if (finished) return
            finished = true
            handler.removeCallbacks(timeout)
            val headless = engine
            engine = null
            // Destroy after the current channel callback has returned.
            if (headless != null) handler.post { headless.destroy() }
            pending.finish()
        }
        timeout = Runnable { finish() }
        handler.postDelayed(timeout, TIMEOUT_MS)

        val running = MainActivity.runningChannel
        if (running != null) {
            running.invokeMethod(
                "import",
                mapOf("waitForNew" to true),
                object : MethodChannel.Result {
                    override fun success(result: Any?) = finish()
                    override fun error(code: String, message: String?, details: Any?) = finish()
                    override fun notImplemented() = finish()
                },
            )
            return
        }

        val headless = FlutterEngine(app)
        engine = headless
        MethodChannel(headless.dartExecutor.binaryMessenger, SmsBridge.CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "backgroundDone") {
                    result.success(null)
                    finish()
                } else {
                    SmsBridge.handle(app, call, result)
                }
            }
        headless.dartExecutor.executeDartEntrypoint(
            DartExecutor.DartEntrypoint(
                FlutterInjector.instance().flutterLoader().findAppBundlePath(),
                "smsBackgroundMain",
            ),
        )
    }

    private companion object {
        /** Receivers get ~10 s after goAsync(); stay under it. */
        const val TIMEOUT_MS = 9_000L
    }
}
