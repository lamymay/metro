package com.rakukura.metrolab.widget

import android.content.Context
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.os.SystemClock
import android.text.TextUtils
import android.util.TypedValue
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.ViewGroup
import android.widget.LinearLayout
import android.widget.TextView
import com.rakukura.metrolab.glyph.MetroGlyph
import com.rakukura.metrolab.glyph.MetroGlyphs
import com.rakukura.metrolab.motion.MetroEase
import com.rakukura.metrolab.motion.MetroEaseMode
import com.rakukura.metrolab.motion.MetroMotion
import com.rakukura.metrolab.motion.TiltController
import com.rakukura.metrolab.theme.MetroRole
import com.rakukura.metrolab.theme.MetroTheme
import kotlin.math.cos
import kotlin.math.sin

/** A `TextView` wired to one of WP's named text styles. */
class MetroTextView(context: Context, role: MetroRole = MetroRole.NORMAL) : TextView(context) {

    var role: MetroRole = role
        set(value) {
            field = value
            applyRole()
        }

    init {
        applyRole()
    }

    private fun applyRole() {
        setTextSize(TypedValue.COMPLEX_UNIT_PX, MetroTheme.textSize(role))
        typeface = MetroTheme.typeface(role.weight)
        setTextColor(MetroTheme.colorFor(role))
        includeFontPadding = false
        if (role == MetroRole.APPLICATION_TITLE) {
            // WP tracked the application title out by about 0.05em and upper-cased it.
            letterSpacingCompat(0.08f)
            transformationMethod = null
        }
    }

    private fun letterSpacingCompat(value: Float) {
        // letterSpacing landed in API 21; below that the title simply sits tight, which
        // is a difference nobody has ever noticed on a 4.1 device.
        if (android.os.Build.VERSION.SDK_INT >= 21) letterSpacing = value
    }
}

/** WP page chrome: small tracked-out application title over the lowercase page header. */
class MetroPageHeader(
    context: Context,
    applicationTitle: String?,
    pageTitle: String?
) : LinearLayout(context) {

    init {
        orientation = VERTICAL
        setPadding(
            MetroTheme.pageMargin.toInt(),
            MetroTheme.dpInt(12f),
            MetroTheme.pageMargin.toInt(),
            MetroTheme.dpInt(18f)
        )

        if (applicationTitle != null) {
            addView(MetroTextView(context, MetroRole.APPLICATION_TITLE).apply {
                text = applicationTitle.uppercase()
            })
        }
        if (pageTitle != null) {
            addView(MetroTextView(context, MetroRole.PAGE_TITLE).apply {
                text = pageTitle
                maxLines = 1
                ellipsize = TextUtils.TruncateAt.END
                // The 7dp indent and the negative leading are from the stock
                // PhoneApplicationPage template. They are small, and they are most of
                // why the header reads as Metro rather than as a generic nav bar.
                val lp = LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT)
                lp.leftMargin = MetroTheme.dpInt(5f)
                lp.topMargin = MetroTheme.dpInt(-6f)
                layoutParams = lp
            })
        }
    }
}

/** Draws a single glyph. */
class MetroGlyphView(
    context: Context,
    var glyph: MetroGlyph,
    private var sizePx: Float,
    var tint: Int? = null
) : View(context) {

    override fun onMeasure(widthMeasureSpec: Int, heightMeasureSpec: Int) {
        setMeasuredDimension(sizePx.toInt(), sizePx.toInt())
    }

    override fun onDraw(canvas: Canvas) {
        MetroGlyphs.draw(
            canvas, glyph, width / 2f, height / 2f,
            minOf(width, height).toFloat(), tint ?: MetroTheme.foreground
        )
    }
}

/** The circled icon used on a WP application bar. */
class MetroAppBarIcon(context: Context, var glyph: MetroGlyph, private val diameter: Float) : View(context) {

    private val paint = Paint(Paint.ANTI_ALIAS_FLAG)
    var tint: Int = MetroTheme.foreground

    override fun onMeasure(widthMeasureSpec: Int, heightMeasureSpec: Int) {
        setMeasuredDimension(diameter.toInt(), diameter.toInt())
    }

