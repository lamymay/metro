package com.rakukura.metrolab.music

import android.content.Context
import android.view.Gravity
import android.widget.FrameLayout
import android.widget.LinearLayout
import com.rakukura.metrolab.glyph.MetroGlyph
import com.rakukura.metrolab.motion.TiltController
import com.rakukura.metrolab.theme.MetroRole
import com.rakukura.metrolab.theme.MetroTheme
import com.rakukura.metrolab.widget.MetroGlyphView
import com.rakukura.metrolab.widget.MetroTextView

/**
 * The compact "something is playing" band WP showed above its chrome whenever you'd
 * left the Music app with a track still going. Tapping it jumps back to the full
 * now-playing screen; the play/pause glyph works right where it is.
 */
class MetroMiniPlayerBar(
    context: Context,
    private val player: MetroMusicPlayer,
    private val onOpen: () -> Unit
) : LinearLayout(context) {

    private val titleView: MetroTextView
    private val artistView: MetroTextView
    private val icon: MetroGlyphView

    init {
        orientation = HORIZONTAL
        gravity = Gravity.CENTER_VERTICAL
        setBackgroundColor(MetroTheme.chrome)
        setPadding(MetroTheme.dpInt(12f), 0, MetroTheme.dpInt(12f), 0)

        val stripe = android.view.View(context).apply {
            setBackgroundColor(player.currentSong.accent.color)
        }
        addView(stripe, LayoutParams(MetroTheme.dpInt(4f), MetroTheme.dpInt(28f)))

        val text = LinearLayout(context).apply {
            orientation = VERTICAL
            setPadding(MetroTheme.dpInt(10f), 0, 0, 0)
        }
        titleView = MetroTextView(context, MetroRole.SMALL).apply {
            setTextColor(MetroTheme.foreground)
            maxLines = 1
        }
        artistView = MetroTextView(context, MetroRole.SMALL).apply {
            setTextColor(MetroTheme.subtle)
            maxLines = 1
        }
        text.addView(titleView, LayoutParams(LayoutParams.WRAP_CONTENT, LayoutParams.WRAP_CONTENT))
        text.addView(artistView, LayoutParams(LayoutParams.WRAP_CONTENT, LayoutParams.WRAP_CONTENT))
        addView(text, LayoutParams(0, LayoutParams.WRAP_CONTENT, 1f))

        val iconCell = FrameLayout(context)
        icon = MetroGlyphView(context, MetroGlyph.PLAY, MetroTheme.dp(20f))
        iconCell.addView(icon, FrameLayout.LayoutParams(MetroTheme.dpInt(20f), MetroTheme.dpInt(20f), Gravity.CENTER))
        TiltController(iconCell) { player.togglePlayPause() }.attach()
        addView(iconCell, LayoutParams(MetroTheme.dpInt(36f), MetroTheme.dpInt(36f)))

        setOnClickListener { onOpen() }

        refresh()
        player.setListener { post { refresh() } }
    }

    fun refresh() {
        titleView.text = player.currentSong.title
        artistView.text = player.currentSong.artist
        icon.glyph = if (player.isPlaying) MetroGlyph.PAUSE else MetroGlyph.PLAY
        icon.invalidate()
    }

    override fun onMeasure(widthMeasureSpec: Int, heightMeasureSpec: Int) {
        super.onMeasure(widthMeasureSpec, MeasureSpec.makeMeasureSpec(MetroTheme.dpInt(40f), MeasureSpec.EXACTLY))
    }
}
