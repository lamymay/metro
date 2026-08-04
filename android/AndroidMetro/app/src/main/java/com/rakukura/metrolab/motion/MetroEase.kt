package com.rakukura.metrolab.motion

import android.view.animation.Interpolator
import kotlin.math.PI
import kotlin.math.abs
import kotlin.math.exp
import kotlin.math.pow
import kotlin.math.sin
import kotlin.math.sqrt

enum class MetroEaseMode { EASE_IN, EASE_OUT, EASE_IN_OUT }

/**
 * Windows Phone's easing functions, ported from the Silverlight easing classes that the
 * WP toolkit's storyboards referenced by name.
 *
 * Unlike the SwiftUI side, Android takes an arbitrary [Interpolator], so this is the
 * exact function everywhere — no bezier fitting.
 *
 * The important one is [wpIn]: `ExponentialEase { EasingMode = EaseOut, Exponent = 6 }`,
 * which is what `TurnstileTransition`, `SlideTransition` and most WP page animations used.
 */
class MetroEase(
    private val kind: Kind,
    private val mode: MetroEaseMode
) : Interpolator {

    sealed class Kind {
        object Linear : Kind()
        data class Exponential(val exponent: Float) : Kind()
        data class Power(val exponent: Float) : Kind()
        object Circle : Kind()
        data class Back(val amplitude: Float) : Kind()
        object Sine : Kind()
    }

    override fun getInterpolation(input: Float): Float = progress(input)

    fun progress(t: Float): Float {
        val clamped = t.coerceIn(0f, 1f)
        return when (mode) {
            MetroEaseMode.EASE_IN -> easeIn(clamped)
            MetroEaseMode.EASE_OUT -> 1f - easeIn(1f - clamped)
            MetroEaseMode.EASE_IN_OUT ->
                if (clamped < 0.5f) easeIn(clamped * 2f) / 2f
                else 1f - easeIn((1f - clamped) * 2f) / 2f
        }
    }

    /**
     * The `EaseIn` form. The other two modes are derived from it exactly the way
     * Silverlight's `EasingFunctionBase` derived them.
     */
    private fun easeIn(t: Float): Float = when (kind) {
        is Kind.Linear -> t
        is Kind.Exponential -> {
            val e = kind.exponent
            if (abs(e) < 1e-6f) t
            else ((exp(e * t) - 1f) / (exp(e) - 1f))
        }
        is Kind.Power -> t.pow(kind.exponent.coerceAtLeast(0f))
        is Kind.Circle -> 1f - sqrt(1f - t * t)
        is Kind.Back -> t.pow(3) - t * kind.amplitude.coerceAtLeast(0f) * sin(PI.toFloat() * t)
        is Kind.Sine -> 1f - sin(PI.toFloat() / 2f * (1f - t))
    }

    val displayName: String
        get() {
            val base = when (kind) {
                is Kind.Linear -> return "Linear"
                is Kind.Exponential -> "Exponential ${kind.exponent.toInt()}"
                is Kind.Power -> "Power ${kind.exponent.toInt()}"
                is Kind.Circle -> "Circle"
                is Kind.Back -> "Back"
                is Kind.Sine -> "Sine"
            }
            val suffix = when (mode) {
                MetroEaseMode.EASE_IN -> "easeIn"
                MetroEaseMode.EASE_OUT -> "easeOut"
                MetroEaseMode.EASE_IN_OUT -> "easeInOut"
            }
            return "$base · $suffix"
        }

    companion object {
        /** The WP "arrive" curve. */
        val wpIn = MetroEase(Kind.Exponential(6f), MetroEaseMode.EASE_OUT)

        /** The WP "leave" curve. */
        val wpOut = MetroEase(Kind.Exponential(6f), MetroEaseMode.EASE_IN)

        val linear = MetroEase(Kind.Linear, MetroEaseMode.EASE_IN_OUT)

        val kinds: List<Kind> = listOf(
            Kind.Exponential(6f),
            Kind.Power(3f),
            Kind.Circle,
            Kind.Back(1f),
            Kind.Sine,
            Kind.Linear
        )
    }
}
