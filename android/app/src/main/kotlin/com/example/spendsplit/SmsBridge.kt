package com.example.spendsplit

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.provider.Telephony
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/** Native side of the `spendsplit/sms` channel: permissions and inbox reads. */
object SmsBridge {
    const val CHANNEL = "spendsplit/sms"
    const val SENDER = "TrustBank"
    val REQUESTED_PERMISSIONS = arrayOf(
        Manifest.permission.READ_SMS,
        Manifest.permission.RECEIVE_SMS,
    )

    fun handle(context: Context, call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "hasPermission" -> result.success(permissions(context))
            "readInbox" -> {
                val since = call.argument<Number>("sinceMillis")?.toLong()
                if (since == null) {
                    result.error("bad_args", "sinceMillis is required", null)
                    return
                }
                try {
                    result.success(readInbox(context, since))
                } catch (e: Exception) {
                    result.error("read_failed", e.message, null)
                }
            }
            else -> result.notImplemented()
        }
    }

    fun permissions(context: Context): Map<String, Boolean> = mapOf(
        "read" to granted(context, Manifest.permission.READ_SMS),
        "receive" to granted(context, Manifest.permission.RECEIVE_SMS),
    )

    private fun granted(context: Context, permission: String) =
        ContextCompat.checkSelfPermission(context, permission) ==
            PackageManager.PERMISSION_GRANTED

    /** Trust Bank inbox rows received strictly after [sinceMillis], oldest first. */
    private fun readInbox(context: Context, sinceMillis: Long): List<Map<String, Any>> {
        val rows = mutableListOf<Map<String, Any>>()
        context.contentResolver.query(
            Telephony.Sms.Inbox.CONTENT_URI,
            arrayOf(Telephony.Sms.BODY, Telephony.Sms.DATE),
            "${Telephony.Sms.ADDRESS} = ? COLLATE NOCASE AND ${Telephony.Sms.DATE} > ?",
            arrayOf(SENDER, sinceMillis.toString()),
            "${Telephony.Sms.DATE} ASC",
        )?.use { cursor ->
            while (cursor.moveToNext()) {
                rows.add(mapOf("body" to (cursor.getString(0) ?: ""), "date" to cursor.getLong(1)))
            }
        }
        return rows
    }
}
