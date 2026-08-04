package com.rakukura.metrolab.lab

import android.content.Context
import android.view.View
import android.view.ViewGroup
import android.widget.LinearLayout
import android.widget.ScrollView
import com.rakukura.metrolab.applist.AppListView
import com.rakukura.metrolab.glyph.MetroGlyph
import com.rakukura.metrolab.motion.MetroEase
import com.rakukura.metrolab.motion.MetroFeather
import com.rakukura.metrolab.motion.MetroMotion
import com.rakukura.metrolab.nav.MetroPage
import com.rakukura.metrolab.nav.MetroTransition
import com.rakukura.metrolab.nav.PageHost
import com.rakukura.metrolab.panorama.PanoramaSection
import com.rakukura.metrolab.panorama.PanoramaView
import com.rakukura.metrolab.pivot.PivotItem
import com.rakukura.metrolab.pivot.PivotView
import com.rakukura.metrolab.theme.MetroAccent
import com.rakukura.metrolab.theme.MetroRole
import com.rakukura.metrolab.theme.MetroTheme
import com.rakukura.metrolab.theme.MetroThemeMode
import com.rakukura.metrolab.tile.StartScreenView
import com.rakukura.metrolab.tile.TileBehaviour
import com.rakukura.metrolab.tile.TileFace
import com.rakukura.metrolab.tile.TileModel
import com.rakukura.metrolab.tile.TileSize
import com.rakukura.metrolab.tile.TileStyle
import com.rakukura.metrolab.tile.TileView
import com.rakukura.metrolab.widget.MetroButton
import com.rakukura.metrolab.widget.MetroChip
import com.rakukura.metrolab.widget.MetroChipRow
import com.rakukura.metrolab.widget.MetroGlyphView
import com.rakukura.metrolab.widget.MetroListRow
import com.rakukura.metrolab.widget.MetroPageHeader
import com.rakukura.metrolab.widget.MetroProgressDots
import com.rakukura.metrolab.widget.MetroProgressRing
import com.rakukura.metrolab.widget.MetroSlider
import com.rakukura.metrolab.widget.MetroTextView
import com.rakukura.metrolab.widget.MetroToggle
import com.rakukura.metrolab.widget.columnWithMargins

// ---------------------------------------------------------------- shared scaffolding

private fun matchWrap() = LinearLayout.LayoutParams(
    LinearLayout.LayoutParams.MATCH_PARENT,
    LinearLayout.LayoutParams.WRAP_CONTENT
)

private fun LinearLayout.spacer(dp: Float) {
    addView(View(context), LinearLayout.LayoutParams(1, MetroTheme.dpInt(dp)))
}

private fun LinearLayout.groupTitle(text: String) {
    addView(MetroTextView(context, MetroRole.GROUP_HEADER).apply { this.text = text }, matchWrap())
    spacer(6f)
}

private fun LinearLayout.note(text: String) {
    addView(MetroTextView(context, MetroRole.SMALL).apply { this.text = text }, matchWrap())
    spacer(8f)
}

/** Page chrome plus a scrolling body, which is the shape of almost every lab page. */
private fun scaffold(
    context: Context,
    appTitle: String?,
    pageTitle: String?,
    body: LinearLayout.() -> Unit
): View {
    val root = LinearLayout(context)
    root.orientation = LinearLayout.VERTICAL
    if (appTitle != null || pageTitle != null) {
        root.addView(MetroPageHeader(context, appTitle, pageTitle), matchWrap())
    }
    val scroll = ScrollView(context)
    val column = columnWithMargins(context)
    column.body()
    scroll.addView(
        column,
        ViewGroup.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT)
    )
    root.addView(scroll, LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, 0, 1f))
    return root
}

private fun LinearLayout.slider(
    label: String,
    min: Float,
    max: Float,
    initial: Float,
    format: (Float) -> String = { String.format("%.2f", it) },
    onChange: (Float) -> Unit
) {
    addView(MetroSlider(context, label, min, max, initial, format) {
        onChange(it)
        MetroMotion.notifyChanged()
    }, matchWrap())
}

