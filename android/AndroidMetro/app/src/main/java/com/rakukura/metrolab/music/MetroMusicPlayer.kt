package com.rakukura.metrolab.music

import android.content.Context
import android.media.MediaPlayer
import android.os.Handler
import android.os.Looper

/**
 * Real transport, real audio — just not a real song. Each track is synthesised on
 * first play by [MetroToneSynth], so play/pause/next/previous/scrub all drive an
 * actual `MediaPlayer` instead of a progress bar animating on its own.
 */
class MetroMusicPlayer(
    private val context: Context,
    val playlist: List<MetroSong> = MetroSongs.samplePlaylist
) {
    var currentIndex: Int = 0
        private set
    var isPlaying: Boolean = false
        private set
    var currentTimeMs: Int = 0
        private set

    private var player: MediaPlayer? = null
    private val handler = Handler(Looper.getMainLooper())
    private var onChanged: (() -> Unit)? = null

    private val tick = object : Runnable {
        override fun run() {
            player?.let { currentTimeMs = it.currentPosition }
            onChanged?.invoke()
            if (isPlaying) handler.postDelayed(this, 200)
        }
    }

    val currentSong: MetroSong get() = playlist[currentIndex]

    /** Called whenever play state / position / track changes, so a UI can redraw. */
    fun setListener(listener: (() -> Unit)?) {
        onChanged = listener
    }

    fun togglePlayPause() {
        if (isPlaying) pause() else play()
    }

    fun play() {
        if (player == null) load(currentIndex)
        player?.start()
        isPlaying = true
        handler.post(tick)
        onChanged?.invoke()
    }

    fun pause() {
        player?.pause()
        isPlaying = false
        handler.removeCallbacks(tick)
        onChanged?.invoke()
    }

    fun next() = advance(1)

    fun previous() {
        // WP's convention: "previous" restarts the current track once you're a few
        // seconds in, and only steps back to the prior track right near the start.
        if (currentTimeMs > 3000) {
            seek(0)
            return
        }
        advance(-1)
    }

    fun seek(ms: Int) {
        currentTimeMs = ms
        player?.seekTo(ms)
        onChanged?.invoke()
    }

    private fun advance(delta: Int) {
        val wasPlaying = isPlaying
        pause()
        player?.release()
        player = null
        currentIndex = ((currentIndex + delta) % playlist.size + playlist.size) % playlist.size
        currentTimeMs = 0
        load(currentIndex)
        if (wasPlaying) play() else onChanged?.invoke()
    }

    private fun load(index: Int) {
        val song = playlist[index]
        val path = MetroToneSynth.writeWav(context, song)
        val mp = MediaPlayer()
        mp.setDataSource(path)
        mp.prepare()
        mp.setOnCompletionListener {
            next()
            play()
        }
        player = mp
    }

    fun release() {
        handler.removeCallbacks(tick)
        player?.release()
        player = null
    }
}
