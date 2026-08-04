package com.rakukura.metrolab.theme

import android.content.Context
import android.graphics.Color
import android.graphics.Typeface

/**
 * The twenty stock Windows Phone 8 accents, at their shipping hex values. WP only ever
 * tinted with a flat accent — no gradients, no tints of a tint.
 */
enum class MetroAccent(val displayName: String, val color: Int) {
    LIME("Lime", 0xFFA4C400.toInt()),
    GREEN("Green", 0xFF60A917.toInt()),
    EMERALD("Emerald", 0xFF008A00.toInt()),
    TEAL("Teal", 0xFF00ABA9.toInt()),
    CYAN("Cyan", 0xFF1BA1E2.toInt()),
    COBALT("Cobalt", 0xFF0050EF.toInt()),
    INDIGO("Indigo", 0xFF6A00FF.toInt()),
    VIOLET("Violet", 0xFFAA00FF.toInt()),
    PINK("Pink", 0xFFF472D0.toInt()),
    MAGENTA("Magenta", 0xFFD80073.toInt()),
    CRIMSON("Crimson", 0xFFA20025.toInt()),
    RED("Red", 0xFFE51400.toInt()),
    ORANGE("Orange", 0xFFFA6800.toInt()),
    AMBER("Amber", 0xFFF0A30A.toInt()),
    YELLOW("Yellow", 0xFFE3C800.toInt()),
    BROWN("Brown", 0xFF825A2C.toInt()),
    OLIVE("Olive", 0xFF6D8764.toInt()),
    STEEL("Steel", 0xFF647687.toInt()),
    MAUVE("Mauve", 0xFF76608A.toInt()),
    TAUPE("Taupe", 0xFF87794E.toInt());
}

enum class MetroThemeMode { DARK, LIGHT }

/**
 * WP text styles, by their original `PhoneTextXxxStyle` names. Sizes are WVGA pixels;
 * [MetroTheme.typeScale] brings them onto a modern density-independent grid.
 */
enum class MetroRole(val wpSize: Float, val weight: MetroWeight, val subtle: Boolean = false) {
    APPLICATION_TITLE(18.667f, MetroWeight.SEMIBOLD),
    PAGE_TITLE(40f, MetroWeight.SEMILIGHT),
    PIVOT_HEADER(48f, MetroWeight.SEMILIGHT),
    PANORAMA_TITLE(120f, MetroWeight.LIGHT),
    TITLE1(32f, MetroWeight.SEMILIGHT),
    TITLE2(25.333f, MetroWeight.SEMILIGHT),
    TITLE3(22.667f, MetroWeight.SEMILIGHT),
    NORMAL(20f, MetroWeight.NORMAL),
    SUBTLE(20f, MetroWeight.NORMAL, subtle = true),
    SMALL(18.667f, MetroWeight.NORMAL, subtle = true),
    GROUP_HEADER(18.667f, MetroWeight.SEMIBOLD, subtle = true),
    LARGE(32f, MetroWeight.SEMILIGHT),
    EXTRA_LARGE(34.667f, MetroWeight.SEMILIGHT),
    HUGE(186.667f, MetroWeight.LIGHT),
    TILE_BADGE(46f, MetroWeight.LIGHT),
    TILE_TITLE(18.667f, MetroWeight.NORMAL);
}

enum class MetroWeight { LIGHT, SEMILIGHT, NORMAL, SEMIBOLD, BOLD }

/**
 * Global theme state. A lab app has exactly one, and every view repaints from it, so a
 * plain object with change listeners beats threading a theme through constructors.
 */
object MetroTheme {

    private var density = 3f
    private val listeners = ArrayList<() -> Unit>()

    var mode: MetroThemeMode = MetroThemeMode.DARK
        set(value) {
            field = value
            notifyChanged()
        }

    var accent: MetroAccent = MetroAccent.COBALT
        set(value) {
            field = value
            notifyChanged()
        }

