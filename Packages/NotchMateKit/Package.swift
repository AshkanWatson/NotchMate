// swift-tools-version:5.9
import PackageDescription

// NotchMateKit holds all of NotchMate's platform-independent logic:
// notch detection, geometry/layout math, the hover state machine and settings.
// It depends only on Foundation so it can be unit tested anywhere `swift test` runs.
let package = Package(
    name: "NotchMateKit",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "NotchMateKit", targets: ["NotchMateKit"])
    ],
    targets: [
        .target(name: "NotchMateKit"),
        .testTarget(name: "NotchMateKitTests", dependencies: ["NotchMateKit"])
    ]
)
