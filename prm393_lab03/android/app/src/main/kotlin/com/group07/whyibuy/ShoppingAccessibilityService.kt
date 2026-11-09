package com.group07.whyibuy

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo

/**
 * Accessibility service that detects lingering/hesitation on e-commerce product pages
 * (Shopee, Lazada, Tiki, TikTok Shop).
 * When user dwells on a product page for 15s without major navigation, triggers the
 * shopping guardian bubble to pulse (breathing animation) and display a mindful wake-up prompt.
 */
class ShoppingAccessibilityService : AccessibilityService() {

    companion object {
        const val TAG = "ShoppingA11yService"
        const val DWELL_DELAY_MS = 15000L // 15 seconds dwell threshold
        const val ALERT_COOLDOWN_MS = 45000L // 45s cooldown per product screen

        @Volatile
        var isServiceConnected = false
            private set

        val ECOMMERCE_PACKAGES = setOf(
            "com.shopee.vn",
            "com.lazada.vn",
            "vn.tiki.app.tikiandroid",
            "com.zhiliaoapp.musically"
        )

        fun isPackageEcommerce(packageName: CharSequence?): Boolean {
            if (packageName == null) return false
            val pkg = packageName.toString()
            return ECOMMERCE_PACKAGES.any { pkg.startsWith(it) }
        }
    }

    private val handler = Handler(Looper.getMainLooper())
    private var currentPackage: String? = null
    private var lastAlertTime = 0L
    private var lastDetectedTitle: String? = null

    private val dwellRunnable = Runnable {
        checkAndTriggerLingeringAlert()
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        isServiceConnected = true
        Log.d(TAG, "ShoppingAccessibilityService connected")

        val info = AccessibilityServiceInfo().apply {
            eventTypes = AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED or
                AccessibilityEvent.TYPE_VIEW_SCROLLED
            feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
            flags = AccessibilityServiceInfo.FLAG_REPORT_VIEW_IDS or
                AccessibilityServiceInfo.FLAG_RETRIEVE_INTERACTIVE_WINDOWS
            packageNames = ECOMMERCE_PACKAGES.toTypedArray()
            notificationTimeout = 250
        }
        serviceInfo = info
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return
        val pkg = event.packageName?.toString() ?: return

        if (!isPackageEcommerce(pkg)) {
            // User left shopping app
            cancelDwellTimer()
            currentPackage = null
            return
        }

        currentPackage = pkg

        when (event.eventType) {
            AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED -> {
                // New screen or dialog opened in shopping app -> reset dwell timer
                resetDwellTimer()
            }
            AccessibilityEvent.TYPE_VIEW_SCROLLED -> {
                // User is actively scrolling -> postpone dwell timer
                resetDwellTimer()
            }
        }
    }

    override fun onInterrupt() {
        Log.d(TAG, "ShoppingAccessibilityService interrupted")
        cancelDwellTimer()
    }

    override fun onDestroy() {
        super.onDestroy()
        isServiceConnected = false
        cancelDwellTimer()
        Log.d(TAG, "ShoppingAccessibilityService destroyed")
    }

    private fun resetDwellTimer() {
        handler.removeCallbacks(dwellRunnable)
        handler.postDelayed(dwellRunnable, DWELL_DELAY_MS)
    }

    private fun cancelDwellTimer() {
        handler.removeCallbacks(dwellRunnable)
    }

    private fun checkAndTriggerLingeringAlert() {
        val now = SystemClock.uptimeMillis()
        if (now - lastAlertTime < ALERT_COOLDOWN_MS) {
            Log.d(TAG, "Cooldown active, skipping alert")
            return
        }

        val rootNode = try {
            rootInActiveWindow
        } catch (e: Exception) {
            Log.w(TAG, "Failed to get rootInActiveWindow: ${e.message}")
            null
        } ?: return

        var detectedTitle: String? = null
        var detectedPrice: String? = null

        try {
            val textNodes = mutableListOf<String>()
            collectVisibleTexts(rootNode, textNodes, maxNodes = 60)

            // Price regex (e.g. 120.000 đ, ₫120.000, 250.000đ)
            val priceRegex = Regex("""(\b\d{1,3}([\.,]\d{3})+\s*(đ|₫|VND|VNĐ)?)|([đ₫]\s*\d{1,3}([\.,]\d{3})+)""", RegexOption.IGNORE_CASE)

            for (text in textNodes) {
                if (detectedPrice == null) {
                    val match = priceRegex.find(text)
                    if (match != null) {
                        detectedPrice = match.value.trim()
                    }
                }

                if (detectedTitle == null) {
                    val trimmed = text.trim()
                    if (isLikelyProductTitle(trimmed)) {
                        detectedTitle = trimmed
                    }
                }

                if (detectedPrice != null && detectedTitle != null) {
                    break
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error parsing screen nodes: ${e.message}")
        } finally {
            try {
                rootNode.recycle()
            } catch (_: Exception) {}
        }

        // If user already was alerted on this same product recently, skip
        if (detectedTitle != null && detectedTitle == lastDetectedTitle && (now - lastAlertTime < ALERT_COOLDOWN_MS * 2)) {
            return
        }

        lastAlertTime = now
        lastDetectedTitle = detectedTitle

        Log.d(TAG, "Lingering detected! Title: '$detectedTitle', Price: '$detectedPrice'")

        // Trigger floating bubble breathing pulse & wake-up reminder
        FloatingBubbleService.triggerLingeringAlert(
            context = this,
            title = detectedTitle,
            price = detectedPrice,
            packageName = currentPackage
        )
    }

    private fun collectVisibleTexts(node: AccessibilityNodeInfo?, outList: MutableList<String>, maxNodes: Int) {
        if (node == null || outList.size >= maxNodes) return
        val txt = node.text?.toString()?.trim()
        val desc = node.contentDescription?.toString()?.trim()

        if (!txt.isNullOrEmpty() && txt.length > 2) {
            outList.add(txt)
        } else if (!desc.isNullOrEmpty() && desc.length > 2) {
            outList.add(desc)
        }

        for (i in 0 until node.childCount) {
            if (outList.size >= maxNodes) break
            val child = try {
                node.getChild(i)
            } catch (e: Exception) {
                null
            }
            if (child != null) {
                collectVisibleTexts(child, outList, maxNodes)
                try {
                    child.recycle()
                } catch (_: Exception) {}
            }
        }
    }

    private val ignoredTitleKeywords = listOf(
        "mua ngay", "thêm vào giỏ", "giỏ hàng", "mua với voucher",
        "voucher", "freeship", "chat ngay", "đánh giá", "bình luận",
        "theo dõi", "tìm kiếm", "thông báo", "yêu thích", "xem shop",
        "tất cả", "chia sẻ", "mô tả sản phẩm", "chi tiết sản phẩm"
    )

    private fun isLikelyProductTitle(text: String): Boolean {
        if (text.length < 12 || text.length > 180) return false
        val lower = text.lowercase()
        if (ignoredTitleKeywords.any { lower == it || lower.startsWith("$it ") }) return false
        if (lower.startsWith("http://") || lower.startsWith("https://")) return false
        // Must contain some alphabetic words
        val wordCount = text.split("\\s+".toRegex()).size
        return wordCount >= 3
    }
}

