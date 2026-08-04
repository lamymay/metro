package com.rakukura.metrolab.settings

import com.rakukura.metrolab.glyph.MetroGlyph

/** One row in the Settings list. [key] decides whether tapping it opens a real control
 * or an honest placeholder. */
data class MetroSettingsItem(
    val key: String,
    val title: String,
    val subtitle: String,
    val glyph: MetroGlyph
)

object MetroSettingsData {
    val system: List<MetroSettingsItem> = listOf(
        MetroSettingsItem("theme", "start+theme", "accent colour, dark/light", MetroGlyph.START),
        MetroSettingsItem("ringtones", "ringtones+sounds", "Nostalgia", MetroGlyph.MUSIC),
        MetroSettingsItem("accounts", "email+accounts", "set up email, contacts and others", MetroGlyph.MAIL),
        MetroSettingsItem("lockscreen", "lock screen", "screen timeout, keep awake", MetroGlyph.CLOCK),
        MetroSettingsItem("brightness", "brightness", "adjusts the real screen", MetroGlyph.SUN),
        MetroSettingsItem("notifications", "notifications+actions", "manage action centre", MetroGlyph.MESSAGE),
        MetroSettingsItem("wifi", "WiFi", "not connected", MetroGlyph.WIFI),
        MetroSettingsItem("flightmode", "flight mode", "off", MetroGlyph.AIRPLANE),
        MetroSettingsItem("bluetooth", "bluetooth", "off", MetroGlyph.BLUETOOTH),
        MetroSettingsItem("cellular", "cellular+SIM", "no SIM", MetroGlyph.PHONE),
        MetroSettingsItem("nfc", "NFC", "off", MetroGlyph.PIN),
        MetroSettingsItem("sharing", "network sharing", "off", MetroGlyph.GLOBE),
        MetroSettingsItem("battery", "battery saver", "reads the real battery", MetroGlyph.HEART)
    )

    val applications: List<MetroSettingsItem> = listOf(
        MetroSettingsItem("app-music", "music+videos", "playback, downloads", MetroGlyph.MUSIC),
        MetroSettingsItem("app-store", "store", "updates, payment", MetroGlyph.STORE),
        MetroSettingsItem("app-maps", "maps", "offline maps", MetroGlyph.GLOBE),
        MetroSettingsItem("app-camera", "camera", "grid lines, shutter sound", MetroGlyph.CAMERA)
    )

    fun item(key: String): MetroSettingsItem? = (system + applications).firstOrNull { it.key == key }
}
