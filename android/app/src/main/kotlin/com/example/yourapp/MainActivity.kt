package com.example.yourapp

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.pm.PackageManager
import java.security.MessageDigest

class MainActivity: FlutterActivity() {
    private val CHANNEL = "app_integrity"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getSignatureHash") {
                try {
                    val hash = getApkSignatureHash()
                    result.success(hash)
                } catch (e: Exception) {
                    result.error("SIGNATURE_ERROR", e.message, null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun getApkSignatureHash(): String {
        val packageInfo = packageManager.getPackageInfo(
            packageName, 
            PackageManager.GET_SIGNATURES
        )
        val signature = packageInfo.signatures[0]
        val md = MessageDigest.getInstance("SHA-256")
        val hashBytes = md.digest(signature.toByteArray())
        val hash = hashBytes.joinToString("") { "%02x".format(it) }
        return hash
    }
}
