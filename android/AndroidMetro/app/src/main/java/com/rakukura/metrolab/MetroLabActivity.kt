package com.rakukura.metrolab

import android.app.Activity
import android.os.Bundle
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import android.widget.LinearLayout
import com.rakukura.metrolab.calendar.MetroCalendarPage
import com.rakukura.metrolab.lab.AccentPage
import com.rakukura.metrolab.lab.AppListPage
import com.rakukura.metrolab.lab.ControlsPage
import com.rakukura.metrolab.lab.DetailPage
import com.rakukura.metrolab.lab.MotionPage
import com.rakukura.metrolab.lab.PanoramaPage
import com.rakukura.metrolab.lab.PivotPage
import com.rakukura.metrolab.lab.SampleData
import com.rakukura.metrolab.lab.TilePlaygroundPage
import com.rakukura.metrolab.lab.TransitionPage
import com.rakukura.metrolab.lab.TypePage
import com.rakukura.metrolab.lumia.LumiaStartPage
import com.rakukura.metrolab.motion.MetroEase
import com.rakukura.metrolab.motion.MetroMotion
import com.rakukura.metrolab.music.MetroMiniPlayerBar
import com.rakukura.metrolab.music.MetroMusicPage
import com.rakukura.metrolab.music.MetroMusicPlayer
import com.rakukura.metrolab.nav.MetroPage
import com.rakukura.metrolab.nav.PageHost
import com.rakukura.metrolab.photos.MetroPhotosPage
import com.rakukura.metrolab.settings.MetroActionCenter
import com.rakukura.metrolab.settings.MetroDeviceCapabilities
import com.rakukura.metrolab.settings.MetroSettingsDetailPage
import com.rakukura.metrolab.settings.MetroSettingsPage
import com.rakukura.metrolab.system.MetroSystemLauncher
import com.rakukura.metrolab.theme.MetroTheme
import com.rakukura.metrolab.widget.MetroSystemNavBar

/**
 * The whole app. One Activity, one back stack, no fragments — WP navigation is a stack
 * of pages with a hardware back key, and that maps onto exactly this.
 *
 * There is deliberately no persistent "debug" chrome — no theme toggle, no jump menu.
 * A real Windows Phone Start screen carried nothing but tiles and the three system
 * buttons; every lab/demo screen this app ships is reached the same way a real app
 * would be, by pinning it to Start or finding it in the app list.
 */
class MetroLabActivity : Activity() {

    private lateinit var root: FrameLayout
    private lateinit var chrome: LinearLayout
    private lateinit var host: PageHost
    private lateinit var device: MetroDeviceCapabilities
    private lateinit var musicPlayer: MetroMusicPlayer
    private var miniPlayerBar: MetroMiniPlayerBar? = null
    private var actionCenter: MetroActionCenter? = null
    private var actionCenterOpen = false

    private val themeListener: () -> Unit = { rebuildChrome() }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        MetroTheme.attach(this)
        device = MetroDeviceCapabilities(this)
        musicPlayer = MetroMusicPlayer(this)

        root = FrameLayout(this)
        root.setBackgroundColor(MetroTheme.background)

        chrome = LinearLayout(this)
        chrome.orientation = LinearLayout.VERTICAL

