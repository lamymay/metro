package com.rakukura.metrolab.applist

import android.content.Context
import android.graphics.Canvas
import android.graphics.Paint
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import android.widget.LinearLayout
import android.widget.ScrollView
import com.rakukura.metrolab.glyph.MetroGlyph
import com.rakukura.metrolab.motion.MetroFeather
import com.rakukura.metrolab.motion.TiltController
import com.rakukura.metrolab.theme.MetroAccent
import com.rakukura.metrolab.theme.MetroRole
import com.rakukura.metrolab.theme.MetroTheme
import com.rakukura.metrolab.widget.MetroGlyphView
import com.rakukura.metrolab.widget.MetroGroupHeader
import com.rakukura.metrolab.widget.MetroTextView

/**
 * The WP app list: an alphabetically grouped list whose group headers zoom out to a grid
 * of letters. `LongListSelector` called this semantic zoom, and it is the reason a
 * 200-app phone never needed a scrollbar.
 */
class AppListView(
    context: Context,
    private val entries: List<String>,
    private val onSelect: ((String) -> Unit)? = null
) : FrameLayout(context) {

    /** `#` collects everything that does not start with a Latin letter — numerals, CJK. */
    private val letters: List<String> = listOf("#") + ('A'..'Z').map { it.toString() }

    private val grouped: Map<String, List<String>> = entries.groupBy { name ->
        val first = name.uppercase().firstOrNull()
        if (first != null && first in 'A'..'Z') first.toString() else "#"
    }

    private val listScroll = ScrollView(context)
    private val listColumn = LinearLayout(context).apply { orientation = LinearLayout.VERTICAL }
    private val gridScroll = ScrollView(context)
    private val headerAnchors = HashMap<String, View>()

    init {
        listScroll.isFillViewport = true
        listScroll.addView(
            listColumn,
            ViewGroup.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT)
        )
        buildList()
        addView(listScroll, LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT))

        gridScroll.visibility = GONE
        gridScroll.addView(
            buildGrid(),
            ViewGroup.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT)
        )
        addView(gridScroll, LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT))
    }

    private fun buildList() {
        listColumn.removeAllViews()
        headerAnchors.clear()
        for (letter in letters) {
            // A plain sort is case-sensitive — ASCII 'M' sorts before lowercase 'a', so
            // "FM Radio" would land before "Facebook". WP's list was alphabetised
            // case-insensitively; match that.
            val group = grouped[letter]?.sortedWith(String.CASE_INSENSITIVE_ORDER) ?: continue
            if (group.isEmpty()) continue

            val header = MetroGroupHeader(context, letter) { zoomOut() }
            headerAnchors[letter] = header
            listColumn.addView(
                header,
                LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT
                )
            )

            for ((index, name) in group.withIndex()) {
                val row = appRow(name)
                listColumn.addView(
                    row,
                    LinearLayout.LayoutParams(
                        LinearLayout.LayoutParams.MATCH_PARENT,
                        LinearLayout.LayoutParams.WRAP_CONTENT
                    )
                )
                row.post { MetroFeather.apply(row, index) }
            }
        }
        listColumn.setPadding(0, 0, 0, MetroTheme.dpInt(32f))
    }

    /** WP's app list row was never bare text — every entry carried the app's own small
     * tile icon on the left. There are no real app icons to draw from, so each name
     * gets a deterministic glyph (by keyword) and accent (by hash) — enough to read as
     * "a wall of distinct apps" rather than a plain text list. */
    private fun appRow(name: String): View {
        val row = LinearLayout(context)
        row.orientation = LinearLayout.HORIZONTAL
        row.gravity = Gravity.CENTER_VERTICAL
        row.setPadding(MetroTheme.pageMargin.toInt(), MetroTheme.dpInt(8f), MetroTheme.pageMargin.toInt(), MetroTheme.dpInt(8f))

        val square = FrameLayout(context)
        square.setBackgroundColor(accentFor(name).color)
        val icon = MetroGlyphView(context, glyphFor(name), MetroTheme.dp(20f), android.graphics.Color.WHITE)
        square.addView(icon, FrameLayout.LayoutParams(MetroTheme.dpInt(20f), MetroTheme.dpInt(20f), Gravity.CENTER))
        row.addView(square, LinearLayout.LayoutParams(MetroTheme.dpInt(36f), MetroTheme.dpInt(36f)).apply { rightMargin = MetroTheme.dpInt(14f) })

        row.addView(MetroTextView(context, MetroRole.TITLE3).apply {
            text = name
            maxLines = 1
        }, LinearLayout.LayoutParams(LinearLayout.LayoutParams.WRAP_CONTENT, LinearLayout.LayoutParams.WRAP_CONTENT))

        TiltController(row) { onSelect?.invoke(name) }.attach()
        return row
    }

    private fun glyphFor(name: String): MetroGlyph {
        val n = name.lowercase()
        val table = listOf(
            "phone" to MetroGlyph.PHONE, "nokia care" to MetroGlyph.PHONE,
            "mail" to MetroGlyph.MAIL, "outlook" to MetroGlyph.MAIL, "email" to MetroGlyph.MAIL,
            "message" to MetroGlyph.MESSAGE, "whatsapp" to MetroGlyph.MESSAGE, "微信" to MetroGlyph.MESSAGE,
            "people" to MetroGlyph.PEOPLE, "contact" to MetroGlyph.PEOPLE, "kids corner" to MetroGlyph.PEOPLE,
            "camera" to MetroGlyph.CAMERA, "lens" to MetroGlyph.CAMERA,
            "calendar" to MetroGlyph.CALENDAR,
            "music" to MetroGlyph.MUSIC, "radio" to MetroGlyph.MUSIC, "podcast" to MetroGlyph.MUSIC, "voice recorder" to MetroGlyph.MUSIC,
            "store" to MetroGlyph.STORE, "amazon" to MetroGlyph.STORE,
            "settings" to MetroGlyph.SETTINGS, "battery" to MetroGlyph.SETTINGS, "data sense" to MetroGlyph.SETTINGS,
            "bing" to MetroGlyph.SEARCH, "search" to MetroGlyph.SEARCH,
            "weather" to MetroGlyph.SUN,
            "alarm" to MetroGlyph.CLOCK, "clock" to MetroGlyph.CLOCK,
            "photo" to MetroGlyph.PHOTO, "video" to MetroGlyph.PHOTO,
            "file" to MetroGlyph.FOLDER, "document" to MetroGlyph.FOLDER, "onedrive" to MetroGlyph.FOLDER,
            "office" to MetroGlyph.FOLDER, "word" to MetroGlyph.FOLDER, "onenote" to MetroGlyph.FOLDER,
            "note" to MetroGlyph.FOLDER, "reading list" to MetroGlyph.FOLDER,
            "map" to MetroGlyph.GLOBE, "drive" to MetroGlyph.GLOBE, "travel" to MetroGlyph.GLOBE, "translator" to MetroGlyph.GLOBE,
            "百度地图" to MetroGlyph.GLOBE,
            "wallet" to MetroGlyph.STAR, "1password" to MetroGlyph.STAR, "game" to MetroGlyph.STAR, "xbox" to MetroGlyph.STAR, "sport" to MetroGlyph.STAR,
            "health" to MetroGlyph.HEART,
            "news" to MetroGlyph.GLOBE,
            "facebook" to MetroGlyph.MESSAGE, "twitter" to MetroGlyph.MESSAGE, "instagram" to MetroGlyph.CAMERA
        )
        for ((key, glyph) in table) if (n.contains(key)) return glyph
        return MetroGlyph.FOLDER
    }

    private fun accentFor(name: String): MetroAccent {
        val all = MetroAccent.values()
        var hash = 0
        for (c in name) hash = (hash * 31 + c.code) and 0x7FFFFFFF
        return all[hash % all.size]
    }

    private fun buildGrid(): View {
        val grid = LetterGrid(context) { letter ->
            zoomIn(letter)
        }
        grid.letters = letters.map { it to (grouped[it]?.isNotEmpty() == true) }
        return grid
    }

    private fun zoomOut() {
        gridScroll.visibility = VISIBLE
        listScroll.visibility = GONE
        val grid = (gridScroll.getChildAt(0) as? LetterGrid) ?: return
        grid.post { grid.replayFeather() }
    }

    private fun zoomIn(letter: String) {
        gridScroll.visibility = GONE
        listScroll.visibility = VISIBLE
        val anchor = headerAnchors[letter] ?: return
        listScroll.post { listScroll.scrollTo(0, anchor.top) }
    }
}

