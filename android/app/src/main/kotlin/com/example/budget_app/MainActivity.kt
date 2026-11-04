// Remplace android/app/src/main/kotlin/<ton/package>/MainActivity.kt
// et adapte la ligne "package" à ton applicationId.
package com.example.budget_app

import android.provider.Telephony
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "budget_app/sms")
            .setMethodCallHandler { call, result ->
                if (call.method == "readInbox") {
                    val since = call.argument<Number>("since")?.toLong() ?: 0L
                    try {
                        result.success(readInbox(since))
                    } catch (e: SecurityException) {
                        result.error("PERMISSION", "READ_SMS non accordée", null)
                    }
                } else {
                    result.notImplemented()
                }
            }
    }

    private fun readInbox(since: Long): List<Map<String, Any?>> {
        val out = ArrayList<Map<String, Any?>>()
        val cursor = contentResolver.query(
            Telephony.Sms.Inbox.CONTENT_URI,
            arrayOf(Telephony.Sms.ADDRESS, Telephony.Sms.BODY, Telephony.Sms.DATE),
            "${Telephony.Sms.DATE} >= ?",
            arrayOf(since.toString()),
            "${Telephony.Sms.DATE} ASC"
        ) ?: return out
        cursor.use {
            while (it.moveToNext()) {
                out.add(
                    mapOf(
                        "address" to it.getString(0),
                        "body" to it.getString(1),
                        "date" to it.getLong(2)
                    )
                )
            }
        }
        return out
    }
}
