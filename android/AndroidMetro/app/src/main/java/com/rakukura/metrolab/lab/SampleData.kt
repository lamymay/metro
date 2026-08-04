package com.rakukura.metrolab.lab

import com.rakukura.metrolab.glyph.MetroGlyph
import com.rakukura.metrolab.theme.MetroAccent
import com.rakukura.metrolab.tile.TileBehaviour
import com.rakukura.metrolab.tile.TileFace
import com.rakukura.metrolab.tile.TileModel
import com.rakukura.metrolab.tile.TileSize
import com.rakukura.metrolab.tile.TileStyle

/** Fixture content. Deliberately identical to the iOS project's, so the two compare. */
object SampleData {

    /** A denser, more varied start screen — closer to how an actual, well-used Lumia
     * looked than the sparse first pass was. Real phones don't have four empty rows. */
    val startTiles: List<TileModel> = listOf(
        TileModel(
            id = "phone", title = "phone", glyph = MetroGlyph.PHONE, accent = MetroAccent.EMERALD,
            size = TileSize.MEDIUM, badge = 2, behaviour = TileBehaviour.FLIP,
            faces = listOf(TileFace.Iconic, TileFace.Counter(2, "missed calls"))
        ),
        TileModel(
            id = "messaging", title = "messaging", glyph = MetroGlyph.MESSAGE,
            size = TileSize.MEDIUM, badge = 7, behaviour = TileBehaviour.FLIP,
            faces = listOf(
                TileFace.Iconic,
                TileFace.Message("Kaori", "見た？ タイルの動きが完全に WP なんだけど")
            )
        ),
        TileModel("search", "search", MetroGlyph.SEARCH, MetroAccent.STEEL, size = TileSize.SMALL),
        TileModel("store", "store", MetroGlyph.STORE, MetroAccent.MAGENTA, size = TileSize.SMALL),
        TileModel("settings", "settings", MetroGlyph.SETTINGS, style = TileStyle.NEUTRAL, size = TileSize.SMALL),
        TileModel("camera", "camera", MetroGlyph.CAMERA, MetroAccent.TAUPE, size = TileSize.SMALL),
        TileModel(
            id = "people", title = "people", glyph = MetroGlyph.PEOPLE, accent = MetroAccent.VIOLET,
            size = TileSize.WIDE, behaviour = TileBehaviour.SLIDE,
            faces = listOf(
                TileFace.Iconic, TileFace.Initials("KM"),
                TileFace.Initials("TS"), TileFace.Initials("AY")
            )
        ),
        TileModel(
            id = "mail", title = "outlook", glyph = MetroGlyph.MAIL, accent = MetroAccent.COBALT,
            size = TileSize.MEDIUM, badge = 14, behaviour = TileBehaviour.FLIP,
            faces = listOf(
                TileFace.Iconic,
                TileFace.Message("build@ci", "MetroLab — assembleDebug green"),
                TileFace.Counter(14, "unread")
            )
        ),
        TileModel(
            id = "photo-memories", title = "photos", glyph = MetroGlyph.PHOTO, accent = MetroAccent.AMBER,
            size = TileSize.MEDIUM, behaviour = TileBehaviour.SLIDE,
            faces = listOf(TileFace.Photo, TileFace.Photo, TileFace.Photo)
        ),
        TileModel(
            id = "calendar", title = "calendar", glyph = MetroGlyph.CALENDAR, accent = MetroAccent.ORANGE,
            size = TileSize.MEDIUM, behaviour = TileBehaviour.SLIDE,
            faces = listOf(TileFace.Iconic, TileFace.Headline("14:30 Design review"))
        ),
        TileModel(
            id = "music", title = "music", glyph = MetroGlyph.MUSIC, accent = MetroAccent.CRIMSON,
            size = TileSize.WIDE, behaviour = TileBehaviour.FLIP,
            faces = listOf(TileFace.Iconic, TileFace.Headline("Boards of Canada — Dayvan Cowboy"))
        ),
        TileModel("weather", "weather", MetroGlyph.SUN, MetroAccent.AMBER, size = TileSize.SMALL),
        TileModel("clock", "alarms", MetroGlyph.CLOCK, MetroAccent.INDIGO, size = TileSize.SMALL),
        TileModel("ie", "browser", MetroGlyph.GLOBE, MetroAccent.CYAN, size = TileSize.SMALL),
        TileModel("files", "files", MetroGlyph.FOLDER, style = TileStyle.NEUTRAL, size = TileSize.SMALL),
        TileModel(
            id = "wallet", title = "wallet", glyph = MetroGlyph.STAR, accent = MetroAccent.OLIVE,
            size = TileSize.MEDIUM, behaviour = TileBehaviour.FLIP,
            faces = listOf(TileFace.Iconic, TileFace.Counter(3, "cards"))
        ),
        TileModel("maps", "maps", MetroGlyph.PIN, MetroAccent.RED, size = TileSize.SMALL),
        TileModel("translator", "translator", MetroGlyph.GLOBE, MetroAccent.MAUVE, size = TileSize.SMALL),
        TileModel("health", "health", MetroGlyph.HEART, MetroAccent.PINK, size = TileSize.SMALL),
        TileModel("notes", "notes", MetroGlyph.FOLDER, MetroAccent.BROWN, size = TileSize.SMALL),
        TileModel(
            id = "podcasts", title = "podcasts", glyph = MetroGlyph.MUSIC, accent = MetroAccent.TEAL,
            size = TileSize.MEDIUM, behaviour = TileBehaviour.SLIDE,
            faces = listOf(TileFace.Iconic, TileFace.Headline("New: Turnstile Timing, ep. 12"))
        ),
        TileModel("xbox", "xbox", MetroGlyph.STAR, MetroAccent.EMERALD, size = TileSize.SMALL),
        TileModel("voice-recorder", "voice recorder", MetroGlyph.MUSIC, style = TileStyle.NEUTRAL, size = TileSize.SMALL)
    )

