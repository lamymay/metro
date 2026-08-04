package com.rakukura.metrolab.tile

import android.animation.ValueAnimator
import android.content.Context
import android.graphics.Camera
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Matrix
import android.graphics.Paint
import android.view.View
import com.rakukura.metrolab.glyph.MetroGlyphs
import com.rakukura.metrolab.motion.MetroEase
import com.rakukura.metrolab.motion.MetroMotion
import com.rakukura.metrolab.motion.TiltController
import com.rakukura.metrolab.theme.MetroRole
import com.rakukura.metrolab.theme.MetroTheme
import kotlin.math.abs
import kotlin.math.floor

/**
 * A single live tile: fill, face, caption, badge, tilt and its own turn timer.
 *
 * Everything is drawn rather than composed out of widgets — a tile is a rectangle, a
 * glyph and two pieces of text, and Canvas renders that in one pass on a 2012 phone.
 *
 * The flip is done with a [Camera] transform inside [onDraw] rather than `rotationX`,
 * because the face has to *change* halfway through the turn, and a View property
 * animation cannot swap content mid-flight.
 */
class TileView(context: Context) : View(context) {

    var model: TileModel = TileModel(id = "", title = "", glyph = com.rakukura.metrolab.glyph.MetroGlyph.MAIL)
        set(value) {
            field = value
            turn = 0f
            restartLiveLoop()
            invalidate()
        }

    var onSelect: ((TileModel) -> Unit)? = null
        set(value) {
            field = value
            tilt.setOnClick { value?.invoke(model) }
        }

    /** Side of a small tile, in pixels. Everything else is derived from it. */
    var unit: Float = 0f

    private val tilt = TiltController(this)
    private val paint = Paint(Paint.ANTI_ALIAS_FLAG)
    private val textPaint = Paint(Paint.ANTI_ALIAS_FLAG)
    private val camera = Camera()
    private val matrix = Matrix()

    /** Grows by exactly 1 per turn; the integer part picks the face. */
    private var turn = 0f
    private var turnAnimator: ValueAnimator? = null
    private var liveRunnable: Runnable? = null

    init {
        tilt.attach()
        isClickable = true
    }

    override fun onAttachedToWindow() {
        super.onAttachedToWindow()
        restartLiveLoop()
    }

    override fun onDetachedFromWindow() {
        super.onDetachedFromWindow()
        stopLiveLoop()
    }

    // ---- Live loop ----

    private fun stopLiveLoop() {
        liveRunnable?.let { removeCallbacks(it) }
        liveRunnable = null
        turnAnimator?.cancel()
        turnAnimator = null
    }

    private fun restartLiveLoop() {
        stopLiveLoop()
        if (!isAttachedToWindowCompat() || !model.isLive || !MetroMotion.liveTilesEnabled) return

        // Deterministic per-tile offset. A wall of tiles beating in lockstep is the
        // single most obvious way to get a live start screen wrong.
        val jitter = (abs(model.id.hashCode()) % 1000) / 1000f * MetroMotion.tileDwellJitter

        val runnable = object : Runnable {
            override fun run() {
                if (!MetroMotion.liveTilesEnabled) return
                advance()
                postDelayed(this, MetroMotion.duration(MetroMotion.tileDwell))
            }
        }
        liveRunnable = runnable
        postDelayed(runnable, MetroMotion.duration(MetroMotion.tileDwell) + jitter.toLong())
    }

    private fun isAttachedToWindowCompat(): Boolean = windowToken != null

    private fun advance() {
        turnAnimator?.cancel()
        val from = turn
        val duration = MetroMotion.duration(
            if (model.behaviour == TileBehaviour.FLIP) MetroMotion.tileFlipDuration
            else MetroMotion.tileSlideDuration
        )
        val anim = ValueAnimator.ofFloat(from, from + 1f)
        anim.duration = duration
        anim.interpolator = MetroEase.wpIn
        anim.addUpdateListener {
            turn = it.animatedValue as Float
            invalidate()
        }
        turnAnimator = anim
        anim.start()
    }

