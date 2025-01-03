// swift-tools-version:5.3
// SPDX-FileCopyrightText: 2024 Moritz Schaub <moritz@pfaender.net>
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import PackageDescription

let package = Package(
    name: "BackAppCore",
    platforms: [.iOS(.v13)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "BackAppCore",
            targets: ["BackAppCore"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(name: "BakingRecipeFoundation", path: "../BakingRecipeFoundation"),
        .package(url: "https://github.com/SwiftyJSON/SwiftyJSON.git", from: "5.0.1")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "BackAppCore",
            dependencies: ["BakingRecipeFoundation", "SwiftyJSON"]),
        .testTarget(
            name: "BackAppCoreTests",
            dependencies: ["BackAppCore"]),
    ]
)
