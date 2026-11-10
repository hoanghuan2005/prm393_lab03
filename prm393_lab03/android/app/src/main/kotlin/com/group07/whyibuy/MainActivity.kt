package com.group07.whyibuy

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.text.TextUtils
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val CHANNEL = "com.group07.whyibuy/share_intent"
        private const val BUBBLE_CHANNEL = "com.group07.whyibuy/floating_bubble"
    }

    private var methodChannel: MethodChannel? = null
    private var bubbleChannel: MethodChannel? = null
    private var pendingShareText: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        extractShareText(intent)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.group07.whyibuy/facebook_config")
            .setMethodCallHandler { call, result ->
                if (call.method == "isConfigured") {
                    val appId = getString(R.string.facebook_app_id).trim()
                    val clientToken = getString(R.string.facebook_client_token).trim()
                    val scheme = getString(R.string.fb_login_protocol_scheme).trim()
                    result.success(appId != "0" && appId.all { it.isDigit() } && appId.isNotEmpty()
                        && clientToken.isNotEmpty() && clientToken != "0" && scheme == "fb$appId")
                } else {
                    result.notImplemented()
                }
            }
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)

        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "getInitialShareText" -> {
                    val text = pendingShareText
                    pendingShareText = null
                    result.success(text)
                }
                // Notification permission denied for good: Android shows no dialog any more,
                // so "Bật thông báo" opens this app's notification settings instead
                "openNotificationSettings" -> {
                    try {
                        val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                                .putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
                        } else {
                            Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.parse("package:$packageName"))
                        }
                        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        Log.e("MainActivity", "Failed to open notification settings: ${e.message}")
                        result.success(false)
                    }
                }
                else -> result.notImplemented()
            }
        }

        // If a share text arrived before or during engine setup, notify Flutter if channel is ready
        pendingShareText?.let { text ->
            methodChannel?.invokeMethod("onShareReceived", text)
        }

        bubbleChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, BUBBLE_CHANNEL)
        bubbleChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "checkOverlayPermission" -> {
                    val hasPerm = Settings.canDrawOverlays(this)
                    result.success(hasPerm)
                }
                "requestOverlayPermission" -> {
                    try {
                        val intent = Intent(
                            Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                            Uri.parse("package:$packageName")
                        ).apply {
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK
                        }
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        Log.e("MainActivity", "Failed to open overlay settings: ${e.message}")
                        result.success(false)
                    }
                }
                "startFloatingBubble" -> {
                    if (Settings.canDrawOverlays(this)) {
                        val serviceIntent = Intent(this, FloatingBubbleService::class.java).apply {
                            action = FloatingBubbleService.ACTION_START
                        }
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            startForegroundService(serviceIntent)
                        } else {
                            startService(serviceIntent)
                        }
                        result.success(true)
                    } else {
                        result.success(false)
                    }
                }
                "stopFloatingBubble" -> {
                    val serviceIntent = Intent(this, FloatingBubbleService::class.java).apply {
                        action = FloatingBubbleService.ACTION_STOP
                    }
                    startService(serviceIntent)
                    result.success(true)
                }
                "isBubbleRunning" -> {
                    result.success(FloatingBubbleService.isRunning)
                }
                "showTestAlert" -> {
                    val testUrl = call.argument<String>("url") ?: "https://shopee.vn/product/demo-sale-1111"
                    Log.d("MainActivity", "showTestAlert invoked for: $testUrl")
                    FloatingBubbleService.activeInstance?.triggerSaleAlert(testUrl, isSimulated = true) ?: run {
                        val serviceIntent = Intent(this, FloatingBubbleService::class.java).apply {
                            action = FloatingBubbleService.ACTION_TEST_ALERT
                            putExtra("url", testUrl)
                        }
                        startService(serviceIntent)
                    }
                    result.success(true)
                }
                "isAccessibilityServiceEnabled" -> {
                    result.success(isAccessibilityServiceEnabled())
                }
                "openAccessibilitySettings" -> {
                    try {
                        val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS).apply {
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK
                        }
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        Log.e("MainActivity", "Failed to open accessibility settings: ${e.message}")
                        result.success(false)
                    }
                }
                "showTestLingeringAlert" -> {
                    val title = call.argument<String>("title") ?: "Tai nghe không dây Bluetooth chống ồn"
                    val price = call.argument<String>("price") ?: "120.000 đ"
                    Log.d("MainActivity", "showTestLingeringAlert invoked for: $title - $price")
                    FloatingBubbleService.activeInstance?.handleLingeringAlert(title, price, "com.shopee.vn") ?: run {
                        val serviceIntent = Intent(this, FloatingBubbleService::class.java).apply {
                            action = FloatingBubbleService.ACTION_TEST_PULSE_ALERT
                            putExtra("title", title)
                            putExtra("price", price)
                        }
                        startService(serviceIntent)
                    }
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun isAccessibilityServiceEnabled(): Boolean {
        if (ShoppingAccessibilityService.isServiceConnected) {
            return true
        }
        val expectedServiceName = "$packageName/${ShoppingAccessibilityService::class.java.canonicalName}"
        val colonSplitter = TextUtils.SimpleStringSplitter(':')
        val settingValue = Settings.Secure.getString(
            contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        ) ?: return false

        colonSplitter.setString(settingValue)
        while (colonSplitter.hasNext()) {
            val componentName = colonSplitter.next()
            if (componentName.equals(expectedServiceName, ignoreCase = true) ||
                componentName.contains("ShoppingAccessibilityService")) {
                return true
            }
        }
        return false
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val text = extractShareText(intent)
        if (!text.isNullOrBlank()) {
            pendingShareText = text
            methodChannel?.invokeMethod("onShareReceived", text)
        }
    }

    private fun extractShareText(intent: Intent?): String? {
        if (intent == null) return null
        val action = intent.action
        val type = intent.type

        if (Intent.ACTION_SEND != action) return null
        if (type != null && !type.startsWith("text/")) return null

        val sharedText =
            intent.getCharSequenceExtra(Intent.EXTRA_TEXT)?.toString()?.trim()
                ?.takeIf { it.isNotEmpty() }
                ?: intent.getStringExtra(Intent.EXTRA_HTML_TEXT)?.trim()
                    ?.takeIf { it.isNotEmpty() }
                ?: intent.getStringExtra(Intent.EXTRA_TITLE)?.trim()
                    ?.takeIf { it.isNotEmpty() }
                ?: intent.clipData?.let { clip ->
                    if (clip.itemCount > 0) clip.getItemAt(0)?.coerceToText(this)?.toString()?.trim()?.takeIf { it.isNotEmpty() } else null
                }
                ?: intent.dataString?.trim()?.takeIf { it.isNotEmpty() }

        if (!sharedText.isNullOrBlank()) {
            pendingShareText = sharedText
            Log.d("WhyIBuyShare", "Received ACTION_SEND text (${sharedText.length} chars)")
            return sharedText
        }
        return null
    }
}
