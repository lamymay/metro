package com.rakukura.metrolab.glyph

import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.Path
import android.graphics.RectF
import kotlin.math.PI
import kotlin.math.cos
import kotlin.math.sin

/**
 * Hand-drawn stand-ins for the Segoe UI Symbol glyphs WP used on tiles and app bars.
 *
 * Metro icons are geometric outlines on a fixed optical grid — thin, open, never filled,
 * never rounded except where the object genuinely is round. Drawing them as paths rather
 * than shipping a font keeps the app asset-free and lets the stroke weight track size.
 *
 * The same 27 glyphs exist in the iOS project; keeping the two lists identical is the
 * point, since the whole app is a side-by-side comparison.
 */
enum class MetroGlyph {
    PHONE, MAIL, MESSAGE, PEOPLE, CAMERA, CALENDAR, MUSIC, STORE, SETTINGS,
    SEARCH, BACK, CLOSE, CHECK, PLUS, PIN, GLOBE, CLOCK, PHOTO, FOLDER,
    STAR, HEART, WIFI, SUN, ELLIPSIS, CHEVRON_RIGHT, CHEVRON_DOWN, REFRESH,
    /** The system Start button's glyph — a stylised four-petal pinwheel in the same
     * spirit as WP's own, not a reproduction of Microsoft's mark. */
    START,
    /** Transport controls, for the music player's now-playing screen. */
    PLAY, PAUSE, SKIP_NEXT, SKIP_PREVIOUS,
    /** Action Center / Settings glyphs. */
    AIRPLANE, BLUETOOTH, FLASHLIGHT;

    /** Glyphs whose shape reads better filled than stroked. */
    val prefersFill: Boolean
        get() = this == PHONE || this == ELLIPSIS || this == START ||
            this == PLAY || this == PAUSE || this == SKIP_NEXT || this == SKIP_PREVIOUS || this == FLASHLIGHT
}

object MetroGlyphs {

    private val scratchOval = RectF()

