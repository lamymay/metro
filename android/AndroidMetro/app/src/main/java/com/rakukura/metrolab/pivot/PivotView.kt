package com.rakukura.metrolab.pivot

import android.content.Context
import android.view.MotionEvent
import android.view.VelocityTracker
import android.view.View
import android.view.ViewConfiguration
import android.view.ViewGroup
import android.widget.LinearLayout
import com.rakukura.metrolab.motion.MetroEase
import com.rakukura.metrolab.motion.MetroMotion
import com.rakukura.metrolab.motion.TiltController
import com.rakukura.metrolab.theme.MetroRole
import com.rakukura.metrolab.theme.MetroTheme
import com.rakukura.metrolab.widget.MetroTextView
import kotlin.math.abs
import kotlin.math.roundToInt

class PivotItem(val header: String, val content: (Context) -> View)

/**
 * The WP pivot: a carousel of oversized header words with the content sliding beneath.
 *
 * The detail that makes it a pivot rather than a tab bar is that the header and the
 * content move at *different times* — the header leads, the content follows a beat
 * later. [MetroMotion.pivotContentDelay] is that beat.
 *
 * Known simplification: WP's pivot wrapped past the last item. This one clamps.
 */
class PivotView(context: Context, private val items: List<PivotItem>, title: String?) : ViewGroup(context) {

    private val headerRow = LinearLayout(context)
    private val contentRow = LinearLayout(context)
    private val titleView: MetroTextView? =
        if (title == null) null
        else MetroTextView(context, MetroRole.APPLICATION_TITLE).apply { text = title.uppercase() }

    private val headerViews = ArrayList<MetroTextView>()

    /** Continuous item positions, in item units. */
    private var headerPos = 0f
    private var contentPos = 0f

    private var dragStart = 0f
    private var dragging = false
    private var downX = 0f
    private var downY = 0f
    private val touchSlop = ViewConfiguration.get(context).scaledTouchSlop
    private var velocity: VelocityTracker? = null

    private val headerSpacing = MetroTheme.dpInt(20f)