    override fun onDraw(canvas: Canvas) {
        val r = minOf(width, height) / 2f
        paint.style = Paint.Style.STROKE
        paint.strokeWidth = maxOf(1f, diameter / 24f)
        paint.color = tint
        canvas.drawCircle(width / 2f, height / 2f, r - paint.strokeWidth / 2f, paint)
        MetroGlyphs.draw(canvas, glyph, width / 2f, height / 2f, diameter * 0.52f, tint, 1f / 16f)
    }
}

data class AppBarItem(val glyph: MetroGlyph, val label: String, val action: () -> Unit)
data class AppBarMenuItem(val title: String, val action: () -> Unit)

/**
 * The WP application bar: up to four circled icons, an ellipsis, and a menu that opens
 * upward. Icon labels only appear once it is open — that reveal is the point.
 */
class MetroAppBar(
    context: Context,
    items: List<AppBarItem>,
    private val menuItems: List<AppBarMenuItem> = emptyList()
) : LinearLayout(context) {

    private val iconRow = LinearLayout(context)
    private val menuColumn = LinearLayout(context)
    private val labels = ArrayList<TextView>()
    private var open = false

    init {
        orientation = VERTICAL
        setBackgroundColor(MetroTheme.chrome)

        iconRow.orientation = HORIZONTAL
        iconRow.gravity = Gravity.CENTER_VERTICAL
        addView(
            iconRow,
            LayoutParams(LayoutParams.MATCH_PARENT, MetroTheme.appBarHeight.toInt())
        )

        for (item in items.take(4)) {
            val cell = LinearLayout(context)
            cell.orientation = VERTICAL
            cell.gravity = Gravity.CENTER_HORIZONTAL

            cell.addView(MetroAppBarIcon(context, item.glyph, MetroTheme.dp(38f)))
            val label = MetroTextView(context, MetroRole.SMALL).apply {
                text = item.label
                setTextColor(MetroTheme.foreground)
                setTextSize(TypedValue.COMPLEX_UNIT_PX, MetroTheme.textSize(MetroRole.SMALL) * 0.82f)
                visibility = GONE
            }
            labels.add(label)
            cell.addView(label)

            val tilt = TiltController(cell) { item.action() }
            tilt.attach()

            val lp = LayoutParams(0, LayoutParams.WRAP_CONTENT, 1f)
            iconRow.addView(cell, lp)
        }

        if (menuItems.isNotEmpty()) {
            val more = MetroGlyphView(context, MetroGlyph.ELLIPSIS, MetroTheme.dp(22f))
            val moreCell = LinearLayout(context)
            moreCell.gravity = Gravity.CENTER
            moreCell.addView(more)
            TiltController(moreCell) { toggle() }.attach()
            iconRow.addView(
                moreCell,
                LayoutParams(MetroTheme.dpInt(44f), LayoutParams.MATCH_PARENT)
            )
        }

        menuColumn.orientation = VERTICAL
        menuColumn.visibility = GONE
        for (item in menuItems) {
            val row = MetroTextView(context, MetroRole.NORMAL).apply {
                text = item.title
                setPadding(
                    MetroTheme.dpInt(14f), MetroTheme.dpInt(9f),
                    MetroTheme.dpInt(14f), MetroTheme.dpInt(9f)
                )
            }
            TiltController(row) {
                item.action()
                if (open) toggle()
            }.attach()
            menuColumn.addView(row, LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT))
        }
        addView(menuColumn, LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT))
    }

    private fun toggle() {
        open = !open
        menuColumn.visibility = if (open) VISIBLE else GONE
        for (label in labels) label.visibility = if (open) VISIBLE else GONE
        if (open) {
            for (i in 0 until menuColumn.childCount) {
                com.rakukura.metrolab.motion.MetroFeather.apply(menuColumn.getChildAt(i), i)
            }
        }
    }
}

