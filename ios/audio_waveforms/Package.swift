// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "audio_waveforms",
    platforms: [
        .iOS("13.0"),
    ],
    products: [
        .library(name: "audio-waveforms", targets: ["audio_waveforms"]),
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework"),
    ],
    targets: [
        .target(
            name: "audio_waveforms",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework"),
            ],
            path: "Sources/audio_waveforms"
        ),
    ]
)