    init {
        clipChildren = true
        headerRow.orientation = LinearLayout.HORIZONTAL
        contentRow.orientation = LinearLayout.HORIZONTAL

        titleView?.let { addView(it) }
        addView(headerRow)
        addView(contentRow)

        for ((index, item) in items.withIndex()) {
            val header = MetroTextView(context, MetroRole.PIVOT_HEADER).apply { text = item.header }
            headerViews.add(header)
            TiltController(header) { goTo(index) }.attach()
            val lp = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            )
            if (index > 0) lp.leftMargin = headerSpacing
            headerRow.addView(header, lp)

            contentRow.addView(
                item.content(context),
                LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.MATCH_PARENT)
            )
        }
        updateHeaderAlpha()
    }

    // ---- Layout ----

    override fun onMeasure(widthMeasureSpec: Int, heightMeasureSpec: Int) {
        val width = MeasureSpec.getSize(widthMeasureSpec)
        val height = MeasureSpec.getSize(heightMeasureSpec)

        var top = 0
        titleView?.let {
            it.measure(
                MeasureSpec.makeMeasureSpec(width, MeasureSpec.AT_MOST),
                MeasureSpec.makeMeasureSpec(0, MeasureSpec.UNSPECIFIED)
            )
            top += it.measuredHeight + MetroTheme.dpInt(12f)
        }

        headerRow.measure(
            MeasureSpec.makeMeasureSpec(0, MeasureSpec.UNSPECIFIED),
            MeasureSpec.makeMeasureSpec(0, MeasureSpec.UNSPECIFIED)
        )
        top += headerRow.measuredHeight + MetroTheme.dpInt(8f)

        for (i in 0 until contentRow.childCount) {
            contentRow.getChildAt(i).layoutParams.width = width
        }
        contentRow.measure(
            MeasureSpec.makeMeasureSpec(width * items.size, MeasureSpec.EXACTLY),
            MeasureSpec.makeMeasureSpec((height - top).coerceAtLeast(0), MeasureSpec.EXACTLY)
        )

        setMeasuredDimension(width, height)
    }

    override fun onLayout(changed: Boolean, l: Int, t: Int, r: Int, b: Int) {
        val width = r - l
        val margin = MetroTheme.pageMargin.toInt()
        var top = 0

        titleView?.let {
            it.layout(margin, MetroTheme.dpInt(10f), margin + it.measuredWidth, MetroTheme.dpInt(10f) + it.measuredHeight)
            top = MetroTheme.dpInt(10f) + it.measuredHeight + MetroTheme.dpInt(8f)
        }

        headerRow.layout(margin, top, margin + headerRow.measuredWidth, top + headerRow.measuredHeight)
        top += headerRow.measuredHeight + MetroTheme.dpInt(8f)

        contentRow.layout(0, top, width * items.size, top + contentRow.measuredHeight)
        applyPositions()
    }

    private fun applyPositions() {
        headerRow.translationX = -interpolatedHeaderOffset(headerPos)
        contentRow.translationX = -contentPos * width
        updateHeaderAlpha()
    }

    /** Neighbours dim rather than disappear; that is how a pivot advertises its sides. */
    private fun updateHeaderAlpha() {
        for ((index, view) in headerViews.withIndex()) {
            val distance = abs(index - headerPos)
            view.alpha = if (distance < 0.001f) 1f else maxOf(0.4f, 1f - distance * 0.55f)
        }
    }

    private fun headerOffset(index: Int): Float {
        var x = 0f
        for (i in 0 until index.coerceIn(0, headerViews.size)) {
            x += headerViews[i].width + headerSpacing
        }
        return x
    }

    private fun interpolatedHeaderOffset(position: Float): Float {
        val low = position.toInt().coerceIn(0, (items.size - 1).coerceAtLeast(0))
        val high = (low + 1).coerceAtMost((items.size - 1).coerceAtLeast(0))
        val t = position - low
        val a = headerOffset(low)
        val b = headerOffset(high)
        return a + (b - a) * t
    }

    // ---- Gesture ----

    override fun onInterceptTouchEvent(event: MotionEvent): Boolean {
        when (event.actionMasked) {
            MotionEvent.ACTION_DOWN -> {
                downX = event.x
                downY = event.y
                dragging = false
            }
            MotionEvent.ACTION_MOVE -> {
                val dx = event.x - downX
                val dy = event.y - downY
                if (abs(dx) > touchSlop && abs(dx) > abs(dy)) {
                    beginDrag()
                    return true
                }
            }
        }
        return false
    }

    override fun onTouchEvent(event: MotionEvent): Boolean {
        val tracker = velocity ?: VelocityTracker.obtain().also { velocity = it }
        tracker.addMovement(event)

        when (event.actionMasked) {
            MotionEvent.ACTION_DOWN -> {
                downX = event.x
                downY = event.y
                return true
            }
            MotionEvent.ACTION_MOVE -> {
                if (!dragging && abs(event.x - downX) > touchSlop) beginDrag()
                if (dragging && width > 0) {
                    // Rubber-band a little past both ends rather than hard-stopping.
                    val raw = dragStart - (event.x - downX) / width
                    val clamped = raw.coerceIn(-0.35f, (items.size - 1) + 0.35f)
                    headerPos = clamped
                    contentPos = clamped
                    applyPositions()
                }
                return true
            }
            MotionEvent.ACTION_UP, MotionEvent.ACTION_CANCEL -> {
                if (dragging && width > 0) {
                    tracker.computeCurrentVelocity(1000)
                    val flick = -tracker.xVelocity / width * 0.25f
                    goTo((contentPos + flick).roundToInt())
                }
                dragging = false
                velocity?.recycle()
                velocity = null
                return true
            }
        }
        return super.onTouchEvent(event)
    }

    private fun beginDrag() {
        dragging = true
        dragStart = contentPos
        parent?.requestDisallowInterceptTouchEvent(true)
    }

    fun goTo(rawIndex: Int) {
        val target = rawIndex.coerceIn(0, (items.size - 1).coerceAtLeast(0)).toFloat()

        animateValue(headerPos, target, MetroMotion.duration(MetroMotion.pivotHeaderDuration), 0L) {
            headerPos = it
            applyPositions()
        }
        // The content lags the header. Everything else about a pivot follows from this.
        animateValue(
            contentPos, target,
            MetroMotion.duration(MetroMotion.pivotContentDuration),
            MetroMotion.duration(MetroMotion.pivotContentDelay)
        ) {
            contentPos = it
            applyPositions()
        }
    }

    private fun animateValue(from: Float, to: Float, duration: Long, delay: Long, apply: (Float) -> Unit) {
        val anim = android.animation.ValueAnimator.ofFloat(from, to)
        anim.duration = duration
        anim.startDelay = delay
        anim.interpolator = MetroEase.wpIn
        anim.addUpdateListener { apply(it.animatedValue as Float) }
        anim.start()
    }
}
