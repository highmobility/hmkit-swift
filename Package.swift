// swift-tools-version:5.4
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "HMKit",
    platforms: [
        .iOS(.v10),
        .macOS(.v10_13)
    ],
    products: [
        .library(name: "HMKit", targets: ["HMKit"]),
    ],
    dependencies: [
        .package(name: "HMCryptoKit", url: "https://github.com/highmobility/hmcryptokit-swift", .upToNextMinor(from: "1.2.17")),
        .package(name: "HMUtilities", url: "https://github.com/highmobility/hmutilities-swift", .upToNextMinor(from: "1.4.7")),
    ],
    targets: [
        .target(name: "HMKit",
                dependencies: [
                    "HMCryptoKit",
                    "HMUtilities"
                ]),

        .testTarget(name: "HMKitTests",
                    dependencies: [
                        "HMKit"
                    ]),
    ]
)