private fun millis(value: Float) = String.format("%.0f ms", value)

// ---------------------------------------------------------------- start

/**
 * No page title, no chrome beyond the tiles themselves — a real WP Start screen never
 * had a header, unlike every Pivot/Panorama page which did. Tile taps are handled by
 * whoever hosts this (the Activity), since several of them now hand off to real system
 * apps (phone/camera/mail) rather than pushing another page.
 */
class StartPage(private val onTileSelect: (TileModel) -> Unit) : MetroPage {
    override fun createView(context: Context, host: PageHost): View {
        val scroll = ScrollView(context)
        val start = StartScreenView(context)
        start.tiles = SampleData.startTiles
        start.onSelect = onTileSelect
        scroll.clipChildren = false
        scroll.addView(start, ViewGroup.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT))
        return scroll
    }
}

// ---------------------------------------------------------------- detail

class DetailPage(private val name: String) : MetroPage {
    override fun createView(context: Context, host: PageHost): View =
        scaffold(context, "metrolab", name.lowercase()) {
            setPadding(0, 0, 0, MetroTheme.dpInt(32f))
            for ((index, item) in SampleData.mailPreviews.withIndex()) {
                val row = MetroListRow(context, item.first, item.third, accessory = "${index + 1}") {}
                addView(row, matchWrap())
                row.post { MetroFeather.apply(row, index) }
            }
        }
}

// ---------------------------------------------------------------- app list

class AppListPage(
    private val entries: List<String> = SampleData.appNames,
    private val onSelect: (String) -> Unit = {}
) : MetroPage {
    override fun createView(context: Context, host: PageHost): View {
        val root = LinearLayout(context).apply { orientation = LinearLayout.VERTICAL }
        root.addView(MetroPageHeader(context, "metrolab", "apps"), matchWrap())
        root.addView(
            AppListView(context, entries) { name -> onSelect(name) },
            LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, 0, 1f)
        )
        return root
    }
}

// ---------------------------------------------------------------- tiles

class TilePlaygroundPage : MetroPage {

    private var size = TileSize.MEDIUM
    private var style = TileStyle.ACCENT
    private var behaviour = TileBehaviour.FLIP
    private var accent = MetroAccent.COBALT
    private var badge = true

    override fun createView(context: Context, host: PageHost): View =
        scaffold(context, "metrolab", "tiles") {
            val preview = LinearLayout(context).apply {
                orientation = LinearLayout.HORIZONTAL
                gravity = android.view.Gravity.CENTER
                clipChildren = false
            }
            val tile = TileView(context)
            tile.unit = MetroTheme.dp(66f)
            preview.addView(tile)
            addView(preview, LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT, MetroTheme.dpInt(180f)
            ))

            fun refreshTile() {
                val w = (tile.unit * size.columns + MetroTheme.tileGap * (size.columns - 1)).toInt()
                val h = (tile.unit * size.rows + MetroTheme.tileGap * (size.rows - 1)).toInt()
                tile.layoutParams = LinearLayout.LayoutParams(w, h)
                tile.model = TileModel(
                    id = "playground-${size}-${behaviour}",
                    title = "playground",
                    glyph = MetroGlyph.MAIL,
                    accent = accent,
                    style = style,
                    size = size,
                    badge = if (badge) 12 else null,
                    behaviour = behaviour,
                    faces = listOf(
                        TileFace.Iconic,
                        TileFace.Message("Kaori", "タイルの裏面はキャプションを出さない"),
                        TileFace.Counter(12, "unread")
                    )
                )
                tile.requestLayout()
            }
            refreshTile()