/** The semantic-zoom letter grid: four columns of accent squares. */
private class LetterGrid(
    context: Context,
    private val onPick: (String) -> Unit
) : ViewGroup(context) {

    var letters: List<Pair<String, Boolean>> = emptyList()
        set(value) {
            field = value
            rebuild()
        }

    private val columns = 4
    private var cell = 0

    private fun rebuild() {
        removeAllViews()
        for ((letter, enabled) in letters) {
            addView(LetterCell(context, letter, enabled) { if (enabled) onPick(letter) })
        }
        requestLayout()
    }

    fun replayFeather() {
        for (i in 0 until childCount) MetroFeather.apply(getChildAt(i), i)
    }

    override fun onMeasure(widthMeasureSpec: Int, heightMeasureSpec: Int) {
        val width = MeasureSpec.getSize(widthMeasureSpec)
        val margin = MetroTheme.pageMargin.toInt()
        val gap = MetroTheme.tileGap.toInt()
        cell = ((width - margin * 2 - gap * (columns - 1)) / columns).coerceAtLeast(MetroTheme.dpInt(24f))

        val spec = MeasureSpec.makeMeasureSpec(cell, MeasureSpec.EXACTLY)
        for (i in 0 until childCount) getChildAt(i).measure(spec, spec)

        val rows = (childCount + columns - 1) / columns
        val height = rows * cell + (rows - 1).coerceAtLeast(0) * gap + margin * 2
        setMeasuredDimension(width, height)
    }

    override fun onLayout(changed: Boolean, l: Int, t: Int, r: Int, b: Int) {
        val margin = MetroTheme.pageMargin.toInt()
        val gap = MetroTheme.tileGap.toInt()
        for (i in 0 until childCount) {
            val col = i % columns
            val row = i / columns
            val x = margin + col * (cell + gap)
            val y = margin + row * (cell + gap)
            getChildAt(i).layout(x, y, x + cell, y + cell)
        }
    }
}

