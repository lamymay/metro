package com.rakukura.metrolab.motion

import android.view.View
import android.view.ViewGroup

/**
 * The turnstile-feather entrance: each element swings in about its own left edge,
 * staggered by a fixed step down the reading order.
 *
 * WP applied this to start-screen tiles, list rows and pivot content. It is what makes a
 * Metro screen "unroll" instead of sliding in as a slab, and the 50 ms step is the whole
 * reason it reads as one gesture rather than as N separate animations.
 */
object MetroFeather {

    fun apply(view: View, order: Int, backward: Boolean = false) {
        val angle = if (backward) MetroMotion.turnstileBackwardInAngle
        else MetroMotion.turnstileForwardInAngle

        view.animate().cancel()
        view.pivotX = 0f
        view.pivotY = view.height / 2f
        view.cameraDistance = MetroMotion.tiltCameraDistance *
            maxOf(view.width, view.height).toFloat().coerceAtLeast(1f)
        view.rotationY = angle
        // WP ramped opacity over 0.001s at the start of the storyboard — the element is
        // simply present, it does not fade. A cross-fade here reads as iOS, not Metro.
        view.alpha = 0f

        view.animate()
            .rotationY(0f)
            .setDuration(MetroMotion.duration(MetroMotion.turnstileInDuration))
            .setStartDelay(MetroMotion.featherDelayFor(order))
            .setInterpolator(MetroEase.wpIn)
            .withStartAction { view.alpha = 1f }
            .start()
    }

    /** Feathers every direct child of [group] in index order. */
    fun applyToChildren(group: ViewGroup, backward: Boolean = false) {
        for (i in 0 until group.childCount) apply(group.getChildAt(i), i, backward)
    }

    /** Drops any pending entrance and leaves the view in its settled state. */
    fun settle(view: View) {
        view.animate().cancel()
        view.rotationY = 0f
        view.alpha = 1f
    }
}
