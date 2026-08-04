package com.rakukura.metrolab.music

import android.content.Context
import android.graphics.Color
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import android.widget.LinearLayout
import android.widget.ScrollView
import com.rakukura.metrolab.glyph.MetroGlyph
import com.rakukura.metrolab.motion.MetroFeather
import com.rakukura.metrolab.motion.TiltController
import com.rakukura.metrolab.nav.MetroPage
import com.rakukura.metrolab.nav.PageHost
import com.rakukura.metrolab.pivot.PivotItem
import com.rakukura.metrolab.pivot.PivotView
import com.rakukura.metrolab.theme.MetroRole
import com.rakukura.metrolab.theme.MetroTheme
import com.rakukura.metrolab.widget.AppBarItem
import com.rakukura.metrolab.widget.MetroAppBar
import com.rakukura.metrolab.widget.MetroGlyphView
import com.rakukura.metrolab.widget.MetroListRow
import com.rakukura.metrolab.widget.MetroSlider
import com.rakukura.metrolab.widget.MetroTextView

/**
 * A working stand-in for Xbox Music's now-playing pivot: real transport controls over
 * synthesised audio, a collection list, and a "get music" promo grid — the three tabs
 * visible in the reference screenshots.
 */
class MetroMusicPage(private val player: MetroMusicPlayer) : MetroPage {