private class LetterCell(
    context: Context,
    private val letter: String,
    private val enabled: Boolean,
    action: () -> Unit
) : View(context) {

    private val paint = Paint(Paint.ANTI_ALIAS_FLAG)
    private val textPaint = Paint(Paint.ANTI_ALIAS_FLAG)

    init {
        textPaint.textSize = MetroTheme.textSize(MetroRole.TITLE1)
        textPaint.typeface = MetroTheme.typeface(MetroRole.TITLE1.weight)
        val tilt = TiltController(this) { action() }
        tilt.enabled = enabled
        tilt.attach()
    }

    override fun onDraw(canvas: Canvas) {
        if (enabled) {
            paint.style = Paint.Style.FILL
            paint.color = MetroTheme.accentColor
            canvas.drawRect(0f, 0f, width.toFloat(), height.toFloat(), paint)
        } else {
            paint.style = Paint.Style.STROKE
            paint.strokeWidth = 1f
            paint.color = MetroTheme.withAlpha(MetroTheme.disabled, 0.5f)
            canvas.drawRect(0.5f, 0.5f, width - 0.5f, height - 0.5f, paint)
        }
        textPaint.color = if (enabled) MetroTheme.onAccent else MetroTheme.disabled
        canvas.drawText(
            letter.lowercase(),
            MetroTheme.dp(6f),
            height - MetroTheme.dp(5f) - textPaint.descent(),
            textPaint
        )
    }
}
