package com.example.driver

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.pm.PackageManager
import android.os.Build
import java.security.MessageDigest

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.example.driver/app_meta"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getGoogleMapsApiKey" -> {
                    try {
                        val ai = packageManager.getApplicationInfo(
                            packageName,
                            PackageManager.GET_META_DATA
                        )
                        val key = ai.metaData?.getString("com.google.android.geo.API_KEY") ?: ""
                        result.success(key)
                    } catch (e: Exception) {
                        result.success("")
                    }
                }
                "getAndroidAppIdentity" -> {
                    try {
                        val pkg = packageName
                        val sha1 = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                            val info = packageManager.getPackageInfo(
                                pkg,
                                PackageManager.GET_SIGNING_CERTIFICATES
                            )
                            val sig = info.signingInfo?.apkContentsSigners?.firstOrNull()
                            val bytes = sig?.toByteArray()
                            bytes?.let { sha1Hex(it) } ?: ""
                        } else {
                            @Suppress("DEPRECATION")
                            val info = packageManager.getPackageInfo(
                                pkg,
                                PackageManager.GET_SIGNATURES
                            )
                            @Suppress("DEPRECATION")
                            val sig = info.signatures?.firstOrNull()
                            val bytes = sig?.toByteArray()
                            bytes?.let { sha1Hex(it) } ?: ""
                        }
                        result.success(mapOf("package" to pkg, "sha1" to sha1))
                    } catch (e: Exception) {
                        result.success(mapOf("package" to packageName, "sha1" to ""))
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun sha1Hex(bytes: ByteArray): String {
        val md = MessageDigest.getInstance("SHA1")
        val digest = md.digest(bytes)
        val sb = StringBuilder()
        for (b in digest) {
            sb.append(String.format("%02X", b))
        }
        return sb.toString()
    }
}
