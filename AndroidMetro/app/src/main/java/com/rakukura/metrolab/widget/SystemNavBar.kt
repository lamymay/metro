package com.rakukura.metrolab.widget

import android.content.Context
import android.view.Gravity
import android.widget.LinearLayout
import com.rakukura.metrolab.glyph.MetroGlyph
import com.rakukura.metrolab.motion.TiltController
import com.rakukura.metrolab.theme.MetroTheme

/**
 * The three buttons every Windows Phone had on the bezel of every screen: Back, Start,
 * Search. This sits below the optional per-page [MetroAppBar] and never changes — WP's
 * own chrome, not the app's.
 *
 * The visual distinction from [MetroAppBar] icons is deliberate: no circle, no caption,
 * no fill. On hardware these were capacitive buttons printed on the bezel, not pixels
 * the app drew — the flattest possible treatment is the honest one.
 */
class MetroSystemNavBar(
    context: Context,
    onBack: () -> Unit,
    onStart: () -> Unit,
    onSearch: () -> Unit
) : LinearLayout(context) {

    init {
        orientation = HORIZONTAL
        setBackgroundColor(MetroTheme.chrome)
        addCell(MetroGlyph.BACK, onBack)
        addCell(MetroGlyph.START, onStart)
        addCell(MetroGlyph.SEARCH, onSearch)
    }

    private fun addCell(glyph: MetroGlyph, action: () -> Unit) {
        val cell = LinearLayout(context)
        cell.gravity = Gravity.CENTER
        cell.addView(MetroGlyphView(context, glyph, MetroTheme.dp(22f)))
        TiltController(cell) { action() }.attach()
        addView(cell, LayoutParams(0, MetroTheme.dpInt(46f), 1f))
    }
}
