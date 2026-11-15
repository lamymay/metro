// swift-tools-version: 6.0
import PackageDescription

/// 分两层：
///
/// - `PlayerEngine` —— 纯播放能力，无 SwiftUI 视图、无本地曲库。远程流媒体（带鉴权注入）、
///   本地文件、系统曲库、Now Playing / 控制中心、AB 循环。
/// - `Player` —— WP 风格音乐 App 的完整 UI 与本地曲库（曲库扫描、歌单、收藏、导入、主题）。
///
/// 拆的理由：复用方各取所需。MetroMusic 要整个音乐 App，而 NAS 客户端只要播放能力 ——
/// 不分层就只能「要么全拿要么不拿」，为了播一首远程音乐得把整个曲库 UI 拖进去。
///
/// `Player` 这个 target 名刻意保持不变，现有 `import Player` 的调用方无需改动。
let package = Package(
  name: "Player",
  platforms: [.iOS(.v17), .macOS(.v14)],
  products: [
    .library(name: "PlayerEngine", targets: ["PlayerEngine"]),
    .library(name: "Player", targets: ["Player"]),
  ],
  dependencies: [
    .package(url: "https://github.com/groue/GRDB.swift", from: "7.11.1")
  ],
  targets: [
    .target(name: "PlayerEngine"),
    .target(
      name: "Player",
      dependencies: [
        "PlayerEngine",
        .product(name: "GRDB", package: "GRDB.swift"),
      ]
    ),
    .testTarget(name: "PlayerTests", dependencies: ["Player"]),
  ],
  swiftLanguageModes: [.v5]
)
