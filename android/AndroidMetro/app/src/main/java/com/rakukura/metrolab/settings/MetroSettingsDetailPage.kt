package com.rakukura.metrolab.settings

import android.content.Context
import android.view.View
import android.view.ViewGroup
import android.widget.LinearLayout
import android.widget.ScrollView
import com.rakukura.metrolab.lab.AccentPage
import com.rakukura.metrolab.nav.MetroPage
import com.rakukura.metrolab.nav.PageHost
import com.rakukura.metrolab.theme.MetroRole
import com.rakukura.metrolab.theme.MetroTheme
import com.rakukura.metrolab.widget.MetroPageHeader
import com.rakukura.metrolab.widget.MetroSlider
import com.rakukura.metrolab.widget.MetroTextView
import com.rakukura.metrolab.widget.MetroToggle
import com.rakukura.metrolab.widget.columnWithMargins

/**
 * Dispatches a settings key to either a real, working control or an honest
 * placeholder. "start+theme" reuses [AccentPage] — the one settings screen that was
 * already real everywhere else in the app.
 */
class MetroSettingsDetailPage(
    private val key: String,
    private val device: MetroDeviceCapabilities
) : MetroPage {

    override fun createView(context: Context, host: PageHost): View = when (key) {
        "theme" -> AccentPage().createView(context, host)
        "lockscreen" -> lockScreenPage(context)
        "brightness" -> brightnessPage(context)
        "battery" -> batteryPage(context)
        else -> placeholderPage(context)
    }

    private fun scaffold(context: Context, title: String, body: LinearLayout.() -> Unit): View {
        val root = LinearLayout(context).apply { orientation = LinearLayout.VERTICAL }
        root.addView(MetroPageHeader(context, "settings", title), LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT))
        val scroll = ScrollView(context)
        val column = columnWithMargins(context)
        column.body()
        scroll.addView(column, ViewGroup.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT))
        root.addView(scroll, LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, 0, 1f))
        return root
    }

    private fun lockScreenPage(context: Context): View = scaffold(context, "lock screen") {
        addView(MetroTextView(context, MetroRole.SMALL).apply {
            text = "WP put a screen-timeout picker here. A sandboxed app can't change the system timeout, but it can hold the screen awake itself while this page is open."
        }, LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT))

        addView(
            MetroToggle(context, device.keepAwake) { device.keepAwake = it },
            LinearLayout.LayoutParams(LinearLayout.LayoutParams.WRAP_CONTENT, LinearLayout.LayoutParams.WRAP_CONTENT).apply { topMargin = MetroTheme.dpInt(16f) }
        )

        if (device.torchAvailable) {
            addView(MetroTextView(context, MetroRole.GROUP_HEADER).apply {
                text = "flashlight"
            }, LinearLayout.LayoutParams(LinearLayout.LayoutParams.WRAP_CONTENT, LinearLayout.LayoutParams.WRAP_CONTENT).apply { topMargin = MetroTheme.dpInt(16f) })
            addView(
                MetroToggle(context, device.torchOn) { device.torchOn = it },
                LinearLayout.LayoutParams(LinearLayout.LayoutParams.WRAP_CONTENT, LinearLayout.LayoutParams.WRAP_CONTENT)
            )
        }
    }

    private fun brightnessPage(context: Context): View = scaffold(context, "brightness") {
        addView(MetroTextView(context, MetroRole.SMALL).apply {
            text = "This one is real — drag it and the screen changes with it."
        }, LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT))

        addView(
            MetroSlider(context, "screen brightness", 0.05f, 1f, device.brightness, { String.format("%.0f%%", it * 100) }) {
                device.setBrightness(it)
            },
            LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT).apply { topMargin = MetroTheme.dpInt(12f) }
        )
    }

    private fun batteryPage(context: Context): View = scaffold(context, "battery saver") {
        if (device.batteryLevel < 0) {
            addView(MetroTextView(context, MetroRole.SMALL).apply {
                text = "Battery level not available yet."
            }, LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT))
        } else {
            addView(MetroTextView(context, MetroRole.PAGE_TITLE).apply {
                text = "${device.batteryLevel}%"
            }, LinearLayout.LayoutParams(LinearLayout.LayoutParams.WRAP_CONTENT, LinearLayout.LayoutParams.WRAP_CONTENT))
            addView(MetroTextView(context, MetroRole.SMALL).apply {
                text = device.batteryStateDescription
            }, LinearLayout.LayoutParams(LinearLayout.LayoutParams.WRAP_CONTENT, LinearLayout.LayoutParams.WRAP_CONTENT))
        }
    }

    private fun placeholderPage(context: Context): View {
        val item = MetroSettingsData.item(key)
        return scaffold(context, item?.title ?: key) {
            addView(MetroTextView(context, MetroRole.NORMAL).apply {
                text = item?.subtitle ?: ""
            }, LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT))
            addView(MetroTextView(context, MetroRole.SMALL).apply {
                text = "WP put a real control here, backed by a system radio (WiFi/Bluetooth/cellular) or a permission this kit has no access to. The toggle below is cosmetic — it remembers its state for this session and nothing else."
                setPadding(0, MetroTheme.dpInt(8f), 0, MetroTheme.dpInt(16f))
            }, LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT))
            var cosmetic = false
            addView(
                MetroToggle(context, cosmetic) { cosmetic = it },
                LinearLayout.LayoutParams(LinearLayout.LayoutParams.WRAP_CONTENT, LinearLayout.LayoutParams.WRAP_CONTENT)
            )
        }
    }
}
