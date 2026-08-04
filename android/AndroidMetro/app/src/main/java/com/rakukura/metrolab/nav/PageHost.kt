package com.rakukura.metrolab.nav

import android.content.Context
import android.view.View
import android.widget.FrameLayout
import com.rakukura.metrolab.motion.MetroEase
import com.rakukura.metrolab.motion.MetroMotion
import com.rakukura.metrolab.theme.MetroTheme

/** One screen. The host owns the view's lifetime, so pages are cheap to recreate. */
interface MetroPage {
    fun createView(context: Context, host: PageHost): View
}

/** The page transitions from `Microsoft.Phone.Controls.Toolkit`. */
enum class MetroTransition(val displayName: String) {
    /** The default. Pages swing about their left edge like a revolving door. */
    TURNSTILE("Turnstile"),
    /** `SlideTransition` — vertical translate with a fade. */
    SLIDE("Slide"),
    /** `SwivelTransition` — tips about the horizontal axis. */
    SWIVEL("Swivel"),
    /**
     * An approximation of `ContinuumTransition`, which handed the tapped list item off
     * to the next page's title. Without a shared element this reduces to a rise + scale.
     */
    CONTINUUM("Continuum"),
    NONE("None")
}

/**
 * A back stack with WP page transitions.
 *
 * WP ran the outgoing storyboard, waited for it, then ran the incoming one — so this
 * chains two animations rather than cross-fading, which is what stops it looking like
 * an Android activity transition.
 */
class PageHost(context: Context) : FrameLayout(context) {

    private val stack = ArrayList<MetroPage>()
    private var currentView: View? = null
    private var animating = false

    var transition: MetroTransition = MetroTransition.TURNSTILE

    val depth: Int get() = stack.size

    init {
        clipChildren = false
        setBackgroundColor(MetroTheme.background)
    }

    fun setRoot(page: MetroPage) {
        stack.clear()
        stack.add(page)
        currentView?.let { removeView(it) }
        currentView = null
        showImmediate(page)
    }

    fun push(page: MetroPage) {
        if (animating) return
        val outgoing = currentView
        stack.add(page)
        navigate(outgoing, page, forward = true)
    }

    /** @return false when there is nothing left to pop, so the Activity can finish. */
    fun pop(): Boolean {
        if (animating) return true
        if (stack.size <= 1) return false
        val outgoing = currentView
        stack.removeAt(stack.size - 1)
        navigate(outgoing, stack.last(), forward = false)
        return true
    }

    /** Replaces the whole stack — used by the app bar menu, which jumps sideways. */
    fun replaceAll(page: MetroPage) {
        if (animating) return
        val outgoing = currentView
        stack.clear()
        stack.add(page)
        navigate(outgoing, page, forward = true)
    }

    /**
     * Rebuilds the current page in place. Widgets cache their colours at construction,
     * so a theme change has to go through here rather than just invalidating.
     */
    fun refresh() {
        if (animating) return
        val page = stack.lastOrNull() ?: return
        currentView?.let { removeView(it) }
        currentView = null
        setBackgroundColor(MetroTheme.background)
        showImmediate(page)
    }

    private fun showImmediate(page: MetroPage) {
        val view = page.createView(context, this)
        addView(view, LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT))
        currentView = view
    }

    private fun navigate(outgoing: View?, page: MetroPage, forward: Boolean) {
        if (outgoing == null || transition == MetroTransition.NONE) {
            outgoing?.let { removeView(it) }
            showImmediate(page)
            return
        }

        animating = true
        val outDuration = MetroMotion.duration(MetroMotion.turnstileOutDuration)
        val inDuration = MetroMotion.duration(MetroMotion.turnstileInDuration)

        prepareForExit(outgoing)
        val exit = outgoing.animate().setDuration(outDuration).setInterpolator(MetroEase.wpOut)
        applyExit(exit, forward)
        exit.withEndAction {
            removeView(outgoing)
            val incoming = page.createView(context, this)
            addView(incoming, LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT))
            currentView = incoming

            prepareForEntry(incoming, forward)
            val enter = incoming.animate().setDuration(inDuration).setInterpolator(MetroEase.wpIn)
            applyEntry(enter)
            enter.withEndAction { animating = false }.start()
        }.start()
    }

    private fun cameraFor(view: View) =
        MetroMotion.tiltCameraDistance * maxOf(view.width, view.height).toFloat().coerceAtLeast(1f)

    private fun prepareForExit(view: View) {
        view.cameraDistance = cameraFor(view)
        when (transition) {
            MetroTransition.TURNSTILE -> {
                view.pivotX = 0f
                view.pivotY = view.height / 2f
            }
            else -> {
                view.pivotX = view.width / 2f
                view.pivotY = if (transition == MetroTransition.CONTINUUM) 0f else view.height / 2f
            }
        }
    }

    private fun applyExit(anim: android.view.ViewPropertyAnimator, forward: Boolean) {
        when (transition) {
            MetroTransition.TURNSTILE -> {
                val angle = if (forward) MetroMotion.turnstileForwardOutAngle
                else MetroMotion.turnstileBackwardOutAngle
                anim.rotationY(angle).alpha(0f)
            }
            MetroTransition.SLIDE ->
                anim.translationY(if (forward) -MetroTheme.dp(120f) else MetroTheme.dp(120f)).alpha(0f)
            MetroTransition.SWIVEL ->
                anim.rotationX(if (forward) 45f else -45f).alpha(0f)
            MetroTransition.CONTINUUM ->
                anim.scaleX(0.88f).scaleY(0.88f).translationY(-MetroTheme.dp(40f)).alpha(0f)
            MetroTransition.NONE -> anim.alpha(0f)
        }
    }

    private fun prepareForEntry(view: View, forward: Boolean) {
        view.cameraDistance = cameraFor(view)
        // The incoming page is present from frame one; only the transform animates. A
        // cross-fade here is the classic tell that a Metro replica is not one.
        view.alpha = 1f
        when (transition) {
            MetroTransition.TURNSTILE -> {
                view.pivotX = 0f
                view.pivotY = view.height / 2f
                view.rotationY = if (forward) MetroMotion.turnstileForwardInAngle
                else MetroMotion.turnstileBackwardInAngle
            }
            MetroTransition.SLIDE ->
                view.translationY = if (forward) MetroTheme.dp(150f) else -MetroTheme.dp(150f)
            MetroTransition.SWIVEL -> {
                view.pivotX = view.width / 2f
                view.pivotY = view.height / 2f
                view.rotationX = if (forward) -30f else 30f
            }
            MetroTransition.CONTINUUM -> {
                view.pivotX = view.width / 2f
                view.pivotY = view.height.toFloat()
                view.scaleX = 0.88f
                view.scaleY = 0.88f
                view.translationY = MetroTheme.dp(60f)
            }
            MetroTransition.NONE -> Unit
        }
    }

    private fun applyEntry(anim: android.view.ViewPropertyAnimator) {
        when (transition) {
            MetroTransition.TURNSTILE -> anim.rotationY(0f)
            MetroTransition.SLIDE -> anim.translationY(0f)
            MetroTransition.SWIVEL -> anim.rotationX(0f)
            MetroTransition.CONTINUUM -> anim.scaleX(1f).scaleY(1f).translationY(0f)
            MetroTransition.NONE -> anim.alpha(1f)
        }
    }
}