    // ---- Drawing ----

    override fun onDraw(canvas: Canvas) {
        val w = width.toFloat()
        val h = height.toFloat()
        if (w <= 0f || h <= 0f) return

        if (model.style != TileStyle.TRANSPARENT) {
            paint.style = Paint.Style.FILL
            paint.color = model.fill
            canvas.drawRect(0f, 0f, w, h, paint)
        } else {
            paint.style = Paint.Style.STROKE
            paint.strokeWidth = MetroTheme.dp(1f)
            paint.color = MetroTheme.withAlpha(MetroTheme.foreground, 0.18f)
            canvas.drawRect(0f, 0f, w, h, paint)
        }

        val faces = model.faces
        if (faces.size <= 1 || model.behaviour == TileBehaviour.STATIC) {
            drawFace(canvas, faces[0], w, h)
            return
        }

        val base = floor(turn.toDouble()).toInt()
        val frac = turn - base

        when (model.behaviour) {
            TileBehaviour.FLIP -> {
                // Past halfway the *back* face is showing, so it is drawn upright with
                // the angle wound back a full half-turn — the visual angle is the same
                // and the content is not mirrored.
                val pastHalf = frac >= 0.5f
                val angle = if (pastHalf) frac * 180f - 180f else frac * 180f
                canvas.save()
                camera.save()
                camera.rotateX(angle)
                camera.getMatrix(matrix)
                camera.restore()
                matrix.preTranslate(-w / 2f, -h / 2f)
                matrix.postTranslate(w / 2f, h / 2f)
                canvas.concat(matrix)
                drawFace(canvas, faceAt(if (pastHalf) base + 1 else base), w, h)
                canvas.restore()
            }

            TileBehaviour.SLIDE -> {
                canvas.save()
                canvas.clipRect(0f, 0f, w, h)
                canvas.save()
                canvas.translate(0f, -frac * h)
                drawFace(canvas, faceAt(base), w, h)
                canvas.restore()
                canvas.save()
                canvas.translate(0f, (1f - frac) * h)
                drawFace(canvas, faceAt(base + 1), w, h)
                canvas.restore()
                canvas.restore()
            }

            TileBehaviour.STATIC -> Unit
        }
    }

    private fun faceAt(raw: Int): TileFace {
        val n = model.faces.size
        return model.faces[((raw % n) + n) % n]
    }

    private val padding: Float get() = maxOf(MetroTheme.dp(4f), unit * 0.09f)

    /** The glyph does not grow with the footprint — a wide tile shows the same icon. */
    private val glyphSize: Float
        get() = if (model.size == TileSize.SMALL) unit * 0.50f else unit * 0.62f

