package com.rakukura.metrolab.music

import android.content.Context
import java.io.File
import java.io.RandomAccessFile
import kotlin.math.PI
import kotlin.math.max
import kotlin.math.min
import kotlin.math.sin

/**
 * Synthesises short mono WAV clips to a cache file.
 *
 * The music player needs something to actually play — a redistributable app can't
 * bundle licensed songs — so each "track" is a generated chime instead of an mp3.
 * `MediaPlayer` needs a file path or content Uri (no in-memory byte-array API the way
 * iOS's `AVAudioPlayer(data:)` has), so this writes straight to `context.cacheDir` and
 * hands back the path; callers can `File(path).delete()` whenever, it's just a cache.
 */
object MetroToneSynth {

    private const val SAMPLE_RATE = 44_100

    fun writeWav(context: Context, song: MetroSong): String {
        val file = File(context.cacheDir, "metrotone-${song.title.hashCode()}.wav")
        if (file.exists()) return file.absolutePath

        val frameCount = (song.durationSeconds * SAMPLE_RATE)
        val attack = 0.06 * SAMPLE_RATE
        val release = 0.35 * SAMPLE_RATE
        val dataSize = frameCount * 2

        RandomAccessFile(file, "rw").use { raf ->
            writeHeader(raf, frameCount, SAMPLE_RATE)
            val buffer = ByteArray(frameCount * 2)
            for (i in 0 until frameCount) {
                val t = i.toDouble() / SAMPLE_RATE
                var amplitude = 0.22 * sin(2 * PI * song.frequency * t)
                amplitude += 0.08 * sin(2 * PI * song.frequency * 2 * t)
                amplitude += 0.05 * sin(2 * PI * song.frequency * 1.5 * t)

                var envelope = 1.0
                if (i < attack) envelope = i / attack
                val remaining = (frameCount - i).toDouble()
                if (remaining < release) envelope = min(envelope, remaining / release)

                val clamped = max(-1.0, min(1.0, amplitude * envelope))
                val sample = (clamped * Short.MAX_VALUE).toInt().toShort()
                buffer[i * 2] = (sample.toInt() and 0xFF).toByte()
                buffer[i * 2 + 1] = ((sample.toInt() shr 8) and 0xFF).toByte()
            }
            raf.write(buffer)
        }
        return file.absolutePath
    }

    private fun writeHeader(raf: RandomAccessFile, frameCount: Int, sampleRate: Int) {
        val byteRate = sampleRate * 2
        val dataSize = frameCount * 2

        fun le32(v: Int) = byteArrayOf(
            (v and 0xFF).toByte(), ((v shr 8) and 0xFF).toByte(),
            ((v shr 16) and 0xFF).toByte(), ((v shr 24) and 0xFF).toByte()
        )
        fun le16(v: Int) = byteArrayOf((v and 0xFF).toByte(), ((v shr 8) and 0xFF).toByte())

        raf.write("RIFF".toByteArray(Charsets.US_ASCII))
        raf.write(le32(36 + dataSize))
        raf.write("WAVE".toByteArray(Charsets.US_ASCII))
        raf.write("fmt ".toByteArray(Charsets.US_ASCII))
        raf.write(le32(16))
        raf.write(le16(1)) // PCM
        raf.write(le16(1)) // mono
        raf.write(le32(sampleRate))
        raf.write(le32(byteRate))
        raf.write(le16(2)) // block align
        raf.write(le16(16)) // bits per sample
        raf.write("data".toByteArray(Charsets.US_ASCII))
        raf.write(le32(dataSize))
    }
}