        host = PageHost(this)
        chrome.addView(host, LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, 0, 1f))
        host.setRoot(LumiaStartPage { id -> handleLumiaTileTap(id) })

        chrome.addView(
            MetroSystemNavBar(
                this,
                onBack = { if (!host.pop()) finish() },
                onStart = { host.replaceAll(LumiaStartPage { id -> handleLumiaTileTap(id) }) },
                onSearch = { host.push(AppListPage(SampleData.appNames + SampleData.labApps.map { it.first } + listOf("Calendar", "音乐", "music", "player", "照片", "photos", "Settings")) { name -> handleAppListSelect(name) }) }
            ),
            LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT)
        )

        root.addView(chrome, ViewGroup.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT))

        setupPullDownHandle()
        setContentView(root)

        MetroTheme.addListener(themeListener)
        device.startObservingBattery()
        musicPlayer.setListener { updateMiniPlayerBar() }
    }

    override fun onDestroy() {
        MetroTheme.removeListener(themeListener)
        device.stopObservingBattery()
        musicPlayer.release()
        super.onDestroy()
    }

    // ---- Start screen routing ----

    private fun handleTileTap(tile: com.rakukura.metrolab.tile.TileModel) {
        when (tile.id) {
            "phone" -> MetroSystemLauncher.openPhoneDialer(this)
            "mail" -> MetroSystemLauncher.openMailCompose(this)
            "camera" -> presentCamera("Camera")
            "settings" -> host.push(MetroSettingsPageFor())
            "search" -> host.push(AppListPage(SampleData.appNames + SampleData.labApps.map { it.first } + listOf("Calendar", "音乐", "music", "player", "照片", "photos", "Settings")) { name -> handleAppListSelect(name) })
            "calendar" -> host.push(MetroCalendarPage())
            "photo-memories" -> host.push(MetroPhotosPage())
            "music" -> openMusicPlayer()
            else -> host.push(DetailPage(tile.title))
        }
    }

    private fun handleLumiaTileTap(id: String) {
        when (id) {
            "phone" -> MetroSystemLauncher.openPhoneDialer(this)
            "messaging" -> MetroSystemLauncher.openMessaging(this)
            "mail-small", "google-mail", "mail-7" -> MetroSystemLauncher.openMailCompose(this)
            "camera" -> presentCamera("Camera")
            "calendar" -> host.push(MetroCalendarPage())
            "here-drive" -> MetroSystemLauncher.openMaps(this)
            "music" -> openMusicPlayer()
            // Matches iOS: the tile opens the WP-recreation hub; the system gallery is
            // reachable from the app list's separate "photos" entry.
            "photos" -> host.push(MetroPhotosPage())
            // TODO(parity): iOS routes this to the Player module's own UI. Android has
            // no Player equivalent yet — see ANDROID_STATUS.md.
            "player" -> host.push(DetailPage("Player"))
            "games" -> host.push(DetailPage("Games"))
            "twitter" -> host.push(DetailPage("Twitter"))
            "office" -> host.push(DetailPage("Office"))
            "voicemail" -> host.push(DetailPage("Voicemail"))
        }
    }

    private fun presentCamera(fallbackName: String) {
        if (MetroSystemLauncher.cameraAvailable(this)) {
            MetroSystemLauncher.openCamera(this, CAMERA_REQUEST_CODE)
        } else {
            host.push(DetailPage(fallbackName))
        }
    }

    private fun openMusicPlayer() {
        host.push(MetroMusicPage(musicPlayer))
    }

    private fun MetroSettingsPageFor(): MetroPage = MetroSettingsPage { key -> host.push(MetroSettingsDetailPage(key, device)) }

    // ---- App List routing ----

    private fun handleAppListSelect(name: String) {
        val lab = SampleData.labApps.firstOrNull { it.first == name }
        if (lab != null) {
            host.push(routeForLabKey(lab.second))
            return
        }
        when (name) {
            "Calendar" -> host.push(MetroCalendarPage())
            // Three music entries, named the same way as iOS: the WP recreation, the
            // system default player, and (once it exists here) the Player module's UI.
            "音乐", "Music" -> openMusicPlayer()
            "music" -> MetroSystemLauncher.openSystemMusicPlayer(this)
            // TODO(parity): no Player module on Android yet — see ANDROID_STATUS.md.
            "player" -> host.push(DetailPage("Player"))
            "照片", "Photos" -> host.push(MetroPhotosPage())
            "photos" -> MetroSystemLauncher.openPhotos(this)
            "Settings" -> host.push(MetroSettingsPageFor())
            "Phone" -> MetroSystemLauncher.openPhoneDialer(this)
            "Email", "Outlook" -> MetroSystemLauncher.openMailCompose(this)
            "Message", "Messaging" -> MetroSystemLauncher.openMessaging(this)
            "Camera", "Lumia Camera" -> presentCamera(name)
            else -> host.push(DetailPage(name))
        }
    }

    private fun routeForLabKey(key: String): MetroPage = when (key) {
        "motion" -> MotionPage()
        "tiles" -> TilePlaygroundPage()
        "transitions" -> TransitionPage()
        "panorama" -> PanoramaPage()
        "pivot" -> PivotPage()
        "controls" -> ControlsPage()
        "typography" -> TypePage()
        "accent" -> AccentPage()
        else -> DetailPage(key)
    }

    // ---- Mini player ----

    private fun updateMiniPlayerBar() {
        val shouldShow = musicPlayer.isPlaying
        if (shouldShow && miniPlayerBar == null) {
            val bar = MetroMiniPlayerBar(this, musicPlayer) { openMusicPlayer() }
            miniPlayerBar = bar
            val index = chrome.indexOfChild(host).let { it + 1 }
            chrome.addView(bar, index, LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT))
        } else if (!shouldShow && miniPlayerBar != null) {
            chrome.removeView(miniPlayerBar)
            miniPlayerBar = null
        } else {
            miniPlayerBar?.refresh()
        }
    }

    // ---- Action Center ----

    private fun setupPullDownHandle() {
        val pullTab = View(this)
        var startY = 0f
        pullTab.setOnTouchListener { _, event ->
            when (event.actionMasked) {
                MotionEvent.ACTION_DOWN -> {
                    startY = event.y
                    true
                }
                MotionEvent.ACTION_UP -> {
                    if (event.y - startY > MetroTheme.dp(40f)) openActionCenter()
                    true
                }
                else -> false
            }
        }
        root.addView(pullTab, FrameLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, MetroTheme.dpInt(28f), Gravity.TOP))
    }

    private fun openActionCenter() {
        if (actionCenterOpen) return
        actionCenterOpen = true

        val scrim = View(this).apply { setBackgroundColor(MetroTheme.withAlpha(0x000000, 0.001f)) }
        scrim.setOnClickListener { closeActionCenter(scrim) }
        root.addView(scrim, ViewGroup.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT))

        val center = MetroActionCenter(this, device) {
            closeActionCenter(scrim)
            host.push(MetroSettingsPageFor())
        }
        actionCenter = center
        root.addView(center, FrameLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT, Gravity.TOP))

        center.translationY = -MetroTheme.dp(400f)
        center.animate().translationY(0f).setDuration(MetroMotion.duration(300)).setInterpolator(MetroEase.wpIn).start()

        var startY = 0f
        center.setOnTouchListener { _, event ->
            when (event.actionMasked) {
                MotionEvent.ACTION_DOWN -> { startY = event.y; true }
                MotionEvent.ACTION_UP -> {
                    if (startY - event.y > MetroTheme.dp(30f)) closeActionCenter(scrim)
                    true
                }
                else -> false
            }
        }
    }

    private fun closeActionCenter(scrim: View) {
        val center = actionCenter ?: return
        center.animate().translationY(-MetroTheme.dp(400f)).setDuration(MetroMotion.duration(250)).setInterpolator(MetroEase.wpOut)
            .withEndAction {
                root.removeView(center)
                root.removeView(scrim)
                actionCenter = null
                actionCenterOpen = false
            }.start()
    }

    // ---- Theme ----

    /** Widgets cache their colours at construction, so a theme flip rebuilds the chrome. */
    private fun rebuildChrome() {
        root.setBackgroundColor(MetroTheme.background)
        host.refresh()
        miniPlayerBar?.refresh()
    }

    @Suppress("DEPRECATION")
    override fun onBackPressed() {
        // WP's hardware back key walked the page stack and then left the app; the modern
        // predictive-back APIs are all AndroidX, which minSdk 16 rules out.
        if (!host.pop()) super.onBackPressed()
    }

    companion object {
        private const val CAMERA_REQUEST_CODE = 4201
    }
}