/** A WP list row: title, optional subtitle, no separator, no chevron, no inset. */
class MetroListRow(
    context: Context,
    title: String,
    subtitle: String? = null,
    glyph: MetroGlyph? = null,
    accessory: String? = null,
    action: (() -> Unit)? = null
) : LinearLayout(context) {

    init {
        orientation = HORIZONTAL
        gravity = Gravity.CENTER_VERTICAL
        setPadding(
            MetroTheme.pageMargin.toInt(), MetroTheme.dpInt(7f),
            MetroTheme.pageMargin.toInt(), MetroTheme.dpInt(7f)
        )

        if (glyph != null) {
            val icon = MetroGlyphView(context, glyph, MetroTheme.dp(26f))
            val lp = LayoutParams(MetroTheme.dpInt(26f), MetroTheme.dpInt(26f))
            lp.rightMargin = MetroTheme.dpInt(12f)
            addView(icon, lp)
        }

        val text = LinearLayout(context)
        text.orientation = VERTICAL
        text.addView(MetroTextView(context, MetroRole.TITLE3).apply {
            this.text = title
            maxLines = 1
            ellipsize = TextUtils.TruncateAt.END
        })
        if (subtitle != null) {
            text.addView(MetroTextView(context, MetroRole.SMALL).apply {
                this.text = subtitle
                maxLines = 1
                ellipsize = TextUtils.TruncateAt.END
            })
        }
        addView(text, LayoutParams(0, LayoutParams.WRAP_CONTENT, 1f))

        if (accessory != null) {
            addView(MetroTextView(context, MetroRole.SMALL).apply { this.text = accessory })
        }

        if (action != null) TiltController(this) { action() }.attach()
    }
}

/** Group header — an accent square with the group's letter, tappable into semantic zoom. */
class MetroGroupHeader(
    context: Context,
    letter: String,
    enabled: Boolean = true,
    action: (() -> Unit)? = null
) : LinearLayout(context) {

    init {
        orientation = HORIZONTAL
        setPadding(MetroTheme.pageMargin.toInt(), MetroTheme.dpInt(12f), 0, MetroTheme.dpInt(3f))

        val square = MetroTextView(context, MetroRole.TITLE3).apply {
            text = letter.uppercase()
            gravity = Gravity.CENTER
            setTextColor(if (enabled) MetroTheme.onAccent else MetroTheme.disabled)
            setBackgroundColor(if (enabled) MetroTheme.accentColor else Color.TRANSPARENT)
        }
        addView(square, LayoutParams(MetroTheme.dpInt(38f), MetroTheme.dpInt(38f)))

        if (enabled && action != null) TiltController(square) { action() }.attach()
    }
}

/**
 * The five-dot indeterminate bar. WP staggered five identical dots along one eased path,
 * which is why they bunch through the middle and thin out at the ends — there is no
 * separate "bunching" animation, it falls out of the curve.
 */
class MetroProgressDots(context: Context) : View(context) {

    private val paint = Paint(Paint.ANTI_ALIAS_FLAG)
    private val ease = MetroEase(MetroEase.Kind.Power(2f), MetroEaseMode.EASE_IN_OUT)
    private val dotCount = 5
    private val travelFraction = 0.62f
    private val stagger = 0.055f

    /** `null` runs the indeterminate sweep; 0…1 draws a solid bar. */
    var value: Float? = null
        set(field2) {
            field = field2
            invalidate()
        }

    override fun onMeasure(widthMeasureSpec: Int, heightMeasureSpec: Int) {
        setMeasuredDimension(MeasureSpec.getSize(widthMeasureSpec), MetroTheme.dpInt(16f))
    }

    override fun onDraw(canvas: Canvas) {
        val w = width.toFloat()
        val cy = height / 2f
        paint.style = Paint.Style.FILL

        val determinate = value
        if (determinate != null) {
            paint.color = MetroTheme.disabled
            canvas.drawRect(0f, cy - MetroTheme.dp(2f), w, cy + MetroTheme.dp(2f), paint)
            paint.color = MetroTheme.accentColor
            canvas.drawRect(
                0f, cy - MetroTheme.dp(2f),
                w * determinate.coerceIn(0f, 1f), cy + MetroTheme.dp(2f), paint
            )
            return
        }

        val period = MetroMotion.duration(MetroMotion.progressDotPeriod).coerceAtLeast(1L)
        val cycle = (SystemClock.uptimeMillis() % period).toFloat() / period
        val radius = MetroTheme.dp(2.5f)
        paint.color = MetroTheme.accentColor

        for (i in 0 until dotCount) {
            var local = cycle - i * stagger
            if (local < 0f) local += 1f
            if (local > travelFraction) continue
            val x = ease.progress(local / travelFraction) * (w - radius * 2f) + radius
            canvas.drawCircle(x, cy, radius, paint)
        }
        postInvalidateOnAnimation()
    }
}

