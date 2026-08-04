package com.rakukura.metrolab.tile

import com.rakukura.metrolab.glyph.MetroGlyph
import com.rakukura.metrolab.theme.MetroAccent
import com.rakukura.metrolab.theme.MetroTheme

/** Tile footprints, in small-tile units. WP shipped exactly these three. */
enum class TileSize(val columns: Int, val rows: Int, val displayName: String) {
    /** No room for a caption — WP dropped it rather than shrinking it. */
    SMALL(1, 1, "Small"),
    MEDIUM(2, 2, "Medium"),
    WIDE(4, 2, "Wide");

    val showsTitle: Boolean get() = this != SMALL
}

enum class TileStyle(val displayName: String) {
    /** Solid accent fill — the default, and the one the theme picker repaints. */
    ACCENT("Accent"),
    /** The dark/light neutral fill for tiles the user has not accented. */
    NEUTRAL("Neutral"),
    /** WP 8.1's transparent tiles: glyph and caption only, wallpaper behind. */
    TRANSPARENT("Transparent")
}

/** What a tile does when it is left alone. */
enum class TileBehaviour(val displayName: String) {
    STATIC("Static"),
    /** Turns about its horizontal axis between faces. */
    FLIP("Flip"),
    /** Pushes the next face up from below. */
    SLIDE("Slide")
}

/** One side of a live tile. */
sealed class TileFace {
    /** Glyph plus the tile's caption — the resting face of every WP tile. */
    object Iconic : TileFace()
    data class Glyph(val glyph: MetroGlyph) : TileFace()
    /** A single line of large light text, bled to the tile edge. */
    data class Headline(val text: String) : TileFace()
    /** The mail/messaging template: sender over body. */
    data class Message(val from: String, val body: String) : TileFace()
    /** A number with a caption under it. */
    data class Counter(val value: Int, val caption: String) : TileFace()
    /** The people tile: two letters, oversized. */
    data class Initials(val letters: String) : TileFace()
    /** A "personal photo" tile — WP let you pin an actual photo as a tile face. There is
     * no real photo library here, so this renders the same generated gradient art the
     * Photos hub and music player use for their thumbnails. */
    object Photo : TileFace()
}

data class TileModel(
    val id: String,
    val title: String,
    val glyph: MetroGlyph,
    /** `null` follows the theme accent, which is how most WP tiles behaved. */
    val accent: MetroAccent? = null,
    val style: TileStyle = TileStyle.ACCENT,
    val size: TileSize = TileSize.MEDIUM,
    val badge: Int? = null,
    val behaviour: TileBehaviour = TileBehaviour.STATIC,
    val faces: List<TileFace> = listOf(TileFace.Iconic)
) {
    val fill: Int
        get() = when (style) {
            TileStyle.ACCENT -> (accent ?: MetroTheme.accent).color
            TileStyle.NEUTRAL -> MetroTheme.tileNeutral
            TileStyle.TRANSPARENT -> 0
        }

    val foreground: Int
        get() = if (style == TileStyle.ACCENT) MetroTheme.onAccent else MetroTheme.foreground

    val isLive: Boolean get() = behaviour != TileBehaviour.STATIC && faces.size > 1
}

/** Where one tile ended up, in small-tile units. */
data class TilePlacement(
    val model: TileModel,
    val column: Int,
    val row: Int,
    /** Position in reading order, which is the order the feather uses. */
    val order: Int
)

data class TilePacking(val placements: List<TilePlacement>, val rows: Int)

/**
 * First-fit packer, which is how the WP start screen actually behaved: a tile drops into
 * the first hole big enough for it, scanning left-to-right then down. That is why a wide
 * tile could leave a pair of small holes above it that later small tiles filled.
 */
object TilePacker {

    fun pack(tiles: List<TileModel>, columns: Int): TilePacking {
        if (columns <= 0) return TilePacking(emptyList(), 0)
        val occupied = ArrayList<BooleanArray>()
        val placements = ArrayList<TilePlacement>()

        fun ensureRows(count: Int) {
            while (occupied.size < count) occupied.add(BooleanArray(columns))
        }

        fun fits(row: Int, column: Int, width: Int, height: Int): Boolean {
            if (column + width > columns) return false
            ensureRows(row + height)
            for (r in row until row + height) {
                for (c in column until column + width) if (occupied[r][c]) return false
            }
            return true
        }

        for ((index, tile) in tiles.withIndex()) {
            val w = minOf(tile.size.columns, columns)
            val h = tile.size.rows
            var placed = false
            var row = 0
            while (!placed) {
                ensureRows(row + h)
                var column = 0
                while (column <= columns - w) {
                    if (fits(row, column, w, h)) {
                        for (r in row until row + h) {
                            for (c in column until column + w) occupied[r][c] = true
                        }
                        placements.add(TilePlacement(tile, column, row, index))
                        placed = true
                        break
                    }
                    column++
                }
                if (!placed) row++
            }
        }

        // Renumber into reading order so the feather runs top-left to bottom-right
        // rather than in whatever order the caller happened to supply.
        val sorted = placements.sortedWith(compareBy({ it.row }, { it.column }))
        val orderById = HashMap<String, Int>(sorted.size)
        sorted.forEachIndexed { i, p -> orderById[p.model.id] = i }
        val renumbered = placements.map { it.copy(order = orderById[it.model.id] ?: it.order) }

        var used = 0
        occupied.forEachIndexed { index, row -> if (row.any { it }) used = index + 1 }
        return TilePacking(renumbered, used)
    }
}
