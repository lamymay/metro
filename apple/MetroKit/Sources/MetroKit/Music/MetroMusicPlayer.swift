import Foundation
import AVFoundation
import Combine

/// Real transport, real audio — just not a real song. Each track is synthesised on
/// first play by ``MetroToneSynth``, so play/pause/next/previous/scrub all drive an
/// actual `AVAudioPlayer` instead of a progress bar animating on its own.
@MainActor
public final class MetroMusicPlayer: NSObject, ObservableObject {
  @Published public private(set) var currentIndex: Int = 0
  @Published public private(set) var isPlaying: Bool = false
  @Published public private(set) var currentTime: TimeInterval = 0

  public let playlist: [MetroSong]

  private var player: AVAudioPlayer?
  private var timer: Timer?
  private var delegateProxy: DelegateProxy?

  public init(playlist: [MetroSong] = MetroSong.samplePlaylist) {
    self.playlist = playlist
    super.init()
    #if os(iOS)
    try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
    #endif
  }

  public var currentSong: MetroSong { playlist[currentIndex] }

  public func togglePlayPause() {
    isPlaying ? pause() : play()
  }

  public func play() {
    if player == nil { load(index: currentIndex) }
    #if os(iOS)
    try? AVAudioSession.sharedInstance().setActive(true)
    #endif
    player?.play()
    isPlaying = true
    startTimer()
  }

  public func pause() {
    player?.pause()
    isPlaying = false
    stopTimer()
  }

  public func next() { advance(by: 1) }

  public func previous() {
    // WP's convention: "previous" restarts the current track once you're a few
    // seconds in, and only steps back to the prior track from right near the start.
    if currentTime > 3 {
      seek(to: 0)
      return
    }
    advance(by: -1)
  }

  public func seek(to time: TimeInterval) {
    currentTime = time
    player?.currentTime = time
  }

  private func advance(by delta: Int) {
    let wasPlaying = isPlaying
    pause()
    currentIndex = (currentIndex + delta + playlist.count) % playlist.count
    load(index: currentIndex)
    currentTime = 0
    if wasPlaying { play() }
  }

  private func load(index: Int) {
    let song = playlist[index]
    let data = MetroToneSynth.wavData(frequency: song.frequency, duration: song.duration)
    let audioPlayer = try? AVAudioPlayer(data: data, fileTypeHint: AVFileType.wav.rawValue)
    let proxy = DelegateProxy { [weak self] in self?.handleFinished() }
    delegateProxy = proxy
    audioPlayer?.delegate = proxy
    audioPlayer?.prepareToPlay()
    player = audioPlayer
  }

  private func handleFinished() {
    Task { @MainActor in
      self.next()
      self.play()
    }
  }

  private func startTimer() {
    stopTimer()
    let t = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
      Task { @MainActor in
        guard let self, let player = self.player else { return }
        self.currentTime = player.currentTime
      }
    }
    RunLoop.main.add(t, forMode: .common)
    timer = t
  }

  private func stopTimer() {
    timer?.invalidate()
    timer = nil
  }

  /// `AVAudioPlayerDelegate` requires `NSObjectProtocol` conformance on a type that
  /// isn't `@MainActor`-isolated in the way `MetroMusicPlayer` is; a tiny proxy avoids
  /// fighting Swift concurrency over a single callback.
  private final class DelegateProxy: NSObject, AVAudioPlayerDelegate {
    let onFinish: () -> Void
    init(onFinish: @escaping () -> Void) { self.onFinish = onFinish }
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
      onFinish()
    }
  }
}