    /** Ordinary "installed apps" — tapping any of these opens a generic mail-style
     * placeholder page, same as a real phone's rarely-used apps would show you nothing
     * interesting either. */
    val appNames: List<String> = listOf(
        "Alarms", "Amazon", "Battery Saver", "Bing", "Calculator", "Camera",
        "Contacts", "Data Sense", "Documents", "Email", "Facebook", "Files", "FM Radio",
        "Games", "Groove Music", "Health", "Here Drive", "Here Maps", "IE Mobile",
        "Instagram", "Kids Corner", "Lenses", "Lumia Camera", "Maps", "Messaging",
        "Money", "MSN News", "Nokia Care", "Notes", "OneDrive", "OneNote", "Office",
        "Outlook", "People", "Phone", "Podcasts", "Reading List",
        "Skype", "Sport", "Store", "Translator", "Travel", "Twitter", "Video",
        "Voice Recorder", "Wallet", "Weather", "WhatsApp", "Word", "Xbox", "1Password",
        "2Do", "微信", "百度地图"
    )

    /** Every lab/demo screen, listed the way a real installed app would be — this is
     * the only way to reach them once the debug app bar is gone. */
    val labApps: List<Pair<String, String>> = listOf(
        "Motion Lab" to "motion",
        "Tile Playground" to "tiles",
        "Page Transitions" to "transitions",
        "Panorama Demo" to "panorama",
        "Pivot Demo" to "pivot",
        "Controls Demo" to "controls",
        "Type Ramp" to "typography",
        "Accent Picker" to "accent"
    )

    val mailPreviews: List<Triple<String, String, String>> = listOf(
        Triple("Kaori Mizuki", "Re: tile feather timing", "50 ms でいいと思う。100 は遅すぎ"),
        Triple("build@ci", "MetroLab — all green", "app:assembleDebug, 0 warnings"),
        Triple("Tomo Sasaki", "Turnstile exponent", "Exponent 6 の EaseOut で合ってる"),
        Triple("Store Review", "Submission received", "We'll be in touch within 48 hours."),
        Triple("Aya Yamada", "パノラマの背景", "画像なしで grid だけのほうが Metro っぽい"),
        Triple("noreply@github", "3 new pull requests", "wp/apple, wp/android")
    )

    // ---- Calendar ----

    data class MetroEvent(
        val title: String,
        val start: String,
        val end: String,
        val accent: MetroAccent,
        val day: Int
    )

    const val currentMonth = "August"
    const val today = 2

    val events: List<MetroEvent> = listOf(
        MetroEvent("Design review", "14:30", "15:15", MetroAccent.COBALT, 2),
        MetroEvent("1:1 with Tomo", "16:00", "16:30", MetroAccent.VIOLET, 2),
        MetroEvent("Ship wp/android", "09:00", "10:00", MetroAccent.EMERALD, 3),
        MetroEvent("Kaori — motion review", "11:00", "12:00", MetroAccent.CRIMSON, 5),
        MetroEvent("Store submission window", "All day", "", MetroAccent.AMBER, 8),
        MetroEvent("Aya — panorama assets", "13:00", "13:30", MetroAccent.TEAL, 12)
    )

    // ---- Photos ----

    val photoAccents: List<MetroAccent> = listOf(
        MetroAccent.COBALT, MetroAccent.CRIMSON, MetroAccent.TEAL, MetroAccent.AMBER,
        MetroAccent.VIOLET, MetroAccent.EMERALD, MetroAccent.MAGENTA, MetroAccent.STEEL,
        MetroAccent.ORANGE, MetroAccent.INDIGO, MetroAccent.OLIVE, MetroAccent.TAUPE,
        MetroAccent.PINK, MetroAccent.CYAN, MetroAccent.MAUVE, MetroAccent.LIME
    )

    data class Album(val name: String, val count: Int, val accent: MetroAccent)

    val albums: List<Album> = listOf(
        Album("Camera Roll", 16, MetroAccent.COBALT),
        Album("Screenshots", 9, MetroAccent.STEEL),
        Album("wp/android", 6, MetroAccent.CRIMSON),
        Album("Metro Sessions", 4, MetroAccent.VIOLET)
    )
}
