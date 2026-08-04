// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "MetroKit",
  platforms: [.iOS(.v15), .macOS(.v15)],
  products: [
    .library(name: "MetroKit", targets: ["MetroKit"])
  ],
  targets: [
    .target(name: "MetroKit"),
    .testTarget(name: "MetroKitTests", dependencies: ["MetroKit"]),
  ],
  swiftLanguageModes: [.v5]
)
