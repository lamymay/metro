package com.rakukura.metrolab.settings

import android.content.Context
import android.view.View
import android.widget.LinearLayout
import com.rakukura.metrolab.motion.MetroFeather
import com.rakukura.metrolab.nav.MetroPage
import com.rakukura.metrolab.nav.PageHost
import com.rakukura.metrolab.pivot.PivotItem
import com.rakukura.metrolab.pivot.PivotView
import com.rakukura.metrolab.widget.MetroListRow

/**
 * The settings list, split into WP's own "system" / "application" pivot. Every row
 * exists; only a few open something real — the rest are placeholders, same as most of
 * a real phone's settings would be for a UI clone with no device entitlements.
 */
class MetroSettingsPage(private val onSelect: (String) -> Unit) : MetroPage {

    override fun createView(context: Context, host: PageHost): View = PivotView(
        context,
        listOf(
            PivotItem("system") { ctx -> list(ctx, MetroSettingsData.system) },
            PivotItem("application") { ctx -> list(ctx, MetroSettingsData.applications) }
        ),
        title = "settings"
    )

    private fun list(context: Context, items: List<MetroSettingsItem>): View {
        val column = LinearLayout(context).apply { orientation = LinearLayout.VERTICAL }
        for ((index, item) in items.withIndex()) {
            val row = MetroListRow(context, item.title, item.subtitle, item.glyph) { onSelect(item.key) }
            column.addView(row, LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT))
            row.post { MetroFeather.apply(row, index) }
        }
        return column
    }
}
