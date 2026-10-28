package com.abrar.spendsplit

import android.os.Build
import android.os.Bundle
import androidx.core.app.ActivityCompat
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private var pendingPermissionResult: MethodChannel.Result? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Keep balances out of the recents preview. Unlike FLAG_SECURE this
        // still allows screenshots. Android 13+; older versions show it.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            setRecentsScreenshotEnabled(false)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SmsBridge.CHANNEL)
        channel.setMethodCallHandler { call, result ->
            if (call.method == "requestPermission") {
                requestSmsPermission(result)
            } else {
                SmsBridge.handle(applicationContext, call, result)
            }
        }
        runningChannel = channel
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        runningChannel = null
        super.cleanUpFlutterEngine(flutterEngine)
    }

    private fun requestSmsPermission(result: MethodChannel.Result) {
        if (pendingPermissionResult != null) {
            result.error("busy", "An SMS permission request is already showing", null)
            return
        }
        pendingPermissionResult = result
        ActivityCompat.requestPermissions(this, SmsBridge.REQUESTED_PERMISSIONS, SMS_PERMISSION_REQUEST)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != SMS_PERMISSION_REQUEST) return
        pendingPermissionResult?.success(SmsBridge.permissions(this))
        pendingPermissionResult = null
    }

    companion object {
        private const val SMS_PERMISSION_REQUEST = 4721

        /** The running engine's SMS channel; SmsReceiver uses it when non-null. */
        @Volatile
        var runningChannel: MethodChannel? = null
    }
}
