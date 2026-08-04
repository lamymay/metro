import SwiftUI

/// Standard WP page chrome: a small tracked-out application title, then the lowercase
/// page header, then content. The 9pt indent and the negative leading between the two
/// titles are from the stock `PhoneApplicationPage` template — they are small, and they
/// are most of why the header reads as Metro rather than as a generic nav bar.
public struct MetroPage<Content: View>: View {
  @Environment(\.metroTheme) private var theme

  public var applicationTitle: String?
  public var title: String?
  public var content: Content

  public init(
    applicationTitle: String? = nil,
    title: String? = nil,
    @ViewBuilder content: () -> Content
  ) {
    self.applicationTitle = applicationTitle
    self.title = title
    self.content = content()
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      if applicationTitle != nil || title != nil {
        VStack(alignment: .leading, spacing: 0) {
          if let applicationTitle {
            MetroApplicationTitle(applicationTitle)
          }
          if let title {
            Text(title)
              .metroText(.pageTitle)
              .padding(.leading, 7)
              .padding(.top, -6)
              .lineLimit(1)
              .minimumScaleFactor(0.6)
          }
        }
        .padding(.leading, theme.metrics.pageMargin)
        .padding(.top, 14)
        .padding(.bottom, 22)
      }

      content
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
  }
}

/// Drives WP page transitions off a route stack.
///
/// `content` is called for both the outgoing and the incoming page, so the two always
/// have the same concrete view type and no type erasure is needed. Pass `nil` for the
/// root.
public struct MetroNavigationView<Route: Hashable, Content: View>: View {
  @Environment(\.metroMotion) private var motion

  @Binding public var path: [Route]
  public var transition: MetroTransitionKind
  @ViewBuilder public var content: (Route?) -> Content

  private struct Stage: Equatable {
    var from: Route?
    var to: Route?
    var direction: MetroNavDirection
    var token: Int
  }

  @State private var displayed: [Route] = []
  @State private var stage: Stage?
  @State private var progress: Double = 1
  @State private var nextToken = 0
  @State private var hasAppeared = false

  public init(
    path: Binding<[Route]>,
    transition: MetroTransitionKind = .turnstile,
    @ViewBuilder content: @escaping (Route?) -> Content
  ) {
    self._path = path
    self.transition = transition
    self.content = content
  }

  public var body: some View {
    ZStack {
      if let stage {
        MetroTransitionStage(
          progress: progress,
          kind: transition,
          direction: stage.direction,
          config: motion,
          outgoing: content(stage.from),
          incoming: content(stage.to)
        )
      } else {
        content(displayed.last)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    // `task(id:)` rather than `onChange(of:perform:)`: the two-argument `onChange` is
    // iOS 17+, and the one this would otherwise need is deprecated from macOS 14.
    .task(id: path) {
      guard hasAppeared else {
        hasAppeared = true
        displayed = path
        return
      }
      run(to: path)
    }
  }

  private func run(to newPath: [Route]) {
    let previous = displayed
    guard newPath != previous else { return }

    let direction: MetroNavDirection = newPath.count >= previous.count ? .forward : .backward
    let from = previous.last
    let to = newPath.last
    displayed = newPath

    guard transition != .none else { return }

    nextToken &+= 1
    let token = nextToken
    stage = Stage(from: from, to: to, direction: direction, token: token)
    progress = 0

    let total = motion.duration(motion.turnstileOutDuration + motion.turnstileInDuration)
    withAnimation(.linear(duration: total)) { progress = 1 }

    // The stage tears itself down once the clock has run out; the token guards against
    // a second navigation landing mid-flight.
    DispatchQueue.main.asyncAfter(deadline: .now() + total + 0.02) {
      if stage?.token == token { stage = nil }
    }
  }
}

/// The on-screen stand-in for WP's hardware back key.
public struct MetroBackButton: View {
  @Environment(\.metroTheme) private var theme
  public var action: () -> Void

  public init(action: @escaping () -> Void) {
    self.action = action
  }

  public var body: some View {
    MetroIcon(.back, size: 24, color: theme.foreground, weight: 1.0 / 14)
      .frame(width: 44, height: 44)
      .contentShape(Rectangle())
      .metroTilt { action() }
      .accessibilityLabel("Back")
  }
}
