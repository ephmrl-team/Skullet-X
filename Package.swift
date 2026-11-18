// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SkulletX",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "SkulletX", targets: ["SkulletX"]),
        .library(name: "SkulletXCore", targets: ["SkulletXCore"]),
    ],
    targets: [
        .target(
            name: "SkulletXCore",
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .target(
            name: "SkulletX",
            dependencies: ["SkulletXCore"],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .testTarget(
            name: "SkulletXCoreTests",
            dependencies: ["SkulletXCore"],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
    ]
)