/** WP 8.1's ProgressRing: the same five dots, bent round a circle. */
class MetroProgressRing(context: Context, private val diameter: Float) : View(context) {

    private val paint = Paint(Paint.ANTI_ALIAS_FLAG)
    private val ease = MetroEase(MetroEase.Kind.Power(1.7f), MetroEaseMode.EASE_IN_OUT)
    private val dotCount = 5
    private val stagger = 0.08f

    override fun onMeasure(widthMeasureSpec: Int, heightMeasureSpec: Int) {
        setMeasuredDimension(diameter.toInt(), diameter.toInt())
    }

    override fun onDraw(canvas: Canvas) {
        val period = MetroMotion.duration((MetroMotion.progressDotPeriod * 0.75f).toLong()).coerceAtLeast(1L)
        val cycle = (SystemClock.uptimeMillis() % period).toFloat() / period
        val dot = maxOf(MetroTheme.dp(2f), diameter * 0.055f)
        val radius = (diameter - dot * 2f) / 2f

        paint.style = Paint.Style.FILL
        paint.color = MetroTheme.accentColor

        for (i in 0 until dotCount) {
            var local = cycle - i * stagger
            if (local < 0f) local += 1f
            val angle = ease.progress(local) * 2f * Math.PI.toFloat() - Math.PI.toFloat() / 2f
            canvas.drawCircle(
                width / 2f + cos(angle) * radius,
                height / 2f + sin(angle) * radius,
                dot, paint
            )
        }
        postInvalidateOnAnimation()
    }
}

/**
 * Transparent, bordered, and inverted while pressed — the WP `Button` template swapped
 * `Background` to `PhoneForegroundBrush` and `Foreground` to `PhoneBackgroundBrush`
 * rather than dimming.
 */
class MetroButton(context: Context, label: String, private val action: () -> Unit) : View(context) {

    private val paint = Paint(Paint.ANTI_ALIAS_FLAG)
    private val textPaint = Paint(Paint.ANTI_ALIAS_FLAG)
    private var pressedDown = false
    private val tilt = TiltController(this) { action() }

    var label: String = label
        set(value) {
            field = value
            invalidate()
        }

    init {
        textPaint.textSize = MetroTheme.textSize(MetroRole.NORMAL)
        textPaint.typeface = MetroTheme.typeface(MetroRole.NORMAL.weight)
        textPaint.textAlign = Paint.Align.CENTER
        tilt.attach()
        setOnTouchListener { _, event ->
            when (event.actionMasked) {
                MotionEvent.ACTION_DOWN -> { pressedDown = true; invalidate() }
                MotionEvent.ACTION_UP, MotionEvent.ACTION_CANCEL -> { pressedDown = false; invalidate() }
            }
            tilt.onTouchEvent(event)
        }
    }

    override fun onMeasure(widthMeasureSpec: Int, heightMeasureSpec: Int) {
        val w = (textPaint.measureText(label) + MetroTheme.dp(40f)).toInt()
        setMeasuredDimension(
            resolveSize(maxOf(w, MetroTheme.dpInt(92f)), widthMeasureSpec),
            resolveSize(MetroTheme.dpInt(42f), heightMeasureSpec)
        )
    }

    override fun onDraw(canvas: Canvas) {
        val border = MetroTheme.borderWidth
        if (pressedDown) {
            paint.style = Paint.Style.FILL
            paint.color = MetroTheme.foreground
            canvas.drawRect(0f, 0f, width.toFloat(), height.toFloat(), paint)
        }
        paint.style = Paint.Style.STROKE
        paint.strokeWidth = border
        paint.color = MetroTheme.foreground
        canvas.drawRect(border / 2f, border / 2f, width - border / 2f, height - border / 2f, paint)

        textPaint.color = if (pressedDown) MetroTheme.background else MetroTheme.foreground
        canvas.drawText(
            label, width / 2f,
            height / 2f - (textPaint.ascent() + textPaint.descent()) / 2f, textPaint
        )
    }
}