            spacer(12f)
            groupTitle("footprint")
            chipRow(TileSize.values().toList(), { it.displayName }, { size == it }) {
                size = it; refreshTile()
            }
            spacer(14f)
            groupTitle("style")
            chipRow(TileStyle.values().toList(), { it.displayName }, { style == it }) {
                style = it; refreshTile()
            }
            spacer(14f)
            groupTitle("behaviour")
            chipRow(TileBehaviour.values().toList(), { it.displayName }, { behaviour == it }) {
                behaviour = it; refreshTile()
            }
            spacer(14f)
            addView(MetroToggle(context, badge) { badge = it; refreshTile() }, matchWrap())

            spacer(20f)
            groupTitle("packing")
            note("first-fit, left to right then down — a wide tile can leave holes above it that later small tiles drop into")
            val grid = StartScreenView(context)
            grid.tiles = SampleData.startTiles
            addView(grid, matchWrap())
        }

    private fun <T> LinearLayout.chipRow(
        options: List<T>,
        label: (T) -> String,
        selected: (T) -> Boolean,
        onPick: (T) -> Unit
    ) {
        val row = MetroChipRow(context)
        val chips = ArrayList<Pair<T, MetroChip>>()
        for (option in options) {
            lateinit var chip: MetroChip
            chip = MetroChip(context, label(option), selected(option)) {
                onPick(option)
                for ((o, c) in chips) c.picked = selected(o)
            }
            chips.add(option to chip)
            row.addChip(chip)
        }
        addView(row, matchWrap())
    }
}

// ---------------------------------------------------------------- motion

class MotionPage : MetroPage {
    override fun createView(context: Context, host: PageHost): View =
        scaffold(context, "metrolab", "motion") {
            groupTitle("press the tiles while you tune")
            val row = LinearLayout(context).apply {
                orientation = LinearLayout.HORIZONTAL
                clipChildren = false
            }
            val unit = MetroTheme.dp(54f)
            for (spec in listOf(
                Triple("lab-flip", TileBehaviour.FLIP, MetroAccent.COBALT),
                Triple("lab-slide", TileBehaviour.SLIDE, MetroAccent.CRIMSON)
            )) {
                val tile = TileView(context)
                tile.unit = unit
                tile.model = TileModel(
                    id = spec.first, title = spec.second.displayName.lowercase(),
                    glyph = MetroGlyph.MAIL, accent = spec.third,
                    size = TileSize.MEDIUM, badge = 3, behaviour = spec.second,
                    faces = listOf(TileFace.Iconic, TileFace.Counter(3, "unread"))
                )
                val side = (unit * 2 + MetroTheme.tileGap).toInt()
                val lp = LinearLayout.LayoutParams(side, side)
                lp.rightMargin = MetroTheme.tileGap.toInt()
                row.addView(tile, lp)
            }
            addView(row, matchWrap())

            spacer(20f)
            groupTitle("easing")
            addView(CurveInspector(context), LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT, MetroTheme.dpInt(130f)
            ))

            spacer(20f)
            groupTitle("global")
            slider("speed", 0.1f, 2f, MetroMotion.speed, { String.format("%.2f×", it) }) {
                MetroMotion.speed = it
            }

            spacer(16f)
            groupTitle("tilt")
            slider("max angle (rad)", 0f, 0.8f, MetroMotion.tiltMaxAngle) { MetroMotion.tiltMaxAngle = it }
            slider("depression", 0f, 0.25f, MetroMotion.tiltMaxDepression) { MetroMotion.tiltMaxDepression = it }
            slider("camera distance", 1f, 30f, MetroMotion.tiltCameraDistance, { String.format("%.1f×", it) }) {
                MetroMotion.tiltCameraDistance = it
            }
            slider("press", 0f, 500f, MetroMotion.tiltPressDuration.toFloat(), ::millis) {
                MetroMotion.tiltPressDuration = it.toLong()
            }
            slider("release", 0f, 600f, MetroMotion.tiltReleaseDuration.toFloat(), ::millis) {
                MetroMotion.tiltReleaseDuration = it.toLong()
            }

