import Foundation

/// Synthesises short mono WAV clips in memory.
///
/// The music player needs something to actually play — a redistributable UI kit can't
/// bundle licensed songs — so each "track" is a generated chime instead of an mp3.
/// Three stacked harmonics plus a soft attack/release envelope keep it from sounding
/// like a test-tone; the frequency is the only thing that varies per song.
enum MetroToneSynth {
  static func wavData(frequency: Double, duration: Double, sampleRate: Double = 44_100) -> Data {
    let frameCount = max(1, Int(duration * sampleRate))
    let attack = 0.06 * sampleRate
    let release = 0.35 * sampleRate

    var samples = [Int16]()
    samples.reserveCapacity(frameCount)

    for i in 0..<frameCount {
      let t = Double(i) / sampleRate
      var amplitude = 0.22 * sin(2 * .pi * frequency * t)
      amplitude += 0.08 * sin(2 * .pi * frequency * 2 * t)
      amplitude += 0.05 * sin(2 * .pi * frequency * 1.5 * t)

      var envelope = 1.0
      if Double(i) < attack { envelope = Double(i) / attack }
      let remaining = Double(frameCount - i)
      if remaining < release { envelope = min(envelope, remaining / release) }

      let clamped = max(-1, min(1, amplitude * envelope))
      samples.append(Int16(clamped * Double(Int16.max)))
    }

    var data = wavHeader(sampleCount: frameCount, sampleRate: Int(sampleRate))
    samples.withUnsafeBufferPointer { data.append(Data(buffer: $0)) }
    return data
  }

  private static func wavHeader(sampleCount: Int, sampleRate: Int) -> Data {
    let byteRate = sampleRate * 2
    let dataSize = sampleCount * 2
    var header = Data()

    func appendString(_ s: String) { header.append(s.data(using: .ascii)!) }
    func appendUInt32(_ v: UInt32) { withUnsafeBytes(of: v.littleEndian) { header.append(contentsOf: $0) } }
    func appendUInt16(_ v: UInt16) { withUnsafeBytes(of: v.littleEndian) { header.append(contentsOf: $0) } }

    appendString("RIFF")
    appendUInt32(UInt32(36 + dataSize))
    appendString("WAVE")
    appendString("fmt ")
    appendUInt32(16)
    appendUInt16(1) // PCM
    appendUInt16(1) // mono
    appendUInt32(UInt32(sampleRate))
    appendUInt32(UInt32(byteRate))
    appendUInt16(2) // block align
    appendUInt16(16) // bits per sample
    appendString("data")
    appendUInt32(UInt32(dataSize))
    return header
  }
}
