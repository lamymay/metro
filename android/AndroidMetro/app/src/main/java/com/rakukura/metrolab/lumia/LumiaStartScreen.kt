package com.rakukura.metrolab.lumia

import android.content.Context
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.RectF
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import android.widget.ScrollView
import com.rakukura.metrolab.glyph.MetroGlyph
import com.rakukura.metrolab.glyph.MetroGlyphs
import com.rakukura.metrolab.nav.MetroPage
import com.rakukura.metrolab.nav.PageHost
import com.rakukura.metrolab.theme.MetroTheme

/**
 * A dedicated, standalone recreation of one specific Windows Phone 8.1 (Lumia Icon,
 * "Denim", Verizon) start-screen photo — not built on [com.rakukura.metrolab.tile.TilePacker]
 * / [com.rakukura.metrolab.tile.StartScreenView], since that engine auto-packs tiles by
 * size class rather than placing tiles at fixed coordinates. This hard-codes the grid
 * the one photo actually shows: a 4-column layout of small/medium/wide tiles, their
 * colours, glyphs, labels and live badges, reproduced as closely as a single angled
 * product photo allows.
 */
private data class LumiaTile(
    val id: String,
    val col: Int,
    val row: Int,
    val colSpan: Int,
    val rowSpan: Int,
    val color: Int,
    val badge: String? = null,
    val caption: String? = null,
    val captionGravity: Int = Gravity.BOTTOM or Gravity.START,
    val draw: (Canvas, RectF) -> Unit
)

class LumiaStartScreenView(context: Context) : View(context) {

    private val columns = 4
    private val rowCount = 10
    private val gap get() = MetroTheme.dp(4f)
    private val margin get() = MetroTheme.dp(4f)
    private val topInset get() = MetroTheme.dp(44f)
    private val bottomInset get() = MetroTheme.dp(60f)

