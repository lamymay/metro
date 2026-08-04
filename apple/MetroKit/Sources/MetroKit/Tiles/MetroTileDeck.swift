import SwiftUI

/// Turns between faces about the horizontal centre line.
///
/// `progress` advances by exactly 1 per flip and is never reset, so the integer part
/// selects the face and the fraction drives the rotation. Conforming the *view* to
/// `Animatable` — rather than putting the rotation in a modifier — is what lets the
/// body re-resolve which face is on top on every interpolated frame.
struct MetroFlipDeck<Content: View>: View, Animatable {
  var progress: Double
  var perspective: Double
  var faceCount: Int
  @ViewBuilder var content: (Int) -> Content

  var animatableData: Double {
    get { progress }
    set { progress = newValue }
  }

  var body: some View {
    let base = Int(progress.rounded(.down))
    let frac = progress - Double(base)
    let pastHalfway = frac >= 0.5

    ZStack {
      content(index(base))
        .opacity(pastHalfway ? 0 : 1)
      content(index(base + 1))
        .rotation3DEffect(.degrees(180), axis: (x: 1, y: 0, z: 0))
        .opacity(pastHalfway ? 1 : 0)
    }
    .rotation3DEffect(
      .degrees(frac * 180),
      axis: (x: 1, y: 0, z: 0),
      perspective: perspective
    )
  }

  private func index(_ raw: Int) -> Int {
    guard faceCount > 0 else { return 0 }
    return ((raw % faceCount) + faceCount) % faceCount
  }
}

/// Pushes the next face up from below, the way WP's "iconic" and photo templates
/// cycled their text.
struct MetroSlideDeck<Content: View>: View, Animatable {
  var progress: Double
  var height: CGFloat
  var faceCount: Int
  @ViewBuilder var content: (Int) -> Content

  var animatableData: Double {
    get { progress }
    set { progress = newValue }
  }

  var body: some View {
    let base = Int(progress.rounded(.down))
    let frac = progress - Double(base)

    ZStack {
      content(index(base))
        .offset(y: -frac * height)
      content(index(base + 1))
        .offset(y: (1 - frac) * height)
    }
    .clipped()
  }

  private func index(_ raw: Int) -> Int {
    guard faceCount > 0 else { return 0 }
    return ((raw % faceCount) + faceCount) % faceCount
  }
}
