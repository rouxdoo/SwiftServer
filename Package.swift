// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftServer",
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/getGuaka/FileUtils.git", .branch("master")),
        .package(url: "https://github.com/uraimo/SwiftyGPIO.git", from: "1.0.0"),
//        .package(url: "https://github.com/robreuss/ElementalController.git", .branch("master")),
        .package(url: "https://github.com/robreuss/ElementalController.git", .exact("0.0.106")),
        ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "SwiftServer",
            dependencies: ["FileUtils", "SwiftyGPIO", "ElementalController"]),
        ]
)
