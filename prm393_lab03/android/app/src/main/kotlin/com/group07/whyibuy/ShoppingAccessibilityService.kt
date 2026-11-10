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
        const val STANDARD_DWELL_MS = 25000L // 25s cumulative dwell on same product page
        const val ENGAGED_DWELL_MS = 15000L  // 15s if engaged (scrolled 4+ times or viewing reviews)
        const val ALERT_COOLDOWN_MS = 45000L // 45s cooldown per product screen
        const val CHECK_INTERVAL_MS = 2500L  // Check every 2.5s

        @Volatile
        var isServiceConnected = false
            private set

        @Volatile
        var activeInstance: ShoppingAccessibilityService? = null
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
    var currentPackage: String? = null
        private set
    private var lastAlertTime = 0L
    private var lastDetectedTitle: String? = null
    private var cachedShopName: String? = null

    // Session tracking variables for Option 1 + Option 2
    private var sessionStartTime = 0L
    private var sessionScrollCount = 0
    private var hasViewedReviews = false
    private var isAlertTriggeredForCurrentSession = false
    private var currentSessionTitle: String? = null
    private var isSessionLoopRunning = false

    private val sessionCheckRunnable = object : Runnable {
        override fun run() {
            if (currentPackage != null) {
                evaluateProductDwellSession()
                handler.postDelayed(this, CHECK_INTERVAL_MS)
            } else {
                isSessionLoopRunning = false
            }
        }
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        isServiceConnected = true
        activeInstance = this
        Log.d(TAG, "ShoppingAccessibilityService connected")

        val info = AccessibilityServiceInfo().apply {
            eventTypes = AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED or
                AccessibilityEvent.TYPE_VIEW_SCROLLED or
                AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED
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
            resetProductSession()
            currentPackage = null
            return
        }

        currentPackage = pkg

        if (!isSessionLoopRunning) {
            isSessionLoopRunning = true
            handler.post(sessionCheckRunnable)
        }

        when (event.eventType) {
            AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED -> {
                // Window changed: check if navigated to a new screen/product
                checkProductTransition()
            }
            AccessibilityEvent.TYPE_VIEW_SCROLLED -> {
                // User is scrolling inside the product page (reading description, reviews, etc.)
                // DO NOT reset session! Increment scroll count and check engagement signals.
                sessionScrollCount++
                if (sessionStartTime == 0L) {
                    sessionStartTime = SystemClock.uptimeMillis()
                }

                // Check if reviews or comments are appearing on screen
                val eventTexts = event.text?.joinToString(" ")?.lowercase() ?: ""
                if (eventTexts.contains("đánh giá") || eventTexts.contains("bình luận") || eventTexts.contains("nhận xét") || eventTexts.contains("review")) {
                    hasViewedReviews = true
                }

                // Immediately test if engaged threshold (15s) is reached
                evaluateProductDwellSession()
            }
            AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED -> {
                if (sessionStartTime == 0L) {
                    sessionStartTime = SystemClock.uptimeMillis()
                }
            }
        }
    }

    override fun onInterrupt() {
        Log.d(TAG, "ShoppingAccessibilityService interrupted")
        resetProductSession()
    }

    override fun onDestroy() {
        super.onDestroy()
        isServiceConnected = false
        if (activeInstance == this) activeInstance = null
        resetProductSession()
        Log.d(TAG, "ShoppingAccessibilityService destroyed")
    }

    private fun checkProductTransition() {
        val prod = captureCurrentProduct()
        val title = prod.title
        if (!title.isNullOrBlank()) {
            if (currentSessionTitle == null || isDifferentProduct(title, currentSessionTitle)) {
                // Fresh product session!
                currentSessionTitle = title
                sessionStartTime = SystemClock.uptimeMillis()
                sessionScrollCount = 0
                hasViewedReviews = false
                isAlertTriggeredForCurrentSession = false
                cachedShopName = null
                Log.d(TAG, "New product session: $title")
            }
        }
    }

    private fun isDifferentProduct(newTitle: String, oldTitle: String?): Boolean {
        if (oldTitle == null) return true
        if (newTitle == oldTitle) return false
        return !newTitle.take(30).equals(oldTitle.take(30), ignoreCase = true)
    }

    private fun evaluateProductDwellSession() {
        val now = SystemClock.uptimeMillis()
        if (now - lastAlertTime < ALERT_COOLDOWN_MS) return
        if (isAlertTriggeredForCurrentSession) return
        if (sessionStartTime == 0L) return

        val elapsed = now - sessionStartTime
        val isEngaged = sessionScrollCount >= 4 || hasViewedReviews

        val shouldTrigger = if (isEngaged) {
            elapsed >= ENGAGED_DWELL_MS
        } else {
            elapsed >= STANDARD_DWELL_MS
        }

        if (shouldTrigger) {
            checkAndTriggerLingeringAlert()
        }
    }

    private fun resetProductSession() {
        sessionStartTime = 0L
        sessionScrollCount = 0
        hasViewedReviews = false
        isAlertTriggeredForCurrentSession = false
        currentSessionTitle = null
        cachedShopName = null
        isSessionLoopRunning = false
        handler.removeCallbacks(sessionCheckRunnable)
    }

    data class ScreenNode(
        val text: String,
        val resId: String?
    )

    data class ProductInfo(
        val title: String?,
        val price: String?,
        val shopName: String?,
        val url: String?,
        val imageUrl: String?
    )

    /**
     * Inspects active window nodes to extract product title, price, shop name, image & link.
     */
    fun captureCurrentProduct(): ProductInfo {
        val rootNode = try {
            rootInActiveWindow
        } catch (e: Exception) {
            Log.w(TAG, "Failed to get rootInActiveWindow: ${e.message}")
            null
        } ?: return ProductInfo(null, null, cachedShopName, null, null)

        var detectedTitle: String? = null
        var detectedPrice: String? = null
        var detectedShop: String? = null
        var detectedUrl: String? = null
        var detectedImage: String? = null

        try {
            val nodes = mutableListOf<ScreenNode>()
            collectVisibleNodes(rootNode, nodes, maxNodes = 150)

            // Price regex (e.g. 143.100 đ, ₫120.000, 250.000đ, or 143.100)
            val priceRegex = Regex("""(\b\d{1,3}([\.,]\d{3})+\s*(đ|₫|VND|VNĐ)?)|([đ₫]\s*\d{1,3}([\.,]\d{3})+)""", RegexOption.IGNORE_CASE)

            // Pass 1: Resource ID exact matches
            for (node in nodes) {
                val res = node.resId?.lowercase() ?: ""
                val text = node.text.trim()

                // Exact product name on Shopee / Lazada / Tiki
                if (detectedTitle == null && (res.contains("productname") || res.contains("product_name") || res.contains("product_title"))) {
                    if (text.length > 5 && !isRankingBadge(text)) {
                        detectedTitle = cleanProductTitle(text)
                    }
                }

                // Image hash on Shopee (e.g. imageProduct_vn-11134207-...)
                if (detectedImage == null && res.contains("imageproduct_")) {
                    val hash = res.substringAfter("imageproduct_").trim()
                    if (hash.isNotEmpty()) {
                        detectedImage = "https://down-vn.img.susercontent.com/file/$hash"
                    }
                }

                // Shop name resource ID
                if (detectedShop == null && (res.contains("shopname") || res.contains("shop_name") || res.contains("labelshopname") || res.contains("shoptitle"))) {
                    if (text.length in 2..45 && !isShopJunk(text)) {
                        detectedShop = text.trimEnd('.', '…', ' ')
                    }
                }

                // URL detection
                if (detectedUrl == null && (text.startsWith("http://") || text.startsWith("https://") || text.contains("shp.ee"))) {
                    detectedUrl = text
                }
            }

            // Pass 2: Heuristic matching
            for (i in nodes.indices) {
                val node = nodes[i]
                val text = node.text.trim()

                // Price matching
                if (detectedPrice == null) {
                    val match = priceRegex.find(text)
                    if (match != null) {
                        var p = match.value.trim()
                        if (!p.endsWith("đ", ignoreCase = true) && !p.endsWith("₫") && !p.endsWith("vnd", ignoreCase = true)) {
                            p += " đ"
                        }
                        detectedPrice = p
                    }
                }

                // Title heuristic if resource id match was not found
                if (detectedTitle == null && isLikelyProductTitle(text)) {
                    detectedTitle = cleanProductTitle(text)
                }

                // Shop heuristic: Look for "Xem Shop" / "Đến Shop"
                if (detectedShop == null) {
                    val low = text.lowercase()
                    if (low == "xem shop" || low == "đến shop" || low == "visit shop" || low == "view shop") {
                        // Look backwards 1..5 nodes for the real shop name (e.g. "Cherry - Perseper Xưởng T...")
                        for (k in (i - 1) downTo maxOf(0, i - 5)) {
                            val candidate = nodes[k].text.trim()
                            if (candidate.length in 2..45 && !isShopJunk(candidate)) {
                                detectedShop = candidate.trimEnd('.', '…', ' ')
                                break
                            }
                        }
                    } else if (low.startsWith("shop:") || low.startsWith("shop :")) {
                        val candidate = text.substringAfter(":").trim()
                        if (candidate.length in 2..45 && !isShopJunk(candidate)) {
                            detectedShop = candidate.trimEnd('.', '…', ' ')
                        }
                    }
                }
            }

            // Pass 3: Title suffix fallback for shop name (e.g. "... - XMMN")
            if (detectedShop == null && detectedTitle != null) {
                val suffixMatch = Regex("""[-–—|]\s*([A-Za-z0-9À-ỹ\s]{2,20})$""").find(detectedTitle)
                if (suffixMatch != null) {
                    val candidate = suffixMatch.groupValues[1].trim()
                    if (!isCommonSpecWord(candidate)) {
                        detectedShop = candidate.trimEnd('.', '…', ' ')
                    }
                }
            }

            if (detectedShop != null) {
                cachedShopName = detectedShop
            } else if (cachedShopName != null) {
                detectedShop = cachedShopName
            }

        } catch (e: Exception) {
            Log.e(TAG, "Error parsing screen nodes: ${e.message}")
        } finally {
            try {
                rootNode.recycle()
            } catch (_: Exception) {}
        }

        return ProductInfo(
            title = detectedTitle?.let { cleanProductTitle(it) },
            price = detectedPrice,
            shopName = detectedShop ?: cachedShopName,
            url = detectedUrl,
            imageUrl = detectedImage
        )
    }

    private fun checkAndTriggerLingeringAlert() {
        val now = SystemClock.uptimeMillis()
        if (now - lastAlertTime < ALERT_COOLDOWN_MS) {
            Log.d(TAG, "Cooldown active, skipping alert")
            return
        }

        val prod = captureCurrentProduct()
        if (prod.title.isNullOrBlank() && prod.price.isNullOrBlank()) {
            Log.d(TAG, "Not a product page or no title/price detected")
            return
        }

        // If user already was alerted on this same product recently, skip
        if (prod.title != null && prod.title == lastDetectedTitle && (now - lastAlertTime < ALERT_COOLDOWN_MS * 2)) {
            return
        }

        lastAlertTime = now
        lastDetectedTitle = prod.title
        isAlertTriggeredForCurrentSession = true

        Log.d(TAG, "Lingering alert triggered! Title: '${prod.title}', Price: '${prod.price}', Shop: '${prod.shopName}', ScrollCount: $sessionScrollCount, HasReviews: $hasViewedReviews")

        // Trigger floating bubble breathing pulse & wake-up reminder
        FloatingBubbleService.triggerLingeringAlert(
            context = this,
            title = prod.title,
            price = prod.price,
            packageName = currentPackage,
            shopName = prod.shopName,
            url = prod.url,
            imageUrl = prod.imageUrl
        )
    }

    private fun collectVisibleNodes(node: AccessibilityNodeInfo?, outList: MutableList<ScreenNode>, maxNodes: Int) {
        if (node == null || outList.size >= maxNodes) return
        val txt = node.text?.toString()?.trim()
        val desc = node.contentDescription?.toString()?.trim()
        val res = node.viewIdResourceName

        if (!txt.isNullOrEmpty() && txt.length > 1) {
            outList.add(ScreenNode(text = txt, resId = res))
        } else if (!desc.isNullOrEmpty() && desc.length > 1) {
            outList.add(ScreenNode(text = desc, resId = res))
        }

        for (i in 0 until node.childCount) {
            if (outList.size >= maxNodes) break
            val child = try {
                node.getChild(i)
            } catch (e: Exception) {
                null
            }
            if (child != null) {
                collectVisibleNodes(child, outList, maxNodes)
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

    private fun isRankingBadge(text: String): Boolean {
        val low = text.lowercase()
        return low.startsWith("top no.") ||
            low.startsWith("top no ") ||
            low.startsWith("top 1") ||
            low.startsWith("top 2") ||
            low.startsWith("top 3") ||
            low.startsWith("top 4") ||
            low.startsWith("top 5") ||
            low.contains("bán chạy nhất")
    }

    private fun cleanProductTitle(raw: String): String {
        var t = raw.trim()
        // Strip leading isolated digits or artifacts like "0Ô" -> "Ô", "0 Áo" -> "Áo", "0. Áo" -> "Áo"
        t = t.replaceFirst(Regex("""^[0-9]+(?=[A-Za-zÀ-ỹ])"""), "")
        t = t.replaceFirst(Regex("""^[0-9]+[\s.:\-–—|•]+(?=[A-Za-zÀ-ỹ])"""), "")
        // Strip leading ranking badges like "Top No.3", "Top 1", etc.
        t = t.replaceFirst(Regex("""^(?:Top\s*(?:No\.?\s*)?\d+[\s:\-–—|•]+)""", RegexOption.IGNORE_CASE), "")
        return t.trim()
    }

    private fun isShopJunk(text: String): Boolean {
        val low = text.lowercase().trim()
        val junkKeywords = listOf(
            "online", "đánh giá", "tỉ lệ", "sản phẩm", "theo dõi", "chat",
            "freeship", "voucher", "voucher shop", "mã giảm", "phút trước", "giờ trước",
            "ngày trước", "kho hàng", "vận chuyển", "người theo dõi", "phản hồi",
            "xem shop", "đến shop", "visit shop", "view shop",
            "shop nổi bật", "shop xu hướng", "nổi bật", "xu hướng",
            "yêu thích+", "yêu thích", "shopee mall", "mall", "official store",
            "chính hãng", "đổi ý miễn phí", "hướng dẫn chọn", "tất cả", "xem tất cả"
        )
        if (junkKeywords.any { low == it || low.startsWith("$it ") || low.endsWith(" $it") }) return true
        if (low.startsWith("trong ")) return true // e.g. "trong Vớ/ Tất nữ", "trong Thời trang"
        if (low.contains("vớ/ tất") || low.contains("thời trang") || low.contains("ngành hàng")) return true
        if (low.matches(Regex("""[\d\.,\s%⭐★/+\-]+"""))) return true
        return false
    }

    private fun isCommonSpecWord(text: String): Boolean {
        val low = text.lowercase()
        return low.contains("size") || low.contains("màu") || low.contains("chính hãng") ||
            low.contains("cao cấp") || low.contains("giá rẻ") || low.contains("freeship")
    }

    private fun isLikelyProductTitle(text: String): Boolean {
        val cleaned = cleanProductTitle(text)
        if (cleaned.length < 12 || cleaned.length > 180) return false
        if (isRankingBadge(cleaned)) return false
        val lower = cleaned.lowercase()
        if (ignoredTitleKeywords.any { lower == it || lower.startsWith("$it ") }) return false
        if (lower.startsWith("http://") || lower.startsWith("https://")) return false
        val wordCount = cleaned.split("\\s+".toRegex()).size
        return wordCount >= 3
    }
}

