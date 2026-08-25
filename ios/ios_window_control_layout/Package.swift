// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "ios_window_control_layout",
    platforms: [
        .iOS("13.0")
    ],
    products: [
        .library(
            name: "ios-window-control-layout",
            targets: ["ios_window_control_layout"]
        )
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "ios_window_control_layout",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ]
        )
    ]
)