/** WP's ToggleSwitch: a rectangular track with a rectangular thumb and an On/Off caption. */
class MetroToggle(
    context: Context,
    var isOn: Boolean,
    private val onChange: (Boolean) -> Unit
) : View(context) {

    private val paint = Paint(Paint.ANTI_ALIAS_FLAG)
    private val textPaint = Paint(Paint.ANTI_ALIAS_FLAG)
    private var thumbFraction = if (isOn) 1f else 0f

    init {
        textPaint.textSize = MetroTheme.textSize(MetroRole.NORMAL)
        textPaint.typeface = MetroTheme.typeface(MetroRole.NORMAL.weight)
        TiltController(this) {
            isOn = !isOn
            animateThumb()
            onChange(isOn)
        }.attach()
    }

    private fun animateThumb() {
        val anim = android.animation.ValueAnimator.ofFloat(thumbFraction, if (isOn) 1f else 0f)
        anim.duration = MetroMotion.duration(180)
        anim.interpolator = MetroEase.wpIn
        anim.addUpdateListener {
            thumbFraction = it.animatedValue as Float
            invalidate()
        }
        anim.start()
    }

    override fun onMeasure(widthMeasureSpec: Int, heightMeasureSpec: Int) {
        setMeasuredDimension(
            resolveSize(MetroTheme.dpInt(140f), widthMeasureSpec),
            resolveSize(MetroTheme.dpInt(32f), heightMeasureSpec)
        )
    }

    override fun onDraw(canvas: Canvas) {
        val trackW = MetroTheme.dp(74f)
        val trackH = MetroTheme.dp(28f)
        val top = (height - trackH) / 2f
        val border = MetroTheme.borderWidth

        if (isOn) {
            paint.style = Paint.Style.FILL
            paint.color = MetroTheme.accentColor
            canvas.drawRect(0f, top, trackW, top + trackH, paint)
        } else {
            paint.style = Paint.Style.STROKE
            paint.strokeWidth = border
            paint.color = MetroTheme.border
            canvas.drawRect(border / 2f, top + border / 2f, trackW - border / 2f, top + trackH - border / 2f, paint)
        }

        val thumbW = MetroTheme.dp(19f)
        val inset = MetroTheme.dp(3f)
        val x = inset + thumbFraction * (trackW - thumbW - inset * 2f)
        paint.style = Paint.Style.FILL
        paint.color = MetroTheme.foreground
        canvas.drawRect(x, top + inset, x + thumbW, top + trackH - inset, paint)

        textPaint.color = MetroTheme.foreground
        canvas.drawText(
            if (isOn) "On" else "Off",
            trackW + MetroTheme.dp(12f),
            height / 2f - (textPaint.ascent() + textPaint.descent()) / 2f,
            textPaint
        )
    }
}

/** Accent for the filled run, `PhoneDisabledBrush` for the rest, hard rectangular thumb. */
class MetroSlider(
    context: Context,
    private val label: String,
    private val min: Float,
    private val max: Float,
    initial: Float,
    private val format: (Float) -> String = { String.format("%.2f", it) },
    private val onChange: (Float) -> Unit
) : View(context) {

    private val paint = Paint(Paint.ANTI_ALIAS_FLAG)
    private val textPaint = Paint(Paint.ANTI_ALIAS_FLAG)

    var value: Float = initial
        set(v) {
            field = v.coerceIn(min, max)
            invalidate()
        }

    init {
        textPaint.textSize = MetroTheme.textSize(MetroRole.SMALL)
        textPaint.typeface = MetroTheme.typeface(MetroRole.SMALL.weight)
    }

    override fun onMeasure(widthMeasureSpec: Int, heightMeasureSpec: Int) {
        setMeasuredDimension(
            MeasureSpec.getSize(widthMeasureSpec),
            resolveSize(MetroTheme.dpInt(54f), heightMeasureSpec)
        )
    }

    override fun onTouchEvent(event: MotionEvent): Boolean {
        when (event.actionMasked) {
            MotionEvent.ACTION_DOWN, MotionEvent.ACTION_MOVE -> {
                parent?.requestDisallowInterceptTouchEvent(true)
                val f = (event.x / width.toFloat().coerceAtLeast(1f)).coerceIn(0f, 1f)
                value = min + f * (max - min)
                onChange(value)
                return true
            }
            MotionEvent.ACTION_UP, MotionEvent.ACTION_CANCEL -> {
                parent?.requestDisallowInterceptTouchEvent(false)
                return true
            }
        }
        return super.onTouchEvent(event)
    }

    override fun onDraw(canvas: Canvas) {
        textPaint.color = MetroTheme.subtle
        val baseline = -textPaint.ascent()
        canvas.drawText(label, 0f, baseline, textPaint)

        textPaint.color = MetroTheme.accentColor
        textPaint.textAlign = Paint.Align.RIGHT
        canvas.drawText(format(value), width.toFloat(), baseline, textPaint)
        textPaint.textAlign = Paint.Align.LEFT

        val trackY = height * 0.72f
        val fraction = if (max > min) (value - min) / (max - min) else 0f
        paint.style = Paint.Style.FILL

        paint.color = MetroTheme.disabled
        canvas.drawRect(0f, trackY - MetroTheme.dp(2f), width.toFloat(), trackY + MetroTheme.dp(2f), paint)
        paint.color = MetroTheme.accentColor
        canvas.drawRect(0f, trackY - MetroTheme.dp(2f), width * fraction, trackY + MetroTheme.dp(2f), paint)

        val thumbW = MetroTheme.dp(8f)
        val thumbH = MetroTheme.dp(22f)
        val x = (width - thumbW) * fraction
        paint.color = MetroTheme.foreground
        canvas.drawRect(x, trackY - thumbH / 2f, x + thumbW, trackY + thumbH / 2f, paint)
    }
}