    /**
     * WP sizes are WVGA pixels across a 480-unit-wide screen. A modern phone is roughly
     * 360dp wide, so 0.78 lands the type at the same apparent size.
     */
    var typeScale: Float = 0.78f
        set(value) {
            field = value
            notifyChanged()
        }

    fun attach(context: Context) {
        density = context.resources.displayMetrics.density
    }

    fun addListener(listener: () -> Unit) {
        listeners.add(listener)
    }

    fun removeListener(listener: () -> Unit) {
        listeners.remove(listener)
    }

    private fun notifyChanged() {
        // Copy: a listener may detach itself while reacting.
        for (listener in ArrayList(listeners)) listener()
    }

    // ---- Brushes (named after their PhoneXxxBrush originals) ----

    val background: Int get() = if (mode == MetroThemeMode.DARK) Color.BLACK else Color.WHITE
    val foreground: Int get() = if (mode == MetroThemeMode.DARK) Color.WHITE else Color.BLACK
    val accentColor: Int get() = accent.color

    /** PhoneChromeBrush — the app bar fill. */
    val chrome: Int
        get() = if (mode == MetroThemeMode.DARK) 0xFF1F1F1F.toInt() else 0xFFDDDDDD.toInt()

    /** PhoneDisabledBrush. */
    val disabled: Int
        get() = if (mode == MetroThemeMode.DARK) 0xFF666666.toInt() else 0xFFA6A6A6.toInt()

    /** PhoneSubtleBrush — secondary text. */
    val subtle: Int
        get() = if (mode == MetroThemeMode.DARK) 0xFF999999.toInt() else 0xFF666666.toInt()

    /** Fill of a tile the user has not accented. */
    val tileNeutral: Int
        get() = if (mode == MetroThemeMode.DARK) 0xFF1F1F1F.toInt() else 0xFFE6E6E6.toInt()

    /** Text drawn on an accent fill. White in both themes, as WP had it. */
    val onAccent: Int get() = Color.WHITE

    val border: Int get() = withAlpha(foreground, if (mode == MetroThemeMode.DARK) 0.55f else 0.65f)

    // ---- Metrics ----

    fun dp(value: Float): Float = value * density

    fun dpInt(value: Float): Int = (value * density + 0.5f).toInt()

    /** Gap between tiles, and the base unit for most page padding. */
    val tileGap: Float get() = dp(6f)

    /** Small-tile columns on the start screen. WP shipped 4 on WVGA. */
    var tileColumns: Int = 4

    val pageMargin: Float get() = dp(16f)

    val startLeadingMargin: Float get() = dp(6f)

    val appBarHeight: Float get() = dp(60f)

    /** `PhoneBorderThickness` was 3 device pixels at WVGA. */
    val borderWidth: Float get() = dp(1.6f)

    // ---- Type ----

    fun textSize(role: MetroRole): Float = dp(role.wpSize * typeScale)

    fun typeface(weight: MetroWeight): Typeface = when (weight) {
        // "sans-serif-light"/"-thin" landed in API 16, which is exactly our floor.
        MetroWeight.LIGHT -> lightFace
        MetroWeight.SEMILIGHT -> lightFace
        MetroWeight.NORMAL -> Typeface.SANS_SERIF
        MetroWeight.SEMIBOLD -> Typeface.DEFAULT_BOLD
        MetroWeight.BOLD -> Typeface.DEFAULT_BOLD
    }

    private val lightFace: Typeface by lazy {
        Typeface.create("sans-serif-light", Typeface.NORMAL) ?: Typeface.SANS_SERIF
    }

    fun colorFor(role: MetroRole): Int = if (role.subtle) subtle else foreground

    fun withAlpha(color: Int, alpha: Float): Int {
        val a = (255 * alpha.coerceIn(0f, 1f)).toInt()
        return (a shl 24) or (color and 0x00FFFFFF)
    }
}
