package com.rakukura.metrolab.photos

import android.content.Context
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import android.widget.GridLayout
import android.widget.LinearLayout
import android.widget.ScrollView
import com.rakukura.metrolab.lab.SampleData
import com.rakukura.metrolab.motion.TiltController
import com.rakukura.metrolab.music.MetroAlbumArtView
import com.rakukura.metrolab.nav.MetroPage
import com.rakukura.metrolab.nav.PageHost
import com.rakukura.metrolab.pivot.PivotItem
import com.rakukura.metrolab.pivot.PivotView
import com.rakukura.metrolab.theme.MetroRole
import com.rakukura.metrolab.theme.MetroTheme
import com.rakukura.metrolab.widget.MetroTextView

/**
 * WP's Photos hub: a dense square grid of everything, and a pivot over to Albums.
 * There is no photo library here, so every thumbnail is generated art — the same
 * technique the music player uses for album covers, just with a different seed per
 * tile so the grid doesn't repeat.
 */
class MetroPhotosPage : MetroPage {

    override fun createView(context: Context, host: PageHost): View {
        val root = FrameLayout(context)
        val pivot = PivotView(
            context,
            listOf(
                PivotItem("all") { ctx -> grid(ctx, root) },
                PivotItem("albums") { ctx -> albumsTab(ctx) }
            ),
            title = "photos"
        )
        root.addView(pivot, ViewGroup.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT))
        return root
    }

    private fun grid(context: Context, overlayHost: FrameLayout): View {
        val scroll = ScrollView(context)
        val gridLayout = GridLayout(context).apply { columnCount = 4 }

        scroll.post {
            val cellSize = (scroll.width - MetroTheme.dpInt(9f)) / 4
            gridLayout.removeAllViews()
            for ((index, accent) in SampleData.photoAccents.withIndex()) {
                val art = MetroAlbumArtView(context, accent)
                TiltController(art) { openDetail(context, overlayHost, index) }.attach()
                val lp = GridLayout.LayoutParams(GridLayout.spec(GridLayout.UNDEFINED), GridLayout.spec(GridLayout.UNDEFINED))
                lp.width = cellSize
                lp.height = cellSize
                lp.setMargins(0, 0, MetroTheme.dpInt(3f), MetroTheme.dpInt(3f))
                gridLayout.addView(art, lp)
            }
        }

        scroll.addView(gridLayout, ViewGroup.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT))
        return scroll
    }

    private fun openDetail(context: Context, host: FrameLayout, index: Int) {
        val overlay = FrameLayout(context).apply { setBackgroundColor(android.graphics.Color.BLACK) }
        val accent = SampleData.photoAccents[index % SampleData.photoAccents.size]
        val art = MetroAlbumArtView(context, accent)
        overlay.addView(art, FrameLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT))
        overlay.setOnClickListener { host.removeView(overlay) }
        host.addView(overlay, ViewGroup.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT))
    }

    private fun albumsTab(context: Context): View {
        val scroll = ScrollView(context)
        val column = LinearLayout(context).apply { orientation = LinearLayout.VERTICAL }

        for (album in SampleData.albums) {
            val row = LinearLayout(context).apply {
                orientation = LinearLayout.HORIZONTAL
                gravity = Gravity.CENTER_VERTICAL
                setPadding(MetroTheme.pageMargin.toInt(), MetroTheme.dpInt(8f), MetroTheme.pageMargin.toInt(), MetroTheme.dpInt(8f))
            }
            val art = MetroAlbumArtView(context, album.accent)
            row.addView(art, LinearLayout.LayoutParams(MetroTheme.dpInt(52f), MetroTheme.dpInt(52f)).apply { rightMargin = MetroTheme.dpInt(14f) })

            val textColumn = LinearLayout(context).apply { orientation = LinearLayout.VERTICAL }
            textColumn.addView(MetroTextView(context, MetroRole.TITLE3).apply { text = album.name }, LinearLayout.LayoutParams(LinearLayout.LayoutParams.WRAP_CONTENT, LinearLayout.LayoutParams.WRAP_CONTENT))
            textColumn.addView(MetroTextView(context, MetroRole.SMALL).apply { text = "${album.count} photos" }, LinearLayout.LayoutParams(LinearLayout.LayoutParams.WRAP_CONTENT, LinearLayout.LayoutParams.WRAP_CONTENT))
            row.addView(textColumn, LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f))

            column.addView(row, LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT))
        }
        scroll.addView(column, ViewGroup.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT))
        return scroll
    }
}