    override fun createView(context: Context, host: PageHost): View {
        val root = FrameLayout(context)

        // Xbox Music's now-playing pivot sat over a wash tinted by the current album's
        // art rather than flat black — the one page in the app that breaks that rule,
        // on purpose, because the reference does too.
        val background = MetroAlbumArtView(context, player.currentSong.accent).apply {
            alpha = 0.55f
        }
        root.addView(background, ViewGroup.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT))
        root.addView(
            View(context).apply { setBackgroundColor(MetroTheme.withAlpha(0x000000, 0.4f)) },
            ViewGroup.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT)
        )

        val pivot = PivotView(
            context,
            listOf(
                PivotItem("now playing") { ctx -> nowPlayingTab(ctx) },
                PivotItem("collection") { ctx -> collectionTab(ctx) },
                PivotItem("get music") { ctx -> getMusicTab(ctx) }
            ),
            title = "music"
        )
        root.addView(pivot, ViewGroup.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT))

        player.setListener {
            background.accent = player.currentSong.accent
            background.invalidate()
        }
        return root
    }

    private fun nowPlayingTab(context: Context): View {
        val column = LinearLayout(context).apply { orientation = LinearLayout.VERTICAL }

        val artRow = FrameLayout(context)
        val art = MetroAlbumArtView(context, player.currentSong.accent)
        val artSize = MetroTheme.dpInt(220f)
        artRow.addView(art, FrameLayout.LayoutParams(artSize, artSize, Gravity.CENTER))
        column.addView(artRow, LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, MetroTheme.dpInt(240f)))

        val titleView = MetroTextView(context, MetroRole.TITLE2).apply { maxLines = 1 }
        val artistView = MetroTextView(context, MetroRole.NORMAL).apply {
            setTextColor(MetroTheme.subtle)
            maxLines = 1
        }
        val textCol = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(MetroTheme.pageMargin.toInt(), MetroTheme.dpInt(16f), MetroTheme.pageMargin.toInt(), 0)
            addView(titleView, LinearLayout.LayoutParams(LinearLayout.LayoutParams.WRAP_CONTENT, LinearLayout.LayoutParams.WRAP_CONTENT))
            addView(artistView, LinearLayout.LayoutParams(LinearLayout.LayoutParams.WRAP_CONTENT, LinearLayout.LayoutParams.WRAP_CONTENT))
        }
        column.addView(textCol, LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT))

        val timeRow = LinearLayout(context).apply {
            orientation = LinearLayout.HORIZONTAL
            setPadding(MetroTheme.pageMargin.toInt(), MetroTheme.dpInt(4f), MetroTheme.pageMargin.toInt(), 0)
        }
        val elapsedView = MetroTextView(context, MetroRole.SMALL)
        val durationView = MetroTextView(context, MetroRole.SMALL)
        timeRow.addView(elapsedView, LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f))
        timeRow.addView(durationView, LinearLayout.LayoutParams(LinearLayout.LayoutParams.WRAP_CONTENT, LinearLayout.LayoutParams.WRAP_CONTENT))

        lateinit var slider: MetroSlider
        slider = MetroSlider(
            context, "",
            0f, (player.currentSong.durationSeconds * 1000).toFloat(),
            player.currentTimeMs.toFloat(),
            format = { "" }
        ) { value -> player.seek(value.toInt()) }
        val sliderContainer = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(MetroTheme.pageMargin.toInt(), MetroTheme.dpInt(6f), MetroTheme.pageMargin.toInt(), 0)
            addView(slider, LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT))
        }
        column.addView(sliderContainer, LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT))
        column.addView(timeRow, LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT))

        val controls = LinearLayout(context).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER
            setPadding(0, MetroTheme.dpInt(24f), 0, 0)
        }
        val prev = transportButton(context, MetroGlyph.SKIP_PREVIOUS, 26f) { player.previous() }
        val playPause = transportButton(context, if (player.isPlaying) MetroGlyph.PAUSE else MetroGlyph.PLAY, 34f) {
            player.togglePlayPause()
        }
        val next = transportButton(context, MetroGlyph.SKIP_NEXT, 26f) { player.next() }
        val spacing = MetroTheme.dpInt(28f)
        controls.addView(prev, LinearLayout.LayoutParams(MetroTheme.dpInt(56f), MetroTheme.dpInt(56f)).apply { rightMargin = spacing })
        controls.addView(playPause, LinearLayout.LayoutParams(MetroTheme.dpInt(56f), MetroTheme.dpInt(56f)).apply { rightMargin = spacing })
        controls.addView(next, LinearLayout.LayoutParams(MetroTheme.dpInt(56f), MetroTheme.dpInt(56f)))
        column.addView(controls, LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT))

        val bottomSpacer = View(context)
        column.addView(bottomSpacer, LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, 0, 1f))

        val appBar = MetroAppBar(
            context,
            items = listOf(
                AppBarItem(MetroGlyph.PIN, "pin") {},
                AppBarItem(MetroGlyph.SEARCH, "find") {}
            )
        )
        column.addView(appBar, LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT))

        fun refresh() {
            titleView.text = player.currentSong.title
            artistView.text = player.currentSong.artist
            elapsedView.text = format(player.currentTimeMs)
            durationView.text = format(player.currentSong.durationSeconds * 1000)
            slider.value = player.currentTimeMs.toFloat()
            (playPause as? FrameLayout)?.let {
                val icon = it.getChildAt(0) as? MetroGlyphView
                icon?.glyph = if (player.isPlaying) MetroGlyph.PAUSE else MetroGlyph.PLAY
                icon?.invalidate()
            }
        }
        refresh()
        player.setListener { column.post { refresh() } }

        return column
    }

    private fun format(ms: Int): String {
        val totalSeconds = ms / 1000
        return String.format("%d:%02d", totalSeconds / 60, totalSeconds % 60)
    }

    private fun transportButton(context: Context, glyph: MetroGlyph, sizeDp: Float, action: () -> Unit): View {
        val cell = FrameLayout(context)
        val icon = MetroGlyphView(context, glyph, MetroTheme.dp(sizeDp))
        cell.addView(icon, FrameLayout.LayoutParams(MetroTheme.dpInt(sizeDp), MetroTheme.dpInt(sizeDp), Gravity.CENTER))
        TiltController(cell) { action() }.attach()
        return cell
    }

    private fun collectionTab(context: Context): View {
        val column = LinearLayout(context).apply { orientation = LinearLayout.VERTICAL }
        for ((index, category) in listOf("artists", "albums", "songs", "genres", "playlists", "radio").withIndex()) {
            val row = MetroListRow(context, category) {}
            column.addView(row, LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT))
            row.post { MetroFeather.apply(row, index) }
        }
        return column
    }

    private fun getMusicTab(context: Context): View {
        val scroll = ScrollView(context)
        val column = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(MetroTheme.pageMargin.toInt(), 0, MetroTheme.pageMargin.toInt(), MetroTheme.dpInt(32f))
        }

        val promoRow = LinearLayout(context).apply { orientation = LinearLayout.HORIZONTAL }
        for ((index, title) in listOf("Top music", "Browse by genre").withIndex()) {
            val tile = promoTile(context, title)
            val lp = LinearLayout.LayoutParams(0, MetroTheme.dpInt(110f), 1f)
            if (index == 0) lp.rightMargin = MetroTheme.dpInt(6f) else lp.leftMargin = MetroTheme.dpInt(6f)
            promoRow.addView(tile, lp)
        }
        column.addView(promoRow, LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT))

        column.addView(MetroTextView(context, MetroRole.SMALL).apply {
            text = "${player.playlist.size} downloads"
            setPadding(0, MetroTheme.dpInt(12f), 0, MetroTheme.dpInt(8f))
        }, LinearLayout.LayoutParams(LinearLayout.LayoutParams.WRAP_CONTENT, LinearLayout.LayoutParams.WRAP_CONTENT))

        for (song in player.playlist) {
            column.addView(
                MetroListRow(context, song.title, song.artist) {},
                LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT)
            )
        }
        scroll.addView(column, ViewGroup.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT))
        return scroll
    }

    private fun promoTile(context: Context, title: String): View {
        val frame = FrameLayout(context)
        frame.setBackgroundColor(com.rakukura.metrolab.theme.MetroAccent.EMERALD.color)
        val label = MetroTextView(context, MetroRole.TITLE3).apply {
            setTextColor(Color.WHITE)
            text = title
        }
        frame.addView(label, FrameLayout.LayoutParams(FrameLayout.LayoutParams.WRAP_CONTENT, FrameLayout.LayoutParams.WRAP_CONTENT, Gravity.BOTTOM or Gravity.START).apply {
            leftMargin = MetroTheme.dpInt(10f)
            bottomMargin = MetroTheme.dpInt(10f)
        })
        TiltController(frame) {}.attach()
        return frame
    }
}
