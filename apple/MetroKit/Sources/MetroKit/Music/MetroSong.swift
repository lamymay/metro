import Foundation

/// A track. `frequency` and `duration` drive ``MetroToneSynth`` — there is no audio
/// file, this *is* the song.
public struct MetroSong: Identifiable, Equatable, Sendable {
  public var title: String
  public var artist: String
  public var album: String
  public var accent: MetroAccent
  public var frequency: Double
  public var duration: TimeInterval

  public var id: String { title + artist }

  public init(
    title: String,
    artist: String,
    album: String,
    accent: MetroAccent,
    frequency: Double,
    duration: TimeInterval
  ) {
    self.title = title
    self.artist = artist
    self.album = album
    self.accent = accent
    self.frequency = frequency
    self.duration = duration
  }
}

extension MetroSong {
  /// Artists borrowed from the mail fixtures elsewhere in the lab, so the whole demo
  /// reads as one small consistent world rather than a grab-bag of placeholder names.
  public static let samplePlaylist: [MetroSong] = [
    MetroSong(title: "Dayvan Cowboy", artist: "Boards of Canada", album: "Geogaddi", accent: .crimson, frequency: 261.63, duration: 20),
    MetroSong(title: "Turnstile Blue", artist: "Kaori Mizuki", album: "Metro Sessions", accent: .cobalt, frequency: 293.66, duration: 18),
    MetroSong(title: "Feather Step", artist: "Tomo Sasaki", album: "Cascade", accent: .violet, frequency: 329.63, duration: 22),
    MetroSong(title: "Panorama Drift", artist: "Aya Yamada", album: "Wide Angle", accent: .teal, frequency: 349.23, duration: 19),
    MetroSong(title: "Exponent Six", artist: "Kaori Mizuki", album: "Metro Sessions", accent: .magenta, frequency: 392.00, duration: 21),
  ]
}
