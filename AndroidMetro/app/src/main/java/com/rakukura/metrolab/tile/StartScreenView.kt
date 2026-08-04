package com.rakukura.metrolab.tile

import android.content.Context
import android.view.View
import android.view.ViewGroup
import com.rakukura.metrolab.motion.MetroFeather
import com.rakukura.metrolab.theme.MetroTheme
import kotlin.math.max

/**
 * The WP start screen: a packed tile grid that swings in on appear.
 *
 * A hand-rolled [ViewGroup] rather than a grid widget, because the packing is first-fit
 * over a two-dimensional occupancy map — no row/column layout can express it.
 */
class StartScreenView(context: Context) : ViewGroup(context) {

    var tiles: List<TileModel> = emptyList()
        set(value) {
            field = value
            rebuild()
        }

    var onSelect: ((TileModel) -> Unit)? = null

    private var packing: TilePacking = TilePacking(emptyList(), 0)
    private var unit: Float = 0f
    private var pendingCascade = true

    init {
        clipChildren = false
        clipToPadding = false
    }

    private fun rebuild() {
        removeAllViews()
        packing = TilePacker.pack(tiles, MetroTheme.tileColumns)
        for (placement in packing.placements) {
            val view = TileView(context)
            view.model = placement.model
            view.onSelect = { model -> onSelect?.invoke(model) }
            addView(view)
        }
        pendingCascade = true
        requestLayout()
    }

    /** Replays the entrance — the "did that stagger feel right?" button. */
    fun replayCascade() {
        pendingCascade = true
        runCascade()
    }

    private fun runCascade() {
        if (!pendingCascade || childCount == 0) return
        pendingCascade = false
        for ((index, placement) in packing.placements.withIndex()) {
            val child = getChildAt(index) ?: continue
            MetroFeather.apply(child, placement.order)
        }
    }

    override fun onMeasure(widthMeasureSpec: Int, heightMeasureSpec: Int) {
        val width = MeasureSpec.getSize(widthMeasureSpec)
        val gap = MetroTheme.tileGap
        val leading = MetroTheme.startLeadingMargin
        val columns = MetroTheme.tileColumns

        val usable = width - leading * 2f - gap * (columns - 1)
        unit = max(MetroTheme.dp(24f), usable / columns)

        for ((index, placement) in packing.placements.withIndex()) {
            val child = getChildAt(index) as? TileView ?: continue
            child.unit = unit
            val w = (unit * placement.model.size.columns + gap * (placement.model.size.columns - 1)).toInt()
            val h = (unit * placement.model.size.rows + gap * (placement.model.size.rows - 1)).toInt()
            child.measure(
                MeasureSpec.makeMeasureSpec(w, MeasureSpec.EXACTLY),
                MeasureSpec.makeMeasureSpec(h, MeasureSpec.EXACTLY)
            )
        }

        val rows = packing.rows
        val height = if (rows == 0) 0 else (rows * unit + (rows - 1) * gap).toInt()
        setMeasuredDimension(width, height)
    }

    override fun onLayout(changed: Boolean, l: Int, t: Int, r: Int, b: Int) {
        val gap = MetroTheme.tileGap
        val leading = MetroTheme.startLeadingMargin
        val step = unit + gap

        for ((index, placement) in packing.placements.withIndex()) {
            val child = getChildAt(index) ?: continue
            val x = (leading + placement.column * step).toInt()
            val y = (placement.row * step).toInt()
            child.layout(x, y, x + child.measuredWidth, y + child.measuredHeight)
        }
        runCascade()
    }

    override fun generateDefaultLayoutParams(): LayoutParams =
        LayoutParams(LayoutParams.WRAP_CONTENT, LayoutParams.WRAP_CONTENT)

    override fun addView(child: View) {
        super.addView(child, generateDefaultLayoutParams())
    }
}
