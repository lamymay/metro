#if os(iOS)
  import Foundation
  import MediaPlayer

  final class SystemMusicPlayer {
    private let queue = DispatchQueue(label: "SystemMusicPlayer.queue")
    private let player = MPMusicPlayerController.applicationMusicPlayer
    private var observers: [NSObjectProtocol] = []
    private var playbackRate: Float = 1.0
    private var timeTimer: Timer?

    var onIsPlayingChanged: (@Sendable (Bool) -> Void)?
    var onNowPlayingChanged:
      (@Sendable (_ persistentID: UInt64, _ title: String?, _ artist: String?) -> Void)?
    var onTimeChanged: (@Sendable (_ current: Double, _ duration: Double) -> Void)?

    init() {
      player.beginGeneratingPlaybackNotifications()

      let nc = NotificationCenter.default
      observers.append(
        nc.addObserver(
          forName: .MPMusicPlayerControllerPlaybackStateDidChange,
          object: player,
          queue: .main
        ) { [weak self] _ in
          guard let self else { return }
          let playing = self.player.playbackState == .playing
          self.onIsPlayingChanged?(playing)
          if playing {
            self.startTimeTimer()
          } else {
            self.stopTimeTimer()
            self.emitTimeSnapshot()
          }
        }
      )

      observers.append(
        nc.addObserver(
          forName: .MPMusicPlayerControllerNowPlayingItemDidChange,
          object: player,
          queue: .main
        ) { [weak self] _ in
          guard let self else { return }
          guard let item = self.player.nowPlayingItem else { return }
          self.onNowPlayingChanged?(item.persistentID, item.title, item.artist)
          self.emitTimeSnapshot()
        }
      )
    }

    func play(persistentID: UInt64, rate: Float) {
      queue.async { [weak self] in
        guard let self else { return }
        self.playbackRate = rate

        let predicate = MPMediaPropertyPredicate(
          value: NSNumber(value: persistentID),
          forProperty: MPMediaItemPropertyPersistentID
        )
        let query = MPMediaQuery.songs()
        query.addFilterPredicate(predicate)
        guard let item = query.items?.first else { return }

        let collection = MPMediaItemCollection(items: [item])
        let descriptor = MPMusicPlayerMediaItemQueueDescriptor(itemCollection: collection)
        DispatchQueue.main.async { [weak self] in
          guard let self else { return }
          self.player.setQueue(with: descriptor)
          self.player.currentPlaybackRate = rate
          self.player.play()
        }
      }
    }

    func togglePlayPause() {
      queue.async { [weak self] in
        DispatchQueue.main.async { [weak self] in
          guard let self else { return }
          if self.player.playbackState == .playing {
            self.player.pause()
          } else {
            self.player.play()
            // 在 play() 之后立即重新应用倍速，确保系统播放器不会重置它
            self.player.currentPlaybackRate = self.playbackRate
          }
        }
      }
    }

    func seek(to seconds: Double) {
      queue.async { [weak self] in
        DispatchQueue.main.async { [weak self] in
          guard let self else { return }
          self.player.currentPlaybackTime = max(0, seconds)
          self.emitTimeSnapshot()
        }
      }
    }

    func setShuffle(_ enabled: Bool) {
      queue.async { [weak self] in
        DispatchQueue.main.async { [weak self] in
          guard let self else { return }
          self.player.shuffleMode = enabled ? .songs : .off
        }
      }
    }

    func setRepeatOne(_ enabled: Bool) {
      queue.async { [weak self] in
        DispatchQueue.main.async { [weak self] in
          guard let self else { return }
          self.player.repeatMode = enabled ? .one : .none
        }
      }
    }

    func stop() {
      queue.async { [weak self] in
        DispatchQueue.main.async { [weak self] in
          guard let self else { return }
          self.player.stop()
        }
      }
    }

    func setRate(_ rate: Float) {
      queue.async { [weak self] in
        guard let self else { return }
        self.playbackRate = rate
        DispatchQueue.main.async { [weak self] in
          self?.player.currentPlaybackRate = rate
        }
      }
    }

    func shutdown() {
      stopTimeTimer()
      let nc = NotificationCenter.default
      for token in observers {
        nc.removeObserver(token)
      }
      observers.removeAll()
      player.endGeneratingPlaybackNotifications()
    }

    private func startTimeTimer() {
      DispatchQueue.main.async { [weak self] in
        guard let self else { return }
        if self.timeTimer != nil { return }
        self.timeTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) {
          [weak self] _ in
          self?.emitTimeSnapshot()
        }
        RunLoop.main.add(self.timeTimer!, forMode: .common)
      }
    }

    private func stopTimeTimer() {
      DispatchQueue.main.async { [weak self] in
        guard let self else { return }
        self.timeTimer?.invalidate()
        self.timeTimer = nil
      }
    }

    private func emitTimeSnapshot() {
      // MPMusicPlayerController 推荐在主线程读写。
      DispatchQueue.main.async { [weak self] in
        guard let self else { return }
        let current = self.player.currentPlaybackTime
        let duration = self.player.nowPlayingItem?.playbackDuration ?? 0
        self.onTimeChanged?(
          max(0, current.isFinite ? current : 0), max(0, duration.isFinite ? duration : 0))
      }
    }
  }

#endif
