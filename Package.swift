// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "HMKit",
    platforms: [
        .iOS(.v10)
    ],
    products: [
        .library(name: "HMKit", targets: ["HMKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/highmobility/hmcryptokit-swift", .upToNextMinor(from: "1.2.15")),
        .package(url: "https://github.com/highmobility/hmutilities-swift", .upToNextMinor(from: "1.4.6")),
    ],
    targets: [
        .target(name: "HMKit", dependencies: ["HMCryptoKit", "HMUtilities"], exclude: ["Resources", "Supporting Files"]),
        .testTarget(name: "HMKitTests", dependencies: ["HMKit"]),
    ]
)