    private val fillPaint = Paint(Paint.ANTI_ALIAS_FLAG)
    private val badgePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = Color.WHITE
        textSize = MetroTheme.dp(26f)
    }
    private val captionPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = Color.WHITE
        textSize = MetroTheme.dp(12f)
    }
    private val bigTextPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = Color.WHITE
        textSize = MetroTheme.dp(30f)
    }
    private val rect = RectF()

    private val tiles: List<LumiaTile> by lazy { buildTiles() }

    /** Live tile bounds, rebuilt every layout pass — the hit-test source for [onTouchEvent]. */
    private val tileBounds = LinkedHashMap<String, RectF>()

    var onSelect: ((String) -> Unit)? = null

    override fun onMeasure(widthMeasureSpec: Int, heightMeasureSpec: Int) {
        val width = MeasureSpec.getSize(widthMeasureSpec)
        val unit = unitFor(width.toFloat())
        val height = (topInset + rowCount * unit + (rowCount - 1) * gap + bottomInset).toInt()
        setMeasuredDimension(width, height)
    }

    private fun unitFor(width: Float): Float =
        ((width - margin * 2) - gap * (columns - 1)) / columns

    override fun onDraw(canvas: Canvas) {
        val unit = unitFor(width.toFloat())
        tileBounds.clear()

        for (tile in tiles) {
            val left = margin + (tile.col - 1) * (unit + gap)
            val top = topInset + (tile.row - 1) * (unit + gap)
            val w = tile.colSpan * unit + (tile.colSpan - 1) * gap
            val h = tile.rowSpan * unit + (tile.rowSpan - 1) * gap
            rect.set(left, top, left + w, top + h)
            tileBounds[tile.id] = RectF(rect)

            fillPaint.color = tile.color
            canvas.drawRect(rect, fillPaint)

            tile.draw(canvas, rect)

            tile.badge?.let { text ->
                canvas.drawText(
                    text,
                    rect.right - badgePaint.measureText(text) - MetroTheme.dp(8f),
                    rect.top + MetroTheme.dp(30f),
                    badgePaint
                )
            }
            tile.caption?.let { text ->
                val y = if (tile.captionGravity and Gravity.TOP == Gravity.TOP)
                    rect.top + MetroTheme.dp(20f)
                else
                    rect.bottom - MetroTheme.dp(8f)
                val x = if (tile.captionGravity and Gravity.END == Gravity.END)
                    rect.right - captionPaint.measureText(text) - MetroTheme.dp(6f)
                else
                    rect.left + MetroTheme.dp(6f)
                canvas.drawText(text, x, y, captionPaint)
            }
        }
    }

    private var downId: String? = null

    override fun onTouchEvent(event: MotionEvent): Boolean {
        when (event.actionMasked) {
            MotionEvent.ACTION_DOWN -> {
                downId = tileAt(event.x, event.y)
                return downId != null
            }
            MotionEvent.ACTION_UP -> {
                val id = tileAt(event.x, event.y)
                if (id != null && id == downId) onSelect?.invoke(id)
                downId = null
                return true
            }
            MotionEvent.ACTION_CANCEL -> {
                downId = null
            }
        }
        return super.onTouchEvent(event)
    }

    private fun tileAt(x: Float, y: Float): String? =
        tileBounds.entries.firstOrNull { it.value.contains(x, y) }?.key

    private fun glyph(canvas: Canvas, rect: RectF, glyph: MetroGlyph) {
        val size = minOf(rect.width(), rect.height()) * 0.36f
        MetroGlyphs.draw(canvas, glyph, rect.centerX(), rect.centerY(), size, Color.WHITE)
    }

    private fun buildTiles(): List<LumiaTile> = listOf(
        LumiaTile("phone", 1, 1, 2, 2, Color.parseColor("#E51400"), caption = "Verizon Wireless") { c, r ->
            glyph(c, r, MetroGlyph.PHONE)
        },
        LumiaTile("messaging", 3, 1, 1, 1, Color.parseColor("#1BA1E2")) { c, r ->
            glyph(c, r, MetroGlyph.MESSAGE)
        },
        LumiaTile("mail-small", 4, 1, 1, 1, Color.parseColor("#A200FF"), badge = "15") { c, r ->
            glyph(c, r, MetroGlyph.MAIL)
        },
        LumiaTile("google-mail", 3, 2, 2, 1, Color.parseColor("#E51400"), badge = "23", caption = "Google Mail") { c, r ->
            glyph(c, r, MetroGlyph.MAIL)
        },
        LumiaTile("games", 1, 3, 2, 2, Color.parseColor("#60A917")) { c, r ->
            drawGameController(c, r)
        },
        LumiaTile("camera", 3, 3, 1, 2, Color.parseColor("#6A00FF"), caption = "Nokia Camera") { c, r ->
            glyph(c, r, MetroGlyph.CAMERA)
        },
        LumiaTile("mail-7", 4, 3, 1, 2, Color.parseColor("#E51400"), badge = "7") { c, r ->
            glyph(c, r, MetroGlyph.MAIL)
        },
        LumiaTile("calendar", 1, 5, 3, 2, Color.parseColor("#E51400"), caption = "Calendar") { c, r ->
            val text = "Mon 14"
            c.drawText(text, r.centerX() - bigTextPaint.measureText(text) / 2f, r.centerY() + MetroTheme.dp(10f), bigTextPaint)
        },
        LumiaTile("twitter", 4, 5, 1, 2, Color.parseColor("#1BA1E2"), captionGravity = Gravity.TOP or Gravity.END) { c, r ->
            drawBird(c, r)
        },
        LumiaTile("here-drive", 1, 7, 2, 2, Color.parseColor("#1D7DD4"), caption = "HERE Drive+") { c, r ->
            drawCar(c, r)
        },
        // The photo's small unlabeled tile here becomes the Music tile — the app
        // already ships a full WP-style music player and it needs a way in.
        LumiaTile("music", 3, 7, 1, 1, Color.parseColor("#1BA1E2")) { c, r ->
            glyph(c, r, MetroGlyph.MUSIC)
        },
        LumiaTile("icon-d", 4, 7, 1, 1, Color.parseColor("#A200FF")) { c, r ->
            glyph(c, r, MetroGlyph.PHOTO)
        },
        LumiaTile("office", 3, 8, 2, 1, Color.parseColor("#D24726"), caption = "Office") { c, r ->
            drawDoc(c, r)
        },
        LumiaTile("voicemail", 1, 9, 2, 1, Color.parseColor("#E51400"), caption = "Voicemail") { c, r ->
            drawVoicemail(c, r)
        },
        LumiaTile("photos", 3, 9, 2, 1, Color.parseColor("#1F1F1F"), caption = "Photos") { c, r ->
            drawPhotoStrip(c, r)
        }
    )

    private fun drawGameController(canvas: Canvas, r: RectF) {
        val p = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = Color.WHITE; style = Paint.Style.STROKE; strokeWidth = MetroTheme.dp(2f) }
        val w = r.width() * 0.5f
        val h = r.height() * 0.28f
        val body = RectF(r.centerX() - w / 2f, r.centerY() - h / 2f, r.centerX() + w / 2f, r.centerY() + h / 2f)
        canvas.drawRoundRect(body, h / 2f, h / 2f, p)
        val dotR = MetroTheme.dp(2.5f)
        canvas.drawCircle(body.right - h * 0.6f, body.top + h * 0.3f, dotR, p.apply { style = Paint.Style.FILL })
        canvas.drawCircle(body.right - h * 0.35f, body.top + h * 0.6f, dotR, p)
        canvas.drawLine(body.left + h * 0.35f, body.centerY(), body.left + h * 0.65f, body.centerY(), p)
        canvas.drawLine(body.left + h * 0.5f, body.top + h * 0.2f, body.left + h * 0.5f, body.bottom - h * 0.2f, p)
    }

    private fun drawCar(canvas: Canvas, r: RectF) {
        val p = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = Color.WHITE; style = Paint.Style.STROKE; strokeWidth = MetroTheme.dp(2f) }
        val w = r.width() * 0.55f
        val h = r.height() * 0.22f
        val body = RectF(r.centerX() - w / 2f, r.centerY() - h / 2f, r.centerX() + w / 2f, r.centerY() + h / 2f)
        canvas.drawRoundRect(body, h * 0.4f, h * 0.4f, p)
        val wheelR = h * 0.45f
        p.style = Paint.Style.FILL
        canvas.drawCircle(body.left + w * 0.22f, body.bottom, wheelR, p)
        canvas.drawCircle(body.right - w * 0.22f, body.bottom, wheelR, p)
    }

    private fun drawBird(canvas: Canvas, r: RectF) {
        val p = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = Color.WHITE; style = Paint.Style.FILL }
        val s = minOf(r.width(), r.height()) * 0.3f
        val cx = r.centerX()
        val cy = r.centerY()
        canvas.drawOval(RectF(cx - s, cy - s * 0.6f, cx + s * 0.7f, cy + s * 0.5f), p)
        canvas.drawCircle(cx - s * 0.55f, cy - s * 0.35f, s * 0.4f, p)
        val beak = android.graphics.Path()
        beak.moveTo(cx - s * 0.95f, cy - s * 0.35f)
        beak.lineTo(cx - s * 1.25f, cy - s * 0.25f)
        beak.lineTo(cx - s * 0.95f, cy - s * 0.15f)
        beak.close()
        canvas.drawPath(beak, p)
    }

    private fun drawDoc(canvas: Canvas, r: RectF) {
        val p = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = Color.WHITE; style = Paint.Style.STROKE; strokeWidth = MetroTheme.dp(2f) }
        val w = r.width() * 0.3f
        val h = r.height() * 0.4f
        val box = RectF(r.centerX() - w / 2f, r.centerY() - h / 2f, r.centerX() + w / 2f, r.centerY() + h / 2f)
        canvas.drawRect(box, p)
        for (i in 0 until 3) {
            val y = box.top + box.height() * (0.28f + i * 0.24f)
            canvas.drawLine(box.left + box.width() * 0.18f, y, box.right - box.width() * 0.18f, y, p)
        }
    }

    private fun drawVoicemail(canvas: Canvas, r: RectF) {
        val p = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = Color.WHITE; style = Paint.Style.STROKE; strokeWidth = MetroTheme.dp(2f) }
        val radius = r.height() * 0.16f
        val cx = r.centerX()
        val cy = r.centerY() - r.height() * 0.06f
        canvas.drawCircle(cx - radius * 1.6f, cy, radius, p)
        canvas.drawCircle(cx + radius * 1.6f, cy, radius, p)
        canvas.drawLine(cx - radius * 1.6f, cy + radius, cx + radius * 1.6f, cy + radius, p)
    }

    private fun drawPhotoStrip(canvas: Canvas, r: RectF) {
        val stripW = r.width() * 0.34f
        val stripH = r.height() * 0.5f
        val left = r.centerX() - stripW * 1.5f
        val top = r.centerY() - stripH / 2f
        val colors = intArrayOf(Color.parseColor("#E51400"), Color.WHITE, Color.parseColor("#1BA1E2"))
        for (i in 0 until 3) {
            fillPaint.color = colors[i]
            canvas.drawRect(left + i * stripW, top, left + (i + 1) * stripW - MetroTheme.dp(2f), top + stripH, fillPaint)
        }
    }
}

/** Fixed-grid page wrapper. Back/Start/Search live in [com.rakukura.metrolab.widget.SystemNavBar],
 * which [com.rakukura.metrolab.MetroLabActivity] already docks below every page — this
 * just supplies the scrollable tile screen and forwards taps to [onTileSelect]. */
class LumiaStartPage(private val onTileSelect: (String) -> Unit = {}) : MetroPage {
    override fun createView(context: Context, host: PageHost): View {
        val root = FrameLayout(context)
        root.setBackgroundColor(Color.BLACK)

        val startView = LumiaStartScreenView(context)
        startView.onSelect = onTileSelect

        val scroll = ScrollView(context)
        scroll.clipChildren = false
        scroll.addView(
            startView,
            ViewGroup.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT)
        )
        root.addView(scroll, FrameLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT))

        return root
    }
}
