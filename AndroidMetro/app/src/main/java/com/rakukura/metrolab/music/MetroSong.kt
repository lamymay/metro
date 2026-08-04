package com.rakukura.metrolab.music

import com.rakukura.metrolab.theme.MetroAccent

/** A track. [frequency] and [durationSeconds] drive [MetroToneSynth] — there is no
 * audio file, this *is* the song. */
data class MetroSong(
    val title: String,
    val artist: String,
    val album: String,
    val accent: MetroAccent,
    val frequency: Double,
    val durationSeconds: Int
)

object MetroSongs {
    /** Artists borrowed from the mail fixtures elsewhere in the lab, so the whole demo
     * reads as one small consistent world rather than a grab-bag of placeholder names. */
    val samplePlaylist: List<MetroSong> = listOf(
        MetroSong("Dayvan Cowboy", "Boards of Canada", "Geogaddi", MetroAccent.CRIMSON, 261.63, 20),
        MetroSong("Turnstile Blue", "Kaori Mizuki", "Metro Sessions", MetroAccent.COBALT, 293.66, 18),
        MetroSong("Feather Step", "Tomo Sasaki", "Cascade", MetroAccent.VIOLET, 329.63, 22),
        MetroSong("Panorama Drift", "Aya Yamada", "Wide Angle", MetroAccent.TEAL, 349.23, 19),
        MetroSong("Exponent Six", "Kaori Mizuki", "Metro Sessions", MetroAccent.MAGENTA, 392.00, 21)
    )
}
