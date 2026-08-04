package com.rakukura.metrolab.motion

import android.animation.ValueAnimator
import android.view.MotionEvent
import android.view.View
import kotlin.math.abs
import kotlin.math.min

/**
 * The signature Windows Phone press interaction: the view tips in 3D *toward the
 * finger*, and recedes if you press it dead centre.
 *
 * A port of `Microsoft.Phone.Controls.TiltEffect`. The original normalises the touch
 * point into -0.5…0.5, sums the two magnitudes to get a total angle, then splits that
 * angle between the two rotations in proportion to how far off-axis the touch was. A
 * corner press hits the full `MaxAngle` and tips on both axes; an edge-centre press tips
 * on one; a dead-centre press does not tip at all and only depresses.
 *
 * Attach with [attach] and the host view needs no touch code of its own.
 */
class TiltController(
    private val view: View,
    private var onClick: (() -> Unit)? = null
) {

    private var pressed = false
    private var animator: ValueAnimator? = null

    /** Where the finger is, normalised to -0.5…0.5 with the origin at the centre. */
    private var normX = 0f
    private var normY = 0f

    var enabled: Boolean = true

    fun setOnClick(listener: (() -> Unit)?) {
        onClick = listener
    }

    fun attach() {
        // Route the tap through performClick() rather than firing the lambda directly:
        // that keeps TalkBack, click sounds and lint's ClickableViewAccessibility happy.
        view.setOnClickListener { onClick?.invoke() }
        view.setOnTouchListener { _, event -> onTouchEvent(event) }
    }

    fun onTouchEvent(event: MotionEvent): Boolean {
        if (!enabled) return false
        val w = view.width.toFloat()
        val h = view.height.toFloat()
        if (w <= 0f || h <= 0f) return false

        when (event.actionMasked) {
            MotionEvent.ACTION_DOWN -> {
                pressed = true
                view.parent?.requestDisallowInterceptTouchEvent(false)
                setNormalised(event.x / w - 0.5f, event.y / h - 0.5f)
                animateTo(1f, MetroMotion.duration(MetroMotion.tiltPressDuration))
                return true
            }

            MotionEvent.ACTION_MOVE -> {
                if (!pressed) return false
                if (!contains(event.x, event.y, w, h)) {
                    // Dragging off the element cancels the press, exactly as WP did.
                    release(false)
                    return true
                }
                setNormalised(event.x / w - 0.5f, event.y / h - 0.5f)
                // Already tilted; track the finger directly rather than re-animating.
                if (animator == null) applyTilt(1f)
                return true
            }

            MotionEvent.ACTION_UP -> {
                val inside = pressed && contains(event.x, event.y, w, h)
                release(inside)
                return true
            }

            MotionEvent.ACTION_CANCEL -> {
                release(false)
                return true
            }
        }
        return false
    }

    private fun contains(x: Float, y: Float, w: Float, h: Float) =
        x >= 0f && y >= 0f && x <= w && y <= h

    private fun setNormalised(x: Float, y: Float) {
        normX = x.coerceIn(-0.5f, 0.5f)
        normY = y.coerceIn(-0.5f, 0.5f)
    }

    private fun release(fireClick: Boolean) {
        pressed = false
        animateTo(0f, MetroMotion.duration(MetroMotion.tiltReleaseDuration))
        if (fireClick) view.performClick()
    }

    private fun animateTo(target: Float, duration: Long) {
        animator?.cancel()
        val start = currentAmount
        val anim = ValueAnimator.ofFloat(start, target)
        anim.duration = duration
        anim.interpolator = MetroEase.wpIn
        anim.addUpdateListener { applyTilt(it.animatedValue as Float) }
        anim.addListener(object : android.animation.AnimatorListenerAdapter() {
            override fun onAnimationEnd(animation: android.animation.Animator) {
                animator = null
                currentAmount = target
            }
        })
        animator = anim
        anim.start()
    }

    private var currentAmount = 0f

    private fun applyTilt(amount: Float) {
        currentAmount = amount

        val magnitude = min(abs(normX) + abs(normY), 1f)
        val xShare = if (abs(normX) + abs(normY) > 0f) abs(normX) / (abs(normX) + abs(normY)) else 0f
        val degrees = magnitude * MetroMotion.tiltMaxAngle * 180f / Math.PI.toFloat() * amount

        // Android's rotationY matches SwiftUI's — positive pushes the right edge away.
        view.rotationY = degrees * xShare * if (normX < 0f) -1f else 1f
        // rotationX does *not*: Android documents it as clockwise looking down +x, which
        // sends the bottom edge away for positive values. SwiftUI needs a negative value
        // for the same motion, so this is the one sign that differs between the two apps.
        view.rotationX = degrees * (1f - xShare) * if (normY < 0f) -1f else 1f

        val depression = 1f - MetroMotion.tiltMaxDepression * (1f - magnitude) * amount
        view.scaleX = depression
        view.scaleY = depression

        view.cameraDistance = MetroMotion.tiltCameraDistance *
            maxOf(view.width, view.height).toFloat().coerceAtLeast(1f)
    }
}
