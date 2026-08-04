package com.rakukura.metrolab.settings

import android.content.Context
import android.graphics.Color
import android.view.Gravity
import android.view.View
import android.widget.FrameLayout
import android.widget.GridLayout
import android.widget.LinearLayout
import com.rakukura.metrolab.glyph.MetroGlyph
import com.rakukura.metrolab.motion.TiltController
import com.rakukura.metrolab.theme.MetroRole
import com.rakukura.metrolab.theme.MetroTheme
import com.rakukura.metrolab.widget.MetroGlyphView
import com.rakukura.metrolab.widget.MetroTextView

private data class ActionItem(val title: String, val glyph: MetroGlyph, val isOn: () -> Boolean, val action: () -> Unit)

/**
 * WP 8.1's Action Center: drag down from the top edge, get a grid of quick-toggle
 * tiles plus notifications, dismiss by dragging back up or tapping outside it.
 *
 * Brightness and torch are wired to [MetroDeviceCapabilities] and actually work. WiFi,
 * Bluetooth, airplane mode and rotation lock stay local booleans — no sandboxed app can
 * touch those radios, and pretending otherwise would be the one dishonest control in
 * the whole app.
 */
class MetroActionCenter(
    context: Context,
    private val device: MetroDeviceCapabilities,
    private val onOpenSettings: () -> Unit
) : LinearLayout(context) {

    private var wifiOn = true
    private var bluetoothOn = false
    private var airplaneOn = false
    private var rotationLocked = false

    private val grid = GridLayout(context).apply {
        columnCount = 4
    }

    init {
        orientation = VERTICAL
        setBackgroundColor(MetroTheme.chrome)

        addView(grid, LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT).apply {
            leftMargin = MetroTheme.pageMargin.toInt()
            rightMargin = MetroTheme.pageMargin.toInt()
            topMargin = MetroTheme.dpInt(14f)
        })
        rebuildGrid()

        val settingsRow = LinearLayout(context).apply {
            orientation = HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            setPadding(MetroTheme.pageMargin.toInt(), MetroTheme.dpInt(14f), MetroTheme.pageMargin.toInt(), MetroTheme.dpInt(12f))
        }
        settingsRow.addView(MetroGlyphView(context, MetroGlyph.SETTINGS, MetroTheme.dp(18f)))
        settingsRow.addView(MetroTextView(context, MetroRole.SMALL).apply {
            text = "all settings"
            setPadding(MetroTheme.dpInt(10f), 0, 0, 0)
        })
        TiltController(settingsRow) { onOpenSettings() }.attach()
        addView(settingsRow, LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT))

        addView(View(context).apply { setBackgroundColor(MetroTheme.border) }, LayoutParams(LayoutParams.MATCH_PARENT, MetroTheme.dpInt(1f)))

        addView(MetroTextView(context, MetroRole.SMALL).apply {
            text = "no notifications"
            setTextColor(MetroTheme.subtle)
            setPadding(MetroTheme.pageMargin.toInt(), MetroTheme.dpInt(14f), MetroTheme.pageMargin.toInt(), MetroTheme.dpInt(14f))
        }, LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT))

        val handle = View(context).apply { setBackgroundColor(MetroTheme.subtle) }
        val handleFrame = FrameLayout(context)
        handleFrame.addView(handle, FrameLayout.LayoutParams(MetroTheme.dpInt(44f), MetroTheme.dpInt(4f), Gravity.CENTER))
        addView(handleFrame, LayoutParams(LayoutParams.MATCH_PARENT, MetroTheme.dpInt(18f)))

        device.addListener { rebuildGrid() }
    }

    private fun items(): List<ActionItem> = listOf(
        ActionItem("wifi", MetroGlyph.WIFI, { wifiOn }) { wifiOn = !wifiOn; rebuildGrid() },
        ActionItem("bluetooth", MetroGlyph.BLUETOOTH, { bluetoothOn }) { bluetoothOn = !bluetoothOn; rebuildGrid() },
        ActionItem(if (device.torchOn) "torch: on" else "torch", MetroGlyph.FLASHLIGHT, { device.torchOn }) {
            device.torchOn = !device.torchOn
        },
        ActionItem("rotation lock", MetroGlyph.REFRESH, { rotationLocked }) { rotationLocked = !rotationLocked; rebuildGrid() },
        ActionItem("airplane mode", MetroGlyph.AIRPLANE, { airplaneOn }) { airplaneOn = !airplaneOn; rebuildGrid() },
        ActionItem(brightnessLabel(), MetroGlyph.SUN, { device.brightness > 0.6f }) {
            // Cycles low → high → low, the way WP's own brightness quick tile did.
            val next = if (device.brightness > 0.66f) 0.18f else if (device.brightness > 0.33f) 1f else 0.66f
            device.setBrightness(next)
        }
    )

    private fun brightnessLabel(): String = when {
        device.brightness > 0.66f -> "brightness: high"
        device.brightness > 0.33f -> "brightness: med"
        else -> "brightness: low"
    }

    private fun rebuildGrid() {
        grid.removeAllViews()
        val cellSize = MetroTheme.dpInt(72f)
        val gap = MetroTheme.dpInt(8f)
        for (item in items()) {
            val cell = buildTile(item, cellSize)
            val lp = GridLayout.LayoutParams(GridLayout.spec(GridLayout.UNDEFINED), GridLayout.spec(GridLayout.UNDEFINED))
            lp.width = cellSize
            lp.height = LinearLayout.LayoutParams.WRAP_CONTENT
            lp.setMargins(0, 0, gap, gap)
            grid.addView(cell, lp)
        }
    }

    private fun buildTile(item: ActionItem, size: Int): View {
        val column = LinearLayout(context).apply { orientation = VERTICAL }
        val square = FrameLayout(context)
        // `View.foreground` needs API 23; a single background drawable that combines
        // fill and stroke works from API 1 and looks identical here since the tile has
        // no child content overlapping its edge except the centred icon.
        square.background = android.graphics.drawable.GradientDrawable().apply {
            if (item.isOn()) {
                setColor(MetroTheme.accentColor)
            } else {
                setColor(Color.TRANSPARENT)
                setStroke(MetroTheme.borderWidth.toInt().coerceAtLeast(1), MetroTheme.border)
            }
        }
        val icon = MetroGlyphView(context, item.glyph, MetroTheme.dp(22f), if (item.isOn()) MetroTheme.onAccent else MetroTheme.foreground)
        square.addView(icon, FrameLayout.LayoutParams(MetroTheme.dpInt(22f), MetroTheme.dpInt(22f), Gravity.CENTER))
        TiltController(square) { item.action() }.attach()
        column.addView(square, LinearLayout.LayoutParams(size, size))

        column.addView(MetroTextView(context, MetroRole.SMALL).apply {
            text = item.title
            setTextSize(android.util.TypedValue.COMPLEX_UNIT_PX, MetroTheme.textSize(MetroRole.SMALL) * 0.85f)
            maxLines = 1
            setPadding(0, MetroTheme.dpInt(4f), 0, 0)
        }, LinearLayout.LayoutParams(size, LinearLayout.LayoutParams.WRAP_CONTENT))
        return column
    }
}
