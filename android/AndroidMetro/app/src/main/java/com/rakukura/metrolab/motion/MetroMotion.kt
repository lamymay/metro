package com.rakukura.metrolab.motion

/**
 * Every timing number in the app, in one place, so the Motion page can drive them all
 * from sliders while the rest of the app is running.
 *
 * Defaults are the shipping Windows Phone values wherever a shipping value exists.
 */
object MetroMotion {

    private val listeners = ArrayList<() -> Unit>()

    fun addListener(listener: () -> Unit) {
        listeners.add(listener)
    }

    fun removeListener(listener: () -> Unit) {
        listeners.remove(listener)
    }

    fun notifyChanged() {
        for (listener in ArrayList(listeners)) listener()
    }

    // ---- Global ----

    /** Playback multiplier. 0.25 is the quarter-speed view for checking feathering. */
    var speed: Float = 1f

    // ---- Tilt (Microsoft.Phone.Controls.TiltEffect) ----

    /** `TiltEffect.MaxAngle` — 0.3 rad ≈ 17.2°. */
    var tiltMaxAngle: Float = 0.3f

    /**
     * Apparent shrink on a dead-centre press. WP expressed this as
     * `TiltEffect.MaxDepression = 0.2` in PlaneProjection Z-units against a fixed
     * camera; on a tile that lands near a 6% recede. A corner press gets none — the
     * tip is doing the work.
     */
    var tiltMaxDepression: Float = 0.06f

    /** `View.setCameraDistance` multiplier, in multiples of the view's size. */
    var tiltCameraDistance: Float = 8f

    var tiltPressDuration: Long = 100
    var tiltReleaseDuration: Long = 140

    // ---- Turnstile ----

    var turnstileForwardOutAngle: Float = -80f
    var turnstileForwardInAngle: Float = 80f
    var turnstileBackwardOutAngle: Float = 50f
    var turnstileBackwardInAngle: Float = -50f
    var turnstileInDuration: Long = 350
    var turnstileOutDuration: Long = 250

    // ---- Feathering ----
    //
    // WP staggered list rows and tiles rather than moving them as a block. The 50 ms
    // step is what makes a Metro screen "unroll" instead of "slide".

    var featherDelay: Long = 50
    var featherMaxSteps: Int = 12

    // ---- Live tiles ----

    var tileFlipDuration: Long = 500
    var tileSlideDuration: Long = 450
    var tileDwell: Long = 4000

    /** Jitter added per tile so a wall of tiles never beats in lockstep. */
    var tileDwellJitter: Long = 1000

    /** Master switch for the self-starting animations. */
    var liveTilesEnabled: Boolean = true

    // ---- Panorama ----

    var panoramaParallax: Float = 0.32f
    var panoramaTitleParallax: Float = 0.62f
    var panoramaSnapDuration: Long = 400

    // ---- Pivot ----

    var pivotHeaderDuration: Long = 250
    var pivotContentDuration: Long = 300

    /** The pivot's content lags its header. That offset is the whole trick. */
    var pivotContentDelay: Long = 80

    // ---- Progress ----

    var progressDotPeriod: Long = 2400

    // ---- Helpers ----

    fun duration(base: Long): Long = (base / speed.coerceAtLeast(0.01f)).toLong()

    fun featherDelayFor(index: Int): Long =
        duration(featherDelay * minOf(index, featherMaxSteps).toLong())

    fun reset() {
        speed = 1f
        tiltMaxAngle = 0.3f
        tiltMaxDepression = 0.06f
        tiltCameraDistance = 8f
        tiltPressDuration = 100
        tiltReleaseDuration = 140
        turnstileForwardOutAngle = -80f
        turnstileForwardInAngle = 80f
        turnstileBackwardOutAngle = 50f
        turnstileBackwardInAngle = -50f
        turnstileInDuration = 350
        turnstileOutDuration = 250
        featherDelay = 50
        featherMaxSteps = 12
        tileFlipDuration = 500
        tileSlideDuration = 450
        tileDwell = 4000
        tileDwellJitter = 1000
        liveTilesEnabled = true
        panoramaParallax = 0.32f
        panoramaTitleParallax = 0.62f
        panoramaSnapDuration = 400
        pivotHeaderDuration = 250
        pivotContentDuration = 300
        pivotContentDelay = 80
        progressDotPeriod = 2400
        notifyChanged()
    }
}
