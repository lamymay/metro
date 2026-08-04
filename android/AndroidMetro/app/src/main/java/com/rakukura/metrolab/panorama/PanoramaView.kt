package com.rakukura.metrolab.panorama

import android.content.Context
import android.graphics.Canvas
import android.graphics.LinearGradient
import android.graphics.Paint
import android.graphics.Shader
import android.view.MotionEvent
import android.view.VelocityTracker
import android.view.View
import android.view.ViewConfiguration
import android.view.ViewGroup
import android.widget.LinearLayout
import com.rakukura.metrolab.motion.MetroEase
import com.rakukura.metrolab.motion.MetroMotion
import com.rakukura.metrolab.theme.MetroRole
import com.rakukura.metrolab.theme.MetroTheme
import com.rakukura.metrolab.widget.MetroTextView
import kotlin.math.abs
import kotlin.math.roundToInt

class PanoramaSection(val title: String, val content: (Context) -> View)

/**
 * The WP panorama: one long canvas seen through a phone-sized window, with three layers
 * moving at three different rates.
 *
 * The layering is the whole idea — background slowest, title next, sections at 1:1 — and
 * the sections are deliberately *narrower* than the screen so the next one always peeks
 * in from the right. Get the peek wrong and it stops reading as a panorama.
 *
 * Known simplification: WP's panorama wrapped infinitely. This one clamps at both ends.
 */