            spacer(16f)
            groupTitle("turnstile")
            slider("forward out", -120f, 0f, MetroMotion.turnstileForwardOutAngle, { String.format("%.0f°", it) }) {
                MetroMotion.turnstileForwardOutAngle = it
            }
            slider("forward in", 0f, 120f, MetroMotion.turnstileForwardInAngle, { String.format("%.0f°", it) }) {
                MetroMotion.turnstileForwardInAngle = it
            }
            slider("backward out", 0f, 120f, MetroMotion.turnstileBackwardOutAngle, { String.format("%.0f°", it) }) {
                MetroMotion.turnstileBackwardOutAngle = it
            }
            slider("backward in", -120f, 0f, MetroMotion.turnstileBackwardInAngle, { String.format("%.0f°", it) }) {
                MetroMotion.turnstileBackwardInAngle = it
            }
            slider("in", 50f, 1200f, MetroMotion.turnstileInDuration.toFloat(), ::millis) {
                MetroMotion.turnstileInDuration = it.toLong()
            }
            slider("out", 50f, 1200f, MetroMotion.turnstileOutDuration.toFloat(), ::millis) {
                MetroMotion.turnstileOutDuration = it.toLong()
            }

            spacer(16f)
            groupTitle("feather")
            slider("step", 0f, 300f, MetroMotion.featherDelay.toFloat(), ::millis) {
                MetroMotion.featherDelay = it.toLong()
            }
            slider("max steps", 1f, 40f, MetroMotion.featherMaxSteps.toFloat(), { String.format("%.0f", it) }) {
                MetroMotion.featherMaxSteps = it.toInt()
            }

            spacer(16f)
            groupTitle("live tiles")
            slider("flip", 100f, 1500f, MetroMotion.tileFlipDuration.toFloat(), ::millis) {
                MetroMotion.tileFlipDuration = it.toLong()
            }
            slider("slide", 100f, 1500f, MetroMotion.tileSlideDuration.toFloat(), ::millis) {
                MetroMotion.tileSlideDuration = it.toLong()
            }
            slider("dwell", 500f, 12000f, MetroMotion.tileDwell.toFloat(), ::millis) {
                MetroMotion.tileDwell = it.toLong()
            }
            slider("dwell jitter", 0f, 4000f, MetroMotion.tileDwellJitter.toFloat(), ::millis) {
                MetroMotion.tileDwellJitter = it.toLong()
            }

            spacer(16f)
            groupTitle("panorama & pivot")
            slider("background parallax", 0f, 1f, MetroMotion.panoramaParallax) { MetroMotion.panoramaParallax = it }
            slider("title parallax", 0f, 1f, MetroMotion.panoramaTitleParallax) { MetroMotion.panoramaTitleParallax = it }
            slider("snap", 100f, 1200f, MetroMotion.panoramaSnapDuration.toFloat(), ::millis) {
                MetroMotion.panoramaSnapDuration = it.toLong()
            }
            slider("pivot header", 50f, 1000f, MetroMotion.pivotHeaderDuration.toFloat(), ::millis) {
                MetroMotion.pivotHeaderDuration = it.toLong()
            }
            slider("pivot content", 50f, 1000f, MetroMotion.pivotContentDuration.toFloat(), ::millis) {
                MetroMotion.pivotContentDuration = it.toLong()
            }
            slider("pivot lag", 0f, 500f, MetroMotion.pivotContentDelay.toFloat(), ::millis) {
                MetroMotion.pivotContentDelay = it.toLong()
            }

            spacer(16f)
            groupTitle("progress")
            slider("dot period", 500f, 6000f, MetroMotion.progressDotPeriod.toFloat(), ::millis) {
                MetroMotion.progressDotPeriod = it.toLong()
            }
            addView(MetroProgressDots(context), matchWrap())

            spacer(20f)
            addView(MetroButton(context, "reset to WP defaults") {
                MetroMotion.reset()
                host.refresh()
            }, LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT, LinearLayout.LayoutParams.WRAP_CONTENT
            ))
        }
}