/** A small selectable pill used by the lab's option rows. */
class MetroChip(
    context: Context,
    label: String,
    picked: Boolean,
    private val action: () -> Unit
) : View(context) {

    private val paint = Paint(Paint.ANTI_ALIAS_FLAG)
    private val textPaint = Paint(Paint.ANTI_ALIAS_FLAG)

    var label: String = label
        set(v) { field = v; requestLayout() }

    var picked: Boolean = picked
        set(v) { field = v; invalidate() }

    init {
        textPaint.textSize = MetroTheme.textSize(MetroRole.SMALL)
        textPaint.typeface = MetroTheme.typeface(MetroRole.SMALL.weight)
        textPaint.textAlign = Paint.Align.CENTER
        TiltController(this) { action() }.attach()
    }

    override fun onMeasure(widthMeasureSpec: Int, heightMeasureSpec: Int) {
        setMeasuredDimension(
            (textPaint.measureText(label) + MetroTheme.dp(22f)).toInt(),
            MetroTheme.dpInt(32f)
        )
    }

    override fun onDraw(canvas: Canvas) {
        if (picked) {
            paint.style = Paint.Style.FILL
            paint.color = MetroTheme.accentColor
            canvas.drawRect(0f, 0f, width.toFloat(), height.toFloat(), paint)
        } else {
            paint.style = Paint.Style.STROKE
            paint.strokeWidth = MetroTheme.dp(1f)
            paint.color = MetroTheme.border
            canvas.drawRect(0.5f, 0.5f, width - 0.5f, height - 0.5f, paint)
        }
        textPaint.color = if (picked) MetroTheme.onAccent else MetroTheme.foreground
        canvas.drawText(
            label, width / 2f,
            height / 2f - (textPaint.ascent() + textPaint.descent()) / 2f, textPaint
        )
    }
}

/** Horizontal wrap of chips. */
class MetroChipRow(context: Context) : LinearLayout(context) {
    init {
        orientation = HORIZONTAL
    }

    fun addChip(chip: MetroChip) {
        val lp = LayoutParams(LayoutParams.WRAP_CONTENT, LayoutParams.WRAP_CONTENT)
        lp.rightMargin = MetroTheme.dpInt(8f)
        addView(chip, lp)
    }
}

/** Convenience: a vertical column with page-margin padding, for lab pages. */
fun columnWithMargins(context: Context): LinearLayout = LinearLayout(context).apply {
    orientation = LinearLayout.VERTICAL
    setPadding(MetroTheme.pageMargin.toInt(), 0, MetroTheme.pageMargin.toInt(), MetroTheme.dpInt(32f))
    layoutParams = ViewGroup.LayoutParams(
        ViewGroup.LayoutParams.MATCH_PARENT,
        ViewGroup.LayoutParams.WRAP_CONTENT
    )
}
