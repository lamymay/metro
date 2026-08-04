package com.rakukura.metrolab.music

import android.content.Context
import android.graphics.Canvas
import android.graphics.LinearGradient
import android.graphics.Paint
import android.graphics.RadialGradient
import android.graphics.Shader
import android.view.View
import com.rakukura.metrolab.theme.MetroAccent
import com.rakukura.metrolab.theme.MetroTheme

/**
 * A stand-in for album art / photo thumbnails: an accent gradient plus a couple of
 * soft translucent circles for texture, since the kit ships no images. Used by the
 * music player, the Photos hub, and the Start screen's "personal photo" tile face.
 */
class MetroAlbumArtView(context: Context, var accent: MetroAccent) : View(context) {

    private val paint = Paint(Paint.ANTI_ALIAS_FLAG)

    override fun onDraw(canvas: Canvas) {
        val w = width.toFloat()
        val h = height.toFloat()
        if (w <= 0f || h <= 0f) return

        paint.shader = LinearGradient(
            0f, 0f, w, h,
            intArrayOf(accent.color, MetroTheme.withAlpha(accent.color, 0.45f), MetroTheme.withAlpha(0x000000, 0.65f)),
            null, Shader.TileMode.CLAMP
        )
        canvas.drawRect(0f, 0f, w, h, paint)

        paint.shader = RadialGradient(
            w * 0.85f, h * 0.05f, w * 0.5f,
            intArrayOf(MetroTheme.withAlpha(0xFFFFFF, 0.14f), MetroTheme.withAlpha(0xFFFFFF, 0f)),
            null, Shader.TileMode.CLAMP
        )
        canvas.drawRect(0f, 0f, w, h, paint)
        paint.shader = null
    }
}