/** Plots the selected curve with a marker running it in real time. */
private class CurveInspector(context: Context) : View(context) {

    private val paint = android.graphics.Paint(android.graphics.Paint.ANTI_ALIAS_FLAG)
    private val path = android.graphics.Path()
    private val ease = MetroEase.wpIn

    override fun onDraw(canvas: android.graphics.Canvas) {
        val inset = MetroTheme.dp(4f)
        val w = width - inset * 2
        val h = height - inset * 2

        paint.style = android.graphics.Paint.Style.STROKE
        paint.strokeWidth = 1f
        paint.color = MetroTheme.withAlpha(MetroTheme.foreground, 0.12f)
        for (i in 0..4) {
            val y = inset + h * i / 4f
            canvas.drawLine(inset, y, inset + w, y, paint)
        }

        path.reset()
        val steps = 96
        for (i in 0..steps) {
            val x = i / steps.toFloat()
            val y = ease.progress(x)
            val px = inset + w * x
            val py = inset + h * (1f - y)
            if (i == 0) path.moveTo(px, py) else path.lineTo(px, py)
        }
        paint.strokeWidth = MetroTheme.dp(1.5f)
        paint.color = MetroTheme.accentColor
        canvas.drawPath(path, paint)

        val period = 2400L
        val t = (android.os.SystemClock.uptimeMillis() % period).toFloat() / period
        paint.style = android.graphics.Paint.Style.FILL
        paint.color = MetroTheme.foreground
        canvas.drawCircle(inset + w * t, inset + h * (1f - ease.progress(t)), MetroTheme.dp(3f), paint)

        postInvalidateOnAnimation()
    }
}

// ---------------------------------------------------------------- controls

class ControlsPage : MetroPage {
    override fun createView(context: Context, host: PageHost): View =
        scaffold(context, "metrolab", "controls") {
            groupTitle("button")
            val buttons = LinearLayout(context).apply { orientation = LinearLayout.HORIZONTAL }
            for (label in listOf("accept", "cancel")) {
                val lp = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.WRAP_CONTENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT
                )
                lp.rightMargin = MetroTheme.dpInt(10f)
                buttons.addView(MetroButton(context, label) {}, lp)
            }
            addView(buttons, matchWrap())

            spacer(20f)
            groupTitle("toggle")
            addView(MetroToggle(context, true) {}, matchWrap())

            spacer(20f)
            groupTitle("slider")
            slider("brightness", 0f, 1f, 0.4f) {}

            spacer(20f)
            groupTitle("progress")
            addView(MetroProgressDots(context), matchWrap())
            spacer(10f)
            addView(MetroProgressDots(context).apply { value = 0.35f }, matchWrap())
            spacer(14f)
            val ringRow = LinearLayout(context).apply { gravity = android.view.Gravity.CENTER }
            ringRow.addView(MetroProgressRing(context, MetroTheme.dp(56f)))
            addView(ringRow, matchWrap())

            spacer(20f)
            groupTitle("glyphs")
            var row = LinearLayout(context).apply { orientation = LinearLayout.HORIZONTAL }
            for ((index, glyph) in MetroGlyph.values().withIndex()) {
                if (index > 0 && index % 7 == 0) {
                    addView(row, matchWrap())
                    spacer(10f)
                    row = LinearLayout(context).apply { orientation = LinearLayout.HORIZONTAL }
                }
                val lp = LinearLayout.LayoutParams(MetroTheme.dpInt(30f), MetroTheme.dpInt(30f))
                lp.rightMargin = MetroTheme.dpInt(10f)
                row.addView(MetroGlyphView(context, glyph, MetroTheme.dp(30f)), lp)
            }
            addView(row, matchWrap())

            spacer(20f)
            groupTitle("list")
            for ((index, item) in SampleData.mailPreviews.withIndex()) {
                val listRow = MetroListRow(context, item.first, item.second, MetroGlyph.MAIL) {}
                addView(listRow, matchWrap())
                listRow.post { MetroFeather.apply(listRow, index) }
            }
        }
}

