// swift-tools-version: 5.9
// NTFSMount — NTFS read/write for macOS
// Author: KECHANKRISNA <ke.chankrisna168@gmail.com>
// License: GPL-3.0
import PackageDescription

let package = Package(
    name: "NTFSMount",
    platforms: [
        .macOS(.v14)   // Sonoma — required for openSettings environment key
    ],
    products: [
        .executable(name: "NTFSMount", targets: ["NTFSMount"])
    ],
    targets: [
        .executableTarget(
            name: "NTFSMount",
            path: "Sources/NTFSMount",
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("Foundation")
            ]
        )
    ]
)
