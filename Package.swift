// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Noted",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "Noted", targets: ["Noted"])
    ],
    targets: [
        .executableTarget(
            name: "Noted",
            dependencies: [],
            path: "Sources",
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("SwiftUI")
            ]
        )
    ]
)