// ---------------------------------------------------------------- transitions

class TransitionPage : MetroPage {
    override fun createView(context: Context, host: PageHost): View =
        scaffold(context, "metrolab", "transitions") {
            note("the picker changes the transition used by the whole app — including the back button")
            val row = MetroChipRow(context)
            val chips = ArrayList<Pair<MetroTransition, MetroChip>>()
            for (kind in MetroTransition.values()) {
                lateinit var chip: MetroChip
                chip = MetroChip(context, kind.displayName, host.transition == kind) {
                    host.transition = kind
                    for ((k, c) in chips) c.picked = host.transition == k
                }
                chips.add(kind to chip)
                row.addChip(chip)
            }
            addView(row, matchWrap())

            spacer(20f)
            addView(MetroButton(context, "navigate forward") {
                host.push(DetailPage("Transition target"))
            }, LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT, LinearLayout.LayoutParams.WRAP_CONTENT
            ))

            spacer(24f)
            groupTitle("turnstile · what WP actually shipped")
            note(
                "out: rotate about the left edge to -80°, 250 ms, exponential ease-in (exponent 6)\n" +
                    "in: -80° back to 0, 350 ms, exponential ease-out\n" +
                    "opacity is a step, not a fade — the page is present from frame one"
            )
        }
}

// ---------------------------------------------------------------- type & accents

class TypePage : MetroPage {
    override fun createView(context: Context, host: PageHost): View =
        scaffold(context, "metrolab", "type ramp") {
            slider("ramp scale", 0.5f, 1.2f, MetroTheme.typeScale) {
                MetroTheme.typeScale = it
            }
            note("WP sizes are WVGA pixels. 0.78 puts them at the same apparent size on a 360dp phone. Reopen the page to re-measure.")
            spacer(12f)

            for (role in MetroRole.values()) {
                addView(MetroTextView(context, MetroRole.SMALL).apply {
                    text = "${role.name.lowercase()} · ${role.wpSize.toInt()}px"
                }, matchWrap())
                addView(MetroTextView(context, role).apply {
                    text = when (role) {
                        MetroRole.TILE_BADGE -> "12"
                        MetroRole.PANORAMA_TITLE, MetroRole.HUGE -> "panorama"
                        else -> "The quick brown fox 日本語"
                    }
                    maxLines = 1
                }, matchWrap())
                spacer(10f)
            }
        }
}

class AccentPage : MetroPage {
    override fun createView(context: Context, host: PageHost): View =
        scaffold(context, "metrolab", "accents") {
            val modes = MetroChipRow(context)
            val modeChips = ArrayList<Pair<MetroThemeMode, MetroChip>>()
            for (mode in MetroThemeMode.values()) {
                lateinit var chip: MetroChip
                chip = MetroChip(context, mode.name.lowercase(), MetroTheme.mode == mode) {
                    MetroTheme.mode = mode
                    for ((m, c) in modeChips) c.picked = MetroTheme.mode == m
                }
                modeChips.add(mode to chip)
                modes.addChip(chip)
            }
            addView(modes, matchWrap())

            spacer(14f)
            note("the twenty stock WP8 accents, at their shipping hex values")

            var row: LinearLayout? = null
            for ((index, accent) in MetroAccent.values().withIndex()) {
                if (index % 4 == 0) {
                    row = LinearLayout(context).apply { orientation = LinearLayout.HORIZONTAL }
                    addView(row, matchWrap())
                    spacer(6f)
                }
                val swatch = AccentSwatch(context, accent)
                val lp = LinearLayout.LayoutParams(0, MetroTheme.dpInt(58f), 1f)
                lp.rightMargin = MetroTheme.dpInt(6f)
                row!!.addView(swatch, lp)
            }
        }
}

private class AccentSwatch(context: Context, private val accent: MetroAccent) : View(context) {