    private fun drawFace(canvas: Canvas, face: TileFace, w: Float, h: Float) {
        val tint = model.foreground
        when (face) {
            is TileFace.Iconic -> drawRestingFace(canvas, w, h, tint)

            is TileFace.Glyph ->
                MetroGlyphs.draw(canvas, face.glyph, w / 2f, h / 2f, glyphSize, tint)

            is TileFace.Headline -> {
                setText(unit * 0.20f, MetroRole.TITLE2, tint)
                drawWrapped(canvas, face.text, padding, padding, w - padding * 2f, 4)
            }

            is TileFace.Message -> {
                setText(unit * 0.145f, MetroRole.GROUP_HEADER, tint)
                canvas.drawText(face.from, padding, padding - textPaint.ascent(), textPaint)
                val firstLine = padding - textPaint.ascent() + textPaint.descent()
                setText(unit * 0.135f, MetroRole.SMALL, MetroTheme.withAlpha(tint, 0.85f))
                drawWrapped(canvas, face.body, padding, firstLine + unit * 0.04f, w - padding * 2f, 3)
            }

            is TileFace.Counter -> {
                setText(unit * 0.145f, MetroRole.SMALL, MetroTheme.withAlpha(tint, 0.85f))
                val captionBaseline = h - padding * 0.9f - textPaint.descent()
                canvas.drawText(face.caption, padding, captionBaseline, textPaint)
                setText(unit * 0.68f, MetroRole.PAGE_TITLE, tint)
                canvas.drawText(
                    face.value.toString(),
                    padding,
                    captionBaseline + textPaint.ascent() * 0.30f - MetroTheme.dp(2f),
                    textPaint
                )
            }

            is TileFace.Initials -> {
                setText(unit * 0.72f, MetroRole.PAGE_TITLE, tint)
                val text = face.letters.uppercase()
                textPaint.textAlign = Paint.Align.CENTER
                canvas.drawText(text, w / 2f, h / 2f - (textPaint.ascent() + textPaint.descent()) / 2f, textPaint)
                textPaint.textAlign = Paint.Align.LEFT
            }

            is TileFace.Photo -> {
                val accentColor = (model.accent ?: com.rakukura.metrolab.theme.MetroAccent.COBALT).color
                val shader = android.graphics.LinearGradient(
                    0f, 0f, w, h,
                    intArrayOf(accentColor, MetroTheme.withAlpha(accentColor, 0.4f), MetroTheme.withAlpha(0x000000, 0.6f)),
                    null, android.graphics.Shader.TileMode.CLAMP
                )
                paint.shader = shader
                paint.style = Paint.Style.FILL
                canvas.drawRect(0f, 0f, w, h, paint)
                paint.shader = null
            }
        }
    }

    private fun drawRestingFace(canvas: Canvas, w: Float, h: Float, tint: Int) {
        // WP sat the glyph slightly above centre so the caption did not crowd it, and
        // pushed it to the left edge on a wide tile rather than growing it.
        val gx = if (model.size == TileSize.WIDE) padding * 1.4f + glyphSize / 2f else w / 2f
        val gy = if (model.size.showsTitle) h / 2f - unit * 0.09f else h / 2f
        MetroGlyphs.draw(canvas, model.glyph, gx, gy, glyphSize, tint)

        if (model.size.showsTitle) {
            setText(MetroTheme.textSize(MetroRole.TILE_TITLE), MetroRole.TILE_TITLE, tint)
            canvas.drawText(model.title, padding, h - padding * 0.7f - textPaint.descent(), textPaint)
        }

        val badge = model.badge
        if (badge != null && badge > 0) {
            val scale = if (model.size == TileSize.SMALL) 0.55f else 1f
            setText(MetroTheme.textSize(MetroRole.TILE_BADGE) * scale, MetroRole.TILE_BADGE, tint)
            val label = if (badge > 99) "99+" else badge.toString()
            textPaint.textAlign = Paint.Align.RIGHT
            canvas.drawText(label, w - padding, padding * 0.3f - textPaint.ascent(), textPaint)
            textPaint.textAlign = Paint.Align.LEFT
        }
    }

    private fun setText(size: Float, role: MetroRole, color: Int) {
        textPaint.textSize = size
        textPaint.typeface = MetroTheme.typeface(role.weight)
        textPaint.color = color
        textPaint.textAlign = Paint.Align.LEFT
    }

    /** Greedy word wrap. Enough for tile copy; nothing here justifies a StaticLayout. */
    private fun drawWrapped(canvas: Canvas, text: String, x: Float, top: Float, maxWidth: Float, maxLines: Int) {
        val lineHeight = textPaint.descent() - textPaint.ascent()
        var baseline = top - textPaint.ascent()
        var line = StringBuilder()
        var lines = 0

        fun flush() {
            if (line.isEmpty()) return
            canvas.drawText(line.toString(), x, baseline, textPaint)
            baseline += lineHeight
            lines++
            line = StringBuilder()
        }

        for (word in text.split(" ", "\n")) {
            val candidate = if (line.isEmpty()) word else "$line $word"
            if (textPaint.measureText(candidate) > maxWidth && line.isNotEmpty()) {
                flush()
                if (lines >= maxLines) return
                line.append(word)
            } else {
                line.setLength(0)
                line.append(candidate)
            }
        }
        if (lines < maxLines) flush()
    }
}
