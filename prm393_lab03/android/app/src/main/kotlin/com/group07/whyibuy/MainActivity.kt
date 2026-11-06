package com.group07.whyibuy

import android.content.Intent
import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val CHANNEL = "com.group07.whyibuy/share_intent"
    }

    private var methodChannel: MethodChannel? = null
    private var pendingShareText: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        extractShareText(intent)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)

        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "getInitialShareText" -> {
                    val text = pendingShareText
                    pendingShareText = null
                    result.success(text)
                }
                else -> result.notImplemented()
            }
        }

        // If a share text arrived before or during engine setup, notify Flutter if channel is ready
        pendingShareText?.let { text ->
            methodChannel?.invokeMethod("onShareReceived", text)
        }
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