    /** Builds [glyph] into [out], fitted to a square centred in [bounds]. */
    fun build(glyph: MetroGlyph, bounds: RectF, out: Path) {
        out.reset()
        val s = minOf(bounds.width(), bounds.height())
        val ox = bounds.centerX() - s / 2f
        val oy = bounds.centerY() - s / 2f

        fun px(x: Float) = ox + x * s
        fun py(y: Float) = oy + y * s
        fun move(x: Float, y: Float) = out.moveTo(px(x), py(y))
        fun line(x: Float, y: Float) = out.lineTo(px(x), py(y))
        fun seg(x0: Float, y0: Float, x1: Float, y1: Float) {
            move(x0, y0); line(x1, y1)
        }
        fun quad(cx: Float, cy: Float, x: Float, y: Float) = out.quadTo(px(cx), py(cy), px(x), py(y))
        fun cubic(c1x: Float, c1y: Float, c2x: Float, c2y: Float, x: Float, y: Float) =
            out.cubicTo(px(c1x), py(c1y), px(c2x), py(c2y), px(x), py(y))
        fun circle(cx: Float, cy: Float, r: Float) {
            scratchOval.set(px(cx - r), py(cy - r), px(cx + r), py(cy + r))
            out.addOval(scratchOval, Path.Direction.CW)
        }
        fun arc(cx: Float, cy: Float, r: Float, from: Float, to: Float) {
            scratchOval.set(px(cx - r), py(cy - r), px(cx + r), py(cy + r))
            out.arcTo(scratchOval, from, to - from, true)
        }
        fun rect(x: Float, y: Float, w: Float, h: Float) {
            scratchOval.set(px(x), py(y), px(x + w), py(y + h))
            out.addRect(scratchOval, Path.Direction.CW)
        }
        fun poly(points: List<Pair<Float, Float>>, closed: Boolean = true) {
            if (points.isEmpty()) return
            move(points[0].first, points[0].second)
            for (i in 1 until points.size) line(points[i].first, points[i].second)
            if (closed) out.close()
        }

        when (glyph) {
            MetroGlyph.PHONE -> {
                move(0.18f, 0.30f)
                quad(0.24f, 0.20f, 0.34f, 0.22f)
                quad(0.44f, 0.28f, 0.40f, 0.36f)
                quad(0.50f, 0.50f, 0.64f, 0.60f)
                quad(0.72f, 0.56f, 0.78f, 0.66f)
                quad(0.80f, 0.76f, 0.70f, 0.82f)
                quad(0.20f, 0.80f, 0.18f, 0.30f)
            }

            MetroGlyph.MAIL -> {
                rect(0.14f, 0.28f, 0.72f, 0.44f)
                poly(listOf(0.14f to 0.28f, 0.50f to 0.55f, 0.86f to 0.28f), closed = false)
            }

            MetroGlyph.MESSAGE -> poly(
                listOf(
                    0.14f to 0.24f, 0.86f to 0.24f, 0.86f to 0.66f, 0.42f to 0.66f,
                    0.26f to 0.82f, 0.26f to 0.66f, 0.14f to 0.66f
                )
            )

            MetroGlyph.PEOPLE -> {
                circle(0.36f, 0.34f, 0.14f)
                arc(0.36f, 0.76f, 0.24f, 180f, 360f)
                circle(0.68f, 0.36f, 0.11f)
                arc(0.70f, 0.74f, 0.19f, 200f, 340f)
            }

            MetroGlyph.CAMERA -> {
                rect(0.10f, 0.30f, 0.80f, 0.44f)
                poly(listOf(0.34f to 0.30f, 0.40f to 0.20f, 0.60f to 0.20f, 0.66f to 0.30f), closed = false)
                circle(0.50f, 0.52f, 0.15f)
            }

            MetroGlyph.CALENDAR -> {
                rect(0.14f, 0.22f, 0.72f, 0.62f)
                seg(0.14f, 0.38f, 0.86f, 0.38f)
                seg(0.32f, 0.16f, 0.32f, 0.28f)
                seg(0.68f, 0.16f, 0.68f, 0.28f)
                for (row in 0..1) for (col in 0..2) {
                    rect(0.26f + col * 0.20f, 0.50f + row * 0.18f, 0.08f, 0.08f)
                }
            }

            MetroGlyph.MUSIC -> {
                seg(0.42f, 0.72f, 0.42f, 0.20f)
                seg(0.42f, 0.20f, 0.78f, 0.12f)
                seg(0.78f, 0.12f, 0.78f, 0.62f)
                circle(0.32f, 0.74f, 0.11f)
                circle(0.68f, 0.64f, 0.11f)
            }

            MetroGlyph.STORE -> {
                poly(listOf(0.18f to 0.36f, 0.82f to 0.36f, 0.76f to 0.84f, 0.24f to 0.84f))
                arc(0.50f, 0.36f, 0.18f, 180f, 360f)
            }

            MetroGlyph.SETTINGS -> {
                // A real toothed gear. A circle with radiating spokes reads as a sun,
                // which is the mistake to avoid when SUN is also in the set.
                val teeth = 8
                val outer = 0.44f
                val root = 0.33f
                val half = (PI / teeth * 0.45).toFloat()
                val pts = ArrayList<Pair<Float, Float>>(teeth * 4)
                for (i in 0 until teeth) {
                    val c = (i * 2 * PI / teeth).toFloat()
                    val n = ((i + 1) * 2 * PI / teeth).toFloat()
                    pts.add(0.50f + cos(c - half) * outer to 0.50f + sin(c - half) * outer)
                    pts.add(0.50f + cos(c + half) * outer to 0.50f + sin(c + half) * outer)
                    pts.add(0.50f + cos(c + half * 1.6f) * root to 0.50f + sin(c + half * 1.6f) * root)
                    pts.add(0.50f + cos(n - half * 1.6f) * root to 0.50f + sin(n - half * 1.6f) * root)
                }
                poly(pts)
                circle(0.50f, 0.50f, 0.14f)
            }

            MetroGlyph.SEARCH -> {
                circle(0.44f, 0.44f, 0.24f)
                seg(0.62f, 0.62f, 0.84f, 0.84f)
            }

            MetroGlyph.BACK -> {
                seg(0.16f, 0.50f, 0.84f, 0.50f)
                poly(listOf(0.42f to 0.26f, 0.16f to 0.50f, 0.42f to 0.74f), closed = false)
            }

            MetroGlyph.CLOSE -> {
                seg(0.22f, 0.22f, 0.78f, 0.78f)
                seg(0.78f, 0.22f, 0.22f, 0.78f)
            }

            MetroGlyph.CHECK -> poly(listOf(0.18f to 0.52f, 0.40f to 0.74f, 0.84f to 0.26f), closed = false)

            MetroGlyph.PLUS -> {
                seg(0.50f, 0.18f, 0.50f, 0.82f)
                seg(0.18f, 0.50f, 0.82f, 0.50f)
            }

            MetroGlyph.PIN -> {
                // Map pin: round head over a teardrop point.
                circle(0.50f, 0.38f, 0.20f)
                seg(0.335f, 0.49f, 0.50f, 0.88f)
                seg(0.665f, 0.49f, 0.50f, 0.88f)
            }

            MetroGlyph.GLOBE -> {
                circle(0.50f, 0.50f, 0.36f)
                seg(0.14f, 0.50f, 0.86f, 0.50f)
                move(0.50f, 0.14f); quad(0.20f, 0.50f, 0.50f, 0.86f)
                move(0.50f, 0.14f); quad(0.80f, 0.50f, 0.50f, 0.86f)
            }

            MetroGlyph.CLOCK -> {
                circle(0.50f, 0.50f, 0.36f)
                seg(0.50f, 0.50f, 0.50f, 0.26f)
                seg(0.50f, 0.50f, 0.68f, 0.60f)
            }

            MetroGlyph.PHOTO -> {
                rect(0.12f, 0.24f, 0.76f, 0.52f)
                poly(
                    listOf(0.12f to 0.68f, 0.36f to 0.44f, 0.56f to 0.62f, 0.68f to 0.52f, 0.88f to 0.70f),
                    closed = false
                )
                circle(0.68f, 0.36f, 0.07f)
            }

            MetroGlyph.FOLDER -> poly(
                listOf(
                    0.12f to 0.76f, 0.12f to 0.26f, 0.42f to 0.26f,
                    0.50f to 0.36f, 0.88f to 0.36f, 0.88f to 0.76f
                )
            )

            MetroGlyph.STAR -> {
                val pts = ArrayList<Pair<Float, Float>>(10)
                for (i in 0 until 10) {
                    val r = if (i % 2 == 0) 0.38f else 0.16f
                    val a = (-PI / 2 + i * PI / 5).toFloat()
                    pts.add(0.50f + cos(a) * r to 0.50f + sin(a) * r)
                }
                poly(pts)
            }

            MetroGlyph.HEART -> {
                move(0.50f, 0.82f)
                cubic(0.24f, 0.66f, 0.12f, 0.54f, 0.12f, 0.40f)
                arc(0.31f, 0.40f, 0.19f, 180f, 360f)
                arc(0.69f, 0.40f, 0.19f, 180f, 360f)
                move(0.88f, 0.40f)
                cubic(0.88f, 0.54f, 0.76f, 0.66f, 0.50f, 0.82f)
            }

            MetroGlyph.WIFI -> {
                circle(0.50f, 0.76f, 0.05f)
                arc(0.50f, 0.78f, 0.20f, 210f, 330f)
                arc(0.50f, 0.78f, 0.34f, 213f, 327f)
                arc(0.50f, 0.78f, 0.48f, 216f, 324f)
            }

            MetroGlyph.SUN -> {
                circle(0.50f, 0.50f, 0.18f)
                for (i in 0 until 8) {
                    val a = (i * PI / 4).toFloat()
                    seg(
                        0.50f + cos(a) * 0.28f, 0.50f + sin(a) * 0.28f,
                        0.50f + cos(a) * 0.42f, 0.50f + sin(a) * 0.42f
                    )
                }
            }

            MetroGlyph.ELLIPSIS -> for (i in 0 until 3) circle(0.26f + i * 0.24f, 0.50f, 0.055f)

            MetroGlyph.CHEVRON_RIGHT ->
                poly(listOf(0.38f to 0.20f, 0.66f to 0.50f, 0.38f to 0.80f), closed = false)

            MetroGlyph.CHEVRON_DOWN ->
                poly(listOf(0.20f to 0.38f, 0.50f to 0.66f, 0.80f to 0.38f), closed = false)

            MetroGlyph.REFRESH -> {
                // Open arc with a barb on the free end, so travel direction is legible.
                arc(0.50f, 0.50f, 0.34f, -60f, 200f)
                poly(listOf(0.58f to 0.11f, 0.67f to 0.21f, 0.79f to 0.17f), closed = false)
            }

            MetroGlyph.START -> {
                // The four-pane Windows mark: a plain 2×2 grid of filled squares with a
                // visible gap between them — the same glyph WP printed on its own Start
                // button, and a nice echo of the tile grid this button takes you back to.
                rect(0.07f, 0.07f, 0.38f, 0.38f)
                rect(0.55f, 0.07f, 0.38f, 0.38f)
                rect(0.07f, 0.55f, 0.38f, 0.38f)
                rect(0.55f, 0.55f, 0.38f, 0.38f)
            }

            MetroGlyph.PLAY ->
                poly(listOf(0.32f to 0.20f, 0.32f to 0.80f, 0.82f to 0.50f))

            MetroGlyph.PAUSE -> {
                rect(0.28f, 0.20f, 0.16f, 0.60f)
                rect(0.56f, 0.20f, 0.16f, 0.60f)
            }

            MetroGlyph.SKIP_NEXT -> {
                poly(listOf(0.22f to 0.22f, 0.22f to 0.78f, 0.62f to 0.50f))
                rect(0.68f, 0.22f, 0.12f, 0.56f)
            }

            MetroGlyph.SKIP_PREVIOUS -> {
                rect(0.20f, 0.22f, 0.12f, 0.56f)
                poly(listOf(0.78f to 0.22f, 0.78f to 0.78f, 0.38f to 0.50f))
            }

            MetroGlyph.AIRPLANE -> {
                poly(listOf(0.10f to 0.55f, 0.90f to 0.20f, 0.55f to 0.90f, 0.48f to 0.58f), closed = false)
                seg(0.48f, 0.58f, 0.10f, 0.55f)
                seg(0.48f, 0.58f, 0.90f, 0.20f)
            }

            MetroGlyph.BLUETOOTH -> {
                seg(0.50f, 0.12f, 0.50f, 0.88f)
                seg(0.50f, 0.12f, 0.74f, 0.30f)
                seg(0.74f, 0.30f, 0.50f, 0.50f)
                seg(0.50f, 0.50f, 0.74f, 0.70f)
                seg(0.74f, 0.70f, 0.50f, 0.88f)
                seg(0.50f, 0.50f, 0.26f, 0.30f)
                seg(0.50f, 0.50f, 0.26f, 0.70f)
            }

            MetroGlyph.FLASHLIGHT -> {
                poly(listOf(0.34f to 0.40f, 0.66f to 0.40f, 0.58f to 0.16f, 0.42f to 0.16f))
                rect(0.38f, 0.40f, 0.24f, 0.46f)
            }
        }
    }

    private val drawPath = Path()
    private val drawBounds = RectF()
    private val drawPaint = Paint(Paint.ANTI_ALIAS_FLAG)

    /**
     * Draws [glyph] centred at ([cx], [cy]) with the given box [size]. WP's icons sat
     * around 1/22 of the box in stroke weight.
     */
    fun draw(canvas: Canvas, glyph: MetroGlyph, cx: Float, cy: Float, size: Float, color: Int, weight: Float = 1f / 22f) {
        drawBounds.set(cx - size / 2f, cy - size / 2f, cx + size / 2f, cy + size / 2f)
        build(glyph, drawBounds, drawPath)
        drawPaint.color = color
        if (glyph.prefersFill) {
            drawPaint.style = Paint.Style.FILL
        } else {
            drawPaint.style = Paint.Style.STROKE
            drawPaint.strokeWidth = maxOf(1f, size * weight)
            drawPaint.strokeCap = Paint.Cap.BUTT
            drawPaint.strokeJoin = Paint.Join.MITER
        }
        canvas.drawPath(drawPath, drawPaint)
    }
}
