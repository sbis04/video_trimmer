// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "video_trimmer",
    platforms: [
        .iOS("12.0")
    ],
    products: [
        .library(name: "video-trimmer", targets: ["video_trimmer"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "video_trimmer",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ],
            resources: [
                .process("PrivacyInfo.xcprivacy")
            ]
        )
    ]
)