    private val paint = android.graphics.Paint(android.graphics.Paint.ANTI_ALIAS_FLAG)
    private val textPaint = android.graphics.Paint(android.graphics.Paint.ANTI_ALIAS_FLAG)

    init {
        textPaint.textSize = MetroTheme.dp(10f)
        textPaint.typeface = MetroTheme.typeface(com.rakukura.metrolab.theme.MetroWeight.NORMAL)
        com.rakukura.metrolab.motion.TiltController(this) {
            MetroTheme.accent = accent
        }.attach()
        MetroTheme.addListener { invalidate() }
    }

    override fun onDraw(canvas: android.graphics.Canvas) {
        paint.style = android.graphics.Paint.Style.FILL
        paint.color = accent.color
        canvas.drawRect(0f, 0f, width.toFloat(), height.toFloat(), paint)

        textPaint.color = android.graphics.Color.WHITE
        canvas.drawText(
            accent.displayName, MetroTheme.dp(5f),
            height - MetroTheme.dp(5f) - textPaint.descent(), textPaint
        )

        if (MetroTheme.accent == accent) {
            paint.style = android.graphics.Paint.Style.STROKE
            paint.strokeWidth = MetroTheme.dp(2.5f)
            paint.color = MetroTheme.foreground
            val i = paint.strokeWidth / 2f
            canvas.drawRect(i, i, width - i, height - i, paint)
        }
    }
}

// ---------------------------------------------------------------- pivot & panorama

class PivotPage : MetroPage {
    override fun createView(context: Context, host: PageHost): View = PivotView(
        context,
        listOf(
            PivotItem("inbox") { ctx -> mailColumn(ctx, SampleData.mailPreviews.size, useBody = false) },
            PivotItem("unread") { ctx -> mailColumn(ctx, 3, useBody = true) },
            PivotItem("flagged") { ctx ->
                MetroListRow(ctx, "Nothing flagged", "swipe back to the inbox")
            },
            PivotItem("urgent") { ctx ->
                MetroListRow(ctx, "Nothing urgent", "the header leads, the content follows")
            }
        ),
        title = "metrolab"
    )

    private fun mailColumn(context: Context, count: Int, useBody: Boolean): View {
        val column = LinearLayout(context).apply { orientation = LinearLayout.VERTICAL }
        for ((index, item) in SampleData.mailPreviews.take(count).withIndex()) {
            val row = MetroListRow(
                context, item.first,
                if (useBody) item.third else item.second,
                accessory = "now"
            ) {}
            column.addView(row, matchWrap())
            row.post { MetroFeather.apply(row, index) }
        }
        return column
    }
}

class PanoramaPage : MetroPage {
    override fun createView(context: Context, host: PageHost): View = PanoramaView(
        context,
        listOf(
            PanoramaSection("start") { ctx ->
                StartScreenView(ctx).apply { tiles = SampleData.startTiles.take(6) }
            },
            PanoramaSection("recent") { ctx ->
                val column = LinearLayout(ctx).apply { orientation = LinearLayout.VERTICAL }
                for ((index, item) in SampleData.mailPreviews.take(5).withIndex()) {
                    val row = MetroListRow(ctx, item.first, item.second) {}
                    column.addView(row, matchWrap())
                    row.post { MetroFeather.apply(row, index) }
                }
                column
            },
            PanoramaSection("what's new") { ctx ->
                val column = LinearLayout(ctx).apply {
                    orientation = LinearLayout.VERTICAL
                    setPadding(MetroTheme.pageMargin.toInt(), 0, MetroTheme.pageMargin.toInt(), 0)
                }
                column.addView(MetroTextView(ctx, MetroRole.NORMAL).apply {
                    text = "drag sideways — three layers move at three rates"
                }, matchWrap())
                column.addView(MetroTextView(ctx, MetroRole.SMALL).apply {
                    text = "background · title · sections"
                }, matchWrap())
                column.addView(MetroProgressDots(ctx), matchWrap())
                column
            }
        ),
        title = "metro"
    )
}
