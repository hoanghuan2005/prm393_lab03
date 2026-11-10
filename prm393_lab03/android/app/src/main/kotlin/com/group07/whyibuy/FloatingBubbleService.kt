package com.group07.whyibuy

import android.animation.ObjectAnimator
import android.animation.PropertyValuesHolder
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.ClipDescription
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.VibrationEffect
import android.os.Vibrator
import android.provider.Settings
import android.text.TextUtils
import android.util.Log
import android.util.TypedValue
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.view.animation.AccelerateDecelerateInterpolator
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import kotlin.math.hypot

class FloatingBubbleService : Service() {

    companion object {
        const val TAG = "FloatingBubbleService"
        const val CHANNEL_ID = "whyibuy_shopping_guardian"
        const val NOTIFICATION_ID = 9021

        const val ACTION_START = "com.group07.whyibuy.START_BUBBLE"
        const val ACTION_STOP = "com.group07.whyibuy.STOP_BUBBLE"
        const val ACTION_TEST_ALERT = "com.group07.whyibuy.TEST_ALERT"
        const val ACTION_LINGERING_ALERT = "com.group07.whyibuy.LINGERING_ALERT"
        const val ACTION_TEST_PULSE_ALERT = "com.group07.whyibuy.TEST_PULSE_ALERT"

        @Volatile
        var isRunning = false
            private set

        @Volatile
        var activeInstance: FloatingBubbleService? = null
            private set

        fun triggerLingeringAlert(
            context: Context,
            title: String?,
            price: String?,
            packageName: String?,
            shopName: String? = null,
            url: String? = null,
            imageUrl: String? = null
        ) {
            val service = activeInstance
            if (service != null && isRunning) {
                service.handleLingeringAlert(title, price, packageName, shopName, url, imageUrl)
            } else {
                try {
                    val intent = Intent(context, FloatingBubbleService::class.java).apply {
                        action = ACTION_LINGERING_ALERT
                        putExtra("title", title)
                        putExtra("price", price)
                        putExtra("package", packageName)
                        putExtra("shopName", shopName)
                        putExtra("url", url)
                        putExtra("imageUrl", imageUrl)
                    }
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        context.startForegroundService(intent)
                    } else {
                        context.startService(intent)
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "Failed to start FloatingBubbleService for lingering alert: ${e.message}")
                }
            }
        }
    }

    private var windowManager: WindowManager? = null
    private var rootView: LinearLayout? = null
    private var bubbleView: FrameLayout? = null
    private var calloutCard: LinearLayout? = null
    private var badgeDot: View? = null
    private var calloutTitle: TextView? = null
    private var calloutBody: TextView? = null
    private var calloutUrlText: TextView? = null
    private var calloutActionBtn: LinearLayout? = null
    private var calloutActionIcon: ImageView? = null
    private var calloutActionText: TextView? = null

    private var windowLayoutParams: WindowManager.LayoutParams? = null
    private var clipboardManager: ClipboardManager? = null
    private var clipListener: ClipboardManager.OnPrimaryClipChangedListener? = null

    private val mainHandler = Handler(Looper.getMainLooper())
    private var autoCollapseRunnable: Runnable? = null
    private var lastHandledUrl: String? = null
    private var currentDetectedUrl: String? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "onCreate: starting FloatingBubbleService")

        if (!Settings.canDrawOverlays(this)) {
            Log.w(TAG, "Cannot start bubble service: SYSTEM_ALERT_WINDOW permission missing")
            stopSelf()
            return
        }

        activeInstance = this
        startInForeground()
        setupFloatingView()
        setupClipboardListener()
        isRunning = true
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_STOP -> {
                stopSelf()
                return START_NOT_STICKY
            }
            ACTION_TEST_ALERT -> {
                val testUrl = intent.getStringExtra("url") ?: "https://shopee.vn/product/demo-sale-1111"
                triggerSaleAlert(testUrl, isSimulated = true)
            }
            ACTION_LINGERING_ALERT -> {
                val title = intent.getStringExtra("title")
                val price = intent.getStringExtra("price")
                val pkg = intent.getStringExtra("package")
                val shop = intent.getStringExtra("shopName")
                val url = intent.getStringExtra("url")
                val img = intent.getStringExtra("imageUrl")
                handleLingeringAlert(title, price, pkg, shop, url, img)
            }
            ACTION_TEST_PULSE_ALERT -> {
                val title = intent.getStringExtra("title") ?: "Tai nghe không dây Bluetooth chống ồn"
                val price = intent.getStringExtra("price") ?: "120.000 đ"
                val shop = intent.getStringExtra("shopName") ?: "Baseus Official Store"
                val url = intent.getStringExtra("url") ?: "https://shopee.vn/search?keyword=Tai+nghe+Bluetooth+Baseus"
                handleLingeringAlert(title, price, "com.shopee.vn", shop, url)
            }
        }
        return START_STICKY
    }

    private fun startInForeground() {
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Why I Buy Shopping Guardian",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Bong bóng cảnh báo không mua vội khi lướt Shopee/Lazada"
                setShowBadge(false)
            }
            notificationManager.createNotificationChannel(channel)
        }

        val appIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            appIntent,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0
        )

        val notification = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_ID)
                .setContentTitle("Why I Buy - Trợ lý mua sắm")
                .setContentText("Bong bóng cảnh báo đang hoạt động trên màn hình")
                .setSmallIcon(android.R.drawable.ic_dialog_info)
                .setContentIntent(pendingIntent)
                .build()
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
                .setContentTitle("Why I Buy - Trợ lý mua sắm")
                .setContentText("Bong bóng cảnh báo đang hoạt động")
                .setSmallIcon(android.R.drawable.ic_dialog_info)
                .setContentIntent(pendingIntent)
                .build()
        }

        startForeground(NOTIFICATION_ID, notification)
    }

    private fun dpToPx(dp: Float): Int {
        return TypedValue.applyDimension(
            TypedValue.COMPLEX_UNIT_DIP,
            dp,
            resources.displayMetrics
        ).toInt()
    }

    private fun setupFloatingView() {
        windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager

        val layoutType = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            @Suppress("DEPRECATION")
            WindowManager.LayoutParams.TYPE_PHONE
        }

        val bubbleSize = dpToPx(54f)
        val params = WindowManager.LayoutParams(
            bubbleSize,
            bubbleSize,
            layoutType,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.TOP or Gravity.START
            x = 24
            y = dpToPx(160f)
        }
        windowLayoutParams = params

        // Root container (Horizontal: Bubble + Callout card)
        rootView = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            clipChildren = false
            clipToPadding = false
        }

        // 1. Circular Bubble Frame (54dp x 54dp) — No shadow, official Why I Buy brand logo
        bubbleView = FrameLayout(this).apply {
            layoutParams = LinearLayout.LayoutParams(bubbleSize, bubbleSize)
            elevation = 0f

            // Official Why I Buy app icon
            val logoImg = ImageView(context).apply {
                setImageResource(R.drawable.brand_logo)
                scaleType = ImageView.ScaleType.FIT_CENTER
                layoutParams = FrameLayout.LayoutParams(
                    FrameLayout.LayoutParams.MATCH_PARENT,
                    FrameLayout.LayoutParams.MATCH_PARENT
                )
            }
            addView(logoImg)

            // Red notification alert badge dot (12dp x 12dp)
            val badgeSize = dpToPx(12f)
            badgeDot = View(context).apply {
                layoutParams = FrameLayout.LayoutParams(badgeSize, badgeSize).apply {
                    gravity = Gravity.TOP or Gravity.END
                    topMargin = dpToPx(2f)
                    rightMargin = dpToPx(2f)
                }
                val dotBg = GradientDrawable().apply {
                    shape = GradientDrawable.OVAL
                    setColor(Color.parseColor("#FF3B30"))
                    setStroke(dpToPx(1.5f), Color.WHITE)
                }
                background = dotBg
                visibility = View.GONE
            }
            addView(badgeDot)
        }
        rootView?.addView(bubbleView)

        // 2. Expandable Callout Card (Initially GONE) — Flat, no shadow
        val cardWidth = dpToPx(270f)
        calloutCard = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            layoutParams = LinearLayout.LayoutParams(cardWidth, LinearLayout.LayoutParams.WRAP_CONTENT).apply {
                marginStart = dpToPx(8f)
            }
            val cardBg = GradientDrawable().apply {
                shape = GradientDrawable.RECTANGLE
                cornerRadius = dpToPx(16f).toFloat()
                setColor(Color.parseColor("#1C2026")) // Dark card surface
                setStroke(dpToPx(1.5f), Color.parseColor("#FFDE02")) // Gold accent border
            }
            background = cardBg
            val p = dpToPx(12f)
            setPadding(p, p, p, p)
            elevation = 0f
            visibility = View.GONE

            // Header row: Title + Close button
            val headerRow = LinearLayout(context).apply {
                orientation = LinearLayout.HORIZONTAL
                gravity = Gravity.CENTER_VERTICAL
                layoutParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT
                )

                calloutTitle = TextView(context).apply {
                    text = "🛑 Đừng mua vội!"
                    setTextColor(Color.parseColor("#FFDE02"))
                    textSize = 14f
                    typeface = Typeface.DEFAULT_BOLD
                    layoutParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1.0f)
                }
                addView(calloutTitle)

                val closeBtn = TextView(context).apply {
                    text = "✕"
                    setTextColor(Color.parseColor("#9E9E9E"))
                    textSize = 15f
                    typeface = Typeface.DEFAULT_BOLD
                    val cp = dpToPx(4f)
                    setPadding(cp, 0, cp, 0)
                    setOnClickListener {
                        hideCallout()
                    }
                }
                addView(closeBtn)
            }
            addView(headerRow)

            // Body text
            calloutBody = TextView(context).apply {
                text = "Sắp có đợt giảm giá & voucher tốt hơn. Hãy lưu vào Why I Buy để giữ giá và kích hoạt 48h suy nghĩ!"
                setTextColor(Color.parseColor("#E0E0E0"))
                textSize = 11.5f
                layoutParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT
                ).apply {
                    topMargin = dpToPx(6f)
                }
            }
            addView(calloutBody)

            // URL snippet text
            calloutUrlText = TextView(context).apply {
                setTextColor(Color.parseColor("#FFDE02"))
                textSize = 10f
                maxLines = 1
                ellipsize = TextUtils.TruncateAt.END
                visibility = View.GONE
                layoutParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT
                ).apply {
                    topMargin = dpToPx(4f)
                }
            }
            addView(calloutUrlText)

            // Action button (Row: Icon + Text centered together)
            calloutActionBtn = LinearLayout(context).apply {
                orientation = LinearLayout.HORIZONTAL
                gravity = Gravity.CENTER
                val btnBg = GradientDrawable().apply {
                    shape = GradientDrawable.RECTANGLE
                    cornerRadius = dpToPx(8f).toFloat()
                    setColor(Color.parseColor("#FFDE02"))
                }
                background = btnBg
                val bp = dpToPx(8f)
                setPadding(bp, bp, bp, bp)
                layoutParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT
                ).apply {
                    topMargin = dpToPx(10f)
                }

                val iconSize = dpToPx(16f)
                calloutActionIcon = ImageView(context).apply {
                    setImageResource(R.drawable.ic_shopping_cart)
                    layoutParams = LinearLayout.LayoutParams(iconSize, iconSize).apply {
                        marginEnd = dpToPx(6f)
                    }
                }
                addView(calloutActionIcon)

                calloutActionText = TextView(context).apply {
                    text = "Lưu vào Wishlist Why I Buy"
                    setTextColor(Color.parseColor("#111111"))
                    textSize = 12f
                    typeface = Typeface.DEFAULT_BOLD
                }
                addView(calloutActionText)
            }
            setActionButtonWithCart("Lưu vào Wishlist Why I Buy") {
                openWhyIBuyWithLink(currentDetectedUrl)
            }
            addView(calloutActionBtn)
        }
        rootView?.addView(calloutCard)

        // Setup Drag & Click handler for the bubble
        setupTouchListener()

        windowManager?.addView(rootView, params)
    }

    private fun setupTouchListener() {
        var initialX = 0
        var initialY = 0
        var initialTouchX = 0f
        var initialTouchY = 0f
        var isDragging = false

        bubbleView?.setOnTouchListener { _, event ->
            val params = windowLayoutParams ?: return@setOnTouchListener false
            when (event.action) {
                MotionEvent.ACTION_DOWN -> {
                    initialX = params.x
                    initialY = params.y
                    initialTouchX = event.rawX
                    initialTouchY = event.rawY
                    isDragging = false
                    true
                }
                MotionEvent.ACTION_MOVE -> {
                    val dx = event.rawX - initialTouchX
                    val dy = event.rawY - initialTouchY
                    if (hypot(dx.toDouble(), dy.toDouble()) > 10) {
                        isDragging = true
                    }
                    if (isDragging) {
                        params.x = initialX + dx.toInt()
                        params.y = initialY + dy.toInt()
                        windowManager?.updateViewLayout(rootView, params)
                    }
                    true
                }
                MotionEvent.ACTION_UP -> {
                    if (!isDragging) {
                        onBubbleClicked()
                    }
                    true
                }
                else -> false
            }
        }
    }

    private fun onBubbleClicked() {
        if (calloutCard?.visibility == View.VISIBLE) {
            hideCallout()
            return
        }

        // 1. If Accessibility Service is running, immediately capture product on screen
        val a11y = ShoppingAccessibilityService.activeInstance
        if (a11y != null && ShoppingAccessibilityService.isServiceConnected) {
            val prod = a11y.captureCurrentProduct()
            if (!prod.title.isNullOrBlank() || !prod.price.isNullOrBlank()) {
                handleLingeringAlert(
                    title = prod.title,
                    price = prod.price,
                    packageName = a11y.currentPackage,
                    shopName = prod.shopName,
                    url = prod.url,
                    imageUrl = prod.imageUrl
                )
                return
            }
        }

        // 2. Tapping the bubble inspects current clipboard content
        val copied = inspectClipboardText()
        if (isEcommerceLink(copied)) {
            triggerSaleAlert(copied!!, isSimulated = false)
            return
        }

        // 3. Fallback: prompt card
        showPromptCallout()
    }

    private fun setActionButtonWithCart(buttonText: String, onClick: () -> Unit) {
        calloutActionText?.text = buttonText
        calloutActionBtn?.setOnClickListener {
            onClick()
            hideCallout()
        }
    }

    private fun openAccessibilitySettings() {
        try {
            val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            startActivity(intent)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to open accessibility settings: ${e.message}")
        }
    }

    private fun showPromptCallout() {
        calloutTitle?.text = "Trợ lý Why I Buy"
        val isA11yActive = ShoppingAccessibilityService.isServiceConnected
        if (!isA11yActive) {
            calloutBody?.text = "Bạn chưa bật quyền Hỗ trợ tiếp cận để Why I Buy tự đọc tên & giá món này. Hãy bấm 'Bật hỗ trợ tiếp cận' bên dưới hoặc bấm 'Sao chép liên kết' trên Shopee!"
            calloutUrlText?.visibility = View.GONE
            setActionButtonWithCart("Bật Hỗ trợ tiếp cận") {
                openAccessibilitySettings()
            }
        } else {
            calloutBody?.text = "Đang theo dõi sản phẩm. Khi bạn xem một món đồ, chỉ cần bấm 'Sao chép liên kết' (Copy link) hoặc chạm vào đây để Why I Buy giữ giá!"
            calloutUrlText?.visibility = View.GONE
            setActionButtonWithCart("Mở Why I Buy") {
                openWhyIBuyWithLink(null)
            }
        }
        showCallout(autoHideSeconds = 8)
    }

    private fun showCallout(autoHideSeconds: Int = 8) {
        mainHandler.post {
            calloutCard?.visibility = View.VISIBLE
            badgeDot?.visibility = View.GONE

            rootView?.let { root ->
                windowLayoutParams?.let { params ->
                    try {
                        params.width = dpToPx(340f)
                        params.height = WindowManager.LayoutParams.WRAP_CONTENT
                        windowManager?.updateViewLayout(root, params)
                    } catch (e: Exception) {
                        Log.w(TAG, "updateViewLayout failed: ${e.message}")
                    }
                }
            }

            autoCollapseRunnable?.let { mainHandler.removeCallbacks(it) }
            autoCollapseRunnable = Runnable {
                hideCallout()
            }
            if (autoHideSeconds > 0) {
                mainHandler.postDelayed(autoCollapseRunnable!!, (autoHideSeconds * 1000).toLong())
            }
        }
    }

    private fun hideCallout() {
        mainHandler.post {
            autoCollapseRunnable?.let { mainHandler.removeCallbacks(it) }
            calloutCard?.visibility = View.GONE
            rootView?.let { root ->
                windowLayoutParams?.let { params ->
                    try {
                        params.width = dpToPx(54f)
                        params.height = dpToPx(54f)
                        windowManager?.updateViewLayout(root, params)
                    } catch (e: Exception) {
                        Log.w(TAG, "updateViewLayout failed: ${e.message}")
                    }
                }
            }
        }
    }

    private fun setupClipboardListener() {
        clipboardManager = getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
        clipListener = ClipboardManager.OnPrimaryClipChangedListener {
            val text = inspectClipboardText()
            if (isEcommerceLink(text) && text != lastHandledUrl) {
                lastHandledUrl = text
                Log.d(TAG, "Ecommerce link detected from clipboard: $text")
                mainHandler.post {
                    triggerSaleAlert(text!!, isSimulated = false)
                }
            }
        }
        clipboardManager?.addPrimaryClipChangedListener(clipListener)
    }

    private fun inspectClipboardText(): String? {
        try {
            val cm = clipboardManager ?: return null
            if (!cm.hasPrimaryClip()) return null
            val desc = cm.primaryClipDescription ?: return null
            if (!desc.hasMimeType(ClipDescription.MIMETYPE_TEXT_PLAIN) &&
                !desc.hasMimeType(ClipDescription.MIMETYPE_TEXT_HTML)) {
                return null
            }
            val item = cm.primaryClip?.getItemAt(0) ?: return null
            return item.text?.toString()?.trim() ?: item.uri?.toString()?.trim()
        } catch (e: Exception) {
            Log.e(TAG, "Error inspecting clipboard: ${e.message}")
            return null
        }
    }

    private fun isEcommerceLink(text: String?): Boolean {
        if (text.isNullOrBlank()) return false
        val lower = text.lowercase()
        return lower.contains("shopee.vn") ||
            lower.contains("shp.ee") ||
            lower.contains("lazada.vn") ||
            lower.contains("tiki.vn") ||
            lower.contains("tiktok.com")
    }

    fun triggerSaleAlert(url: String, isSimulated: Boolean) {
        currentDetectedUrl = url
        badgeDot?.visibility = View.VISIBLE

        pulseBubble()
        vibrateShort()

        calloutTitle?.text = "🛑 Đừng mua vội! Sắp có sale"
        calloutBody?.text = "Món này sắp có voucher & ưu đãi lớn. Hãy lưu vào Wishlist Why I Buy để kích hoạt 48h suy nghĩ và tránh mua hớ!"
        calloutUrlText?.apply {
            text = url
            visibility = View.VISIBLE
        }
        setActionButtonWithCart("Lưu vào Wishlist Why I Buy") {
            openWhyIBuyWithLink(currentDetectedUrl)
        }

        showCallout(autoHideSeconds = 8)
    }

    fun handleLingeringAlert(
        title: String?,
        price: String?,
        packageName: String?,
        shopName: String? = null,
        url: String? = null,
        imageUrl: String? = null
    ) {
        mainHandler.post {
            badgeDot?.visibility = View.VISIBLE
            pulseBubble()
            vibrateBreathingPulse()

            calloutTitle?.text = "🛑 Dừng lại 1 chút! Đừng mua vội"
            calloutBody?.text = "Bạn đang xem và cân nhắc món này khá kỹ. Bạn đang thực sự CẦN hay chỉ là cảm xúc nhất thời? Hãy lưu lại để suy nghĩ thêm nhé!"

            val infoList = mutableListOf<String>()
            if (!title.isNullOrBlank()) infoList.add(title.take(45))
            if (!shopName.isNullOrBlank()) infoList.add("Shop: $shopName")
            if (!price.isNullOrBlank()) infoList.add(price)

            if (infoList.isNotEmpty()) {
                calloutUrlText?.apply {
                    text = infoList.joinToString(" • ")
                    visibility = View.VISIBLE
                }
            } else {
                calloutUrlText?.visibility = View.GONE
            }

            setActionButtonWithCart("Lưu vào Wishlist Why I Buy") {
                openWhyIBuyWithProduct(
                    title = title,
                    price = price,
                    shopName = shopName,
                    url = url,
                    imageUrl = imageUrl,
                    packageName = packageName
                )
            }

            showCallout(autoHideSeconds = 8)
        }
    }

    private fun pulseBubble() {
        val bubble = bubbleView ?: return
        mainHandler.post {
            val scaleX = PropertyValuesHolder.ofFloat(View.SCALE_X, 1.0f, 1.25f, 0.95f, 1.15f, 1.0f)
            val scaleY = PropertyValuesHolder.ofFloat(View.SCALE_Y, 1.0f, 1.25f, 0.95f, 1.15f, 1.0f)
            ObjectAnimator.ofPropertyValuesHolder(bubble, scaleX, scaleY).apply {
                duration = 1000
                repeatCount = 1
                interpolator = AccelerateDecelerateInterpolator()
                start()
            }
        }
    }

    private fun vibrateBreathingPulse() {
        try {
            val v = getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val timings = longArrayOf(0, 100, 120, 120)
                val amplitudes = intArrayOf(0, 180, 0, 220)
                v?.vibrate(VibrationEffect.createWaveform(timings, amplitudes, -1))
            } else {
                @Suppress("DEPRECATION")
                v?.vibrate(longArrayOf(0, 100, 120, 120), -1)
            }
        } catch (e: Exception) {
            Log.w(TAG, "Pulse vibration failed: ${e.message}")
        }
    }

    private fun vibrateShort() {
        try {
            val v = getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                v?.vibrate(VibrationEffect.createOneShot(120, VibrationEffect.DEFAULT_AMPLITUDE))
            } else {
                @Suppress("DEPRECATION")
                v?.vibrate(120)
            }
        } catch (e: Exception) {
            Log.w(TAG, "Vibration failed: ${e.message}")
        }
    }

    private fun openWhyIBuyWithProduct(
        title: String?,
        price: String?,
        shopName: String?,
        url: String?,
        imageUrl: String?,
        packageName: String?
    ) {
        try {
            val clipText = inspectClipboardText()
            val resolvedUrl = when {
                !url.isNullOrBlank() -> url
                isEcommerceLink(clipText) -> clipText
                !title.isNullOrBlank() -> "https://shopee.vn/search?keyword=" + Uri.encode(title)
                else -> null
            }

            val shareText = buildString {
                if (!title.isNullOrBlank()) append(title)
                if (!shopName.isNullOrBlank()) append(" - Shop: ").append(shopName)
                if (!price.isNullOrBlank()) append(" - Giá: ").append(price)
                if (!resolvedUrl.isNullOrBlank()) append("\n").append(resolvedUrl)
            }.takeIf { it.isNotBlank() } ?: "Sản phẩm đang xem trên $packageName"

            val intent = Intent(this, MainActivity::class.java).apply {
                action = Intent.ACTION_SEND
                type = "text/plain"
                putExtra(Intent.EXTRA_TEXT, shareText)
                if (!title.isNullOrBlank()) putExtra("item_title", title)
                if (!price.isNullOrBlank()) putExtra("item_price", price)
                if (!shopName.isNullOrBlank()) putExtra("item_shop", shopName)
                if (!resolvedUrl.isNullOrBlank()) putExtra("item_url", resolvedUrl)
                if (!imageUrl.isNullOrBlank()) putExtra("item_image", imageUrl)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
            }
            startActivity(intent)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to launch Why I Buy: ${e.message}")
        }
    }

    private fun openWhyIBuyWithLink(url: String?) {
        try {
            val textToSend = if (!url.isNullOrBlank()) url else "Sản phẩm cần cân nhắc"
            val intent = Intent(this, MainActivity::class.java).apply {
                action = Intent.ACTION_SEND
                type = "text/plain"
                putExtra(Intent.EXTRA_TEXT, textToSend)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
            }
            startActivity(intent)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to launch Why I Buy: ${e.message}")
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        Log.d(TAG, "onDestroy: cleaning up FloatingBubbleService")
        activeInstance = null
        isRunning = false
        autoCollapseRunnable?.let { mainHandler.removeCallbacks(it) }

        clipListener?.let {
            clipboardManager?.removePrimaryClipChangedListener(it)
        }

        rootView?.let {
            try {
                windowManager?.removeView(it)
            } catch (e: Exception) {
                Log.w(TAG, "Error removing root view: ${e.message}")
            }
        }
        rootView = null
    }
}

