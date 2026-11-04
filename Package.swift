// swift-tools-version:5.10
import PackageDescription

var targets: [Target] = [
    .target(name: "TimerCore"),
    .testTarget(name: "TimerCoreTests", dependencies: ["TimerCore"]),
]
var dependencies: [Package.Dependency] = []
var products: [Product] = [.library(name: "TimerCore", targets: ["TimerCore"])]

#if os(macOS)
dependencies.append(.package(url: "https://github.com/sindresorhus/KeyboardShortcuts", .upToNextMajor(from: "2.4.0")))
targets.append(.executableTarget(
    name: "CornerTimerApp",
    dependencies: ["TimerCore", .product(name: "KeyboardShortcuts", package: "KeyboardShortcuts")]
))
products.append(.executable(name: "CornerTimer", targets: ["CornerTimerApp"]))
#endif

let package = Package(
    name: "CornerTimer",
    platforms: [.macOS(.v14)],
    products: products,
    dependencies: dependencies,
    targets: targets
)