class PanoramaView(
    context: Context,
    private val sections: List<PanoramaSection>,
    title: String,
    private val peek: Float = MetroTheme.dp(48f)
) : ViewGroup(context) {

    private val backgroundView = PanoramaBackground(context)
    private val titleView = MetroTextView(context, MetroRole.PANORAMA_TITLE).apply {
        text = title
        maxLines = 1
    }
    private val sectionRow = LinearLayout(context).apply { orientation = LinearLayout.HORIZONTAL }

    private var scrollX = 0f
    private var dragStart = 0f
    private var dragging = false
    private var downX = 0f
    private var downY = 0f
    private val touchSlop = ViewConfiguration.get(context).scaledTouchSlop
    private var velocity: VelocityTracker? = null

    init {
        clipChildren = true
        addView(backgroundView)
        addView(titleView)
        addView(sectionRow)

        for (section in sections) {
            val column = LinearLayout(context).apply { orientation = LinearLayout.VERTICAL }
            column.addView(MetroTextView(context, MetroRole.TITLE2).apply {
                text = section.title
                setPadding(MetroTheme.pageMargin.toInt(), 0, 0, MetroTheme.dpInt(8f))
            })
            column.addView(
                section.content(context),
                LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT
                )
            )
            sectionRow.addView(
                column,
                LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.MATCH_PARENT)
            )
        }
    }

    private val sectionWidth: Float get() = (width - peek).coerceAtLeast(MetroTheme.dp(120f))
    private val maxScroll: Float get() = ((sections.size - 1) * sectionWidth).coerceAtLeast(0f)

    override fun onMeasure(widthMeasureSpec: Int, heightMeasureSpec: Int) {
        val w = MeasureSpec.getSize(widthMeasureSpec)
        val h = MeasureSpec.getSize(heightMeasureSpec)
        val secW = (w - peek).coerceAtLeast(MetroTheme.dp(120f)).toInt()

        backgroundView.measure(
            MeasureSpec.makeMeasureSpec(w + (maxScrollFor(w) * MetroMotion.panoramaParallax).toInt() + MetroTheme.dpInt(64f), MeasureSpec.EXACTLY),
            MeasureSpec.makeMeasureSpec(h, MeasureSpec.EXACTLY)
        )
        titleView.measure(
            MeasureSpec.makeMeasureSpec(0, MeasureSpec.UNSPECIFIED),
            MeasureSpec.makeMeasureSpec(0, MeasureSpec.UNSPECIFIED)
        )

        for (i in 0 until sectionRow.childCount) {
            sectionRow.getChildAt(i).layoutParams.width = secW
        }
        val top = MetroTheme.dpInt(8f) + titleView.measuredHeight
        sectionRow.measure(
            MeasureSpec.makeMeasureSpec(secW * sections.size, MeasureSpec.EXACTLY),
            MeasureSpec.makeMeasureSpec((h - top).coerceAtLeast(0), MeasureSpec.EXACTLY)
        )
        setMeasuredDimension(w, h)
    }

    private fun maxScrollFor(width: Int): Float {
        val secW = (width - peek).coerceAtLeast(MetroTheme.dp(120f))
        return ((sections.size - 1) * secW).coerceAtLeast(0f)
    }

    override fun onLayout(changed: Boolean, l: Int, t: Int, r: Int, b: Int) {
        backgroundView.layout(0, 0, backgroundView.measuredWidth, measuredHeight)
        val titleTop = MetroTheme.dpInt(4f)
        titleView.layout(
            MetroTheme.pageMargin.toInt(), titleTop,
            MetroTheme.pageMargin.toInt() + titleView.measuredWidth, titleTop + titleView.measuredHeight
        )
        val top = MetroTheme.dpInt(8f) + titleView.measuredHeight
        sectionRow.layout(0, top, sectionRow.measuredWidth, top + sectionRow.measuredHeight)
        applyOffsets()
    }

    private fun applyOffsets() {
        backgroundView.translationX = -scrollX * MetroMotion.panoramaParallax
        titleView.translationX = -scrollX * MetroMotion.panoramaTitleParallax
        sectionRow.translationX = -scrollX
    }

    override fun onInterceptTouchEvent(event: MotionEvent): Boolean {
        when (event.actionMasked) {
            MotionEvent.ACTION_DOWN -> {
                downX = event.x; downY = event.y; dragging = false
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
                downX = event.x; downY = event.y
                return true
            }
            MotionEvent.ACTION_MOVE -> {
                if (!dragging && abs(event.x - downX) > touchSlop) beginDrag()
                if (dragging) {
                    scrollX = (dragStart - (event.x - downX)).coerceIn(0f, maxScroll)
                    applyOffsets()
                }
                return true
            }
            MotionEvent.ACTION_UP, MotionEvent.ACTION_CANCEL -> {
                if (dragging) {
                    tracker.computeCurrentVelocity(1000)
                    // Predict where the flick was heading, then snap to the nearest section.
                    val predicted = scrollX - tracker.xVelocity * 0.15f
                    val index = (predicted / sectionWidth).roundToInt()
                        .coerceIn(0, (sections.size - 1).coerceAtLeast(0))
                    animateTo(index * sectionWidth)
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
        dragStart = scrollX
        parent?.requestDisallowInterceptTouchEvent(true)
    }

    private fun animateTo(target: Float) {
        val anim = android.animation.ValueAnimator.ofFloat(scrollX, target.coerceIn(0f, maxScroll))
        anim.duration = MetroMotion.duration(MetroMotion.panoramaSnapDuration)
        anim.interpolator = MetroEase.wpIn
        anim.addUpdateListener {
            scrollX = it.animatedValue as Float
            applyOffsets()
        }
        anim.start()
    }
}

/**
 * A stand-in for the photographic backgrounds WP panoramas shipped with: an accent wash
 * plus a sparse grid, drawn rather than bundled so the app stays asset-free.
 */
private class PanoramaBackground(context: Context) : View(context) {

    private val paint = Paint(Paint.ANTI_ALIAS_FLAG)
    private var gradient: LinearGradient? = null

    override fun onSizeChanged(w: Int, h: Int, oldw: Int, oldh: Int) {
        gradient = LinearGradient(
            0f, 0f, w.toFloat(), h.toFloat(),
            MetroTheme.withAlpha(MetroTheme.accentColor, 0.55f),
            MetroTheme.withAlpha(MetroTheme.accentColor, 0.04f),
            Shader.TileMode.CLAMP
        )
    }

    override fun onDraw(canvas: Canvas) {
        val w = width.toFloat()
        val h = height.toFloat()

        paint.shader = null
        paint.style = Paint.Style.FILL
        paint.color = MetroTheme.background
        canvas.drawRect(0f, 0f, w, h, paint)

        paint.shader = gradient
        canvas.drawRect(0f, 0f, w, h, paint)
        paint.shader = null

        paint.style = Paint.Style.STROKE
        paint.strokeWidth = 1f
        paint.color = MetroTheme.withAlpha(MetroTheme.foreground, 0.06f)
        val step = MetroTheme.dp(48f)
        var x = 0f
        while (x < w) {
            canvas.drawLine(x, 0f, x, h, paint)
            x += step
        }
        var y = 0f
        while (y < h) {
            canvas.drawLine(0f, y, w, y, paint)
            y += step
        }
    }
}
