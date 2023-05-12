// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SEChatTUI",
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire.git", .upToNextMajor(from: "5.7.0")),
        .package(url: "https://github.com/scinfu/SwiftSoup.git", .upToNextMajor(from: "2.6.0"))
    ],
    targets: [
        .executableTarget(
            name: "SEChatTUI",
            dependencies: [
                .product(name: "Alamofire", package: "Alamofire"),
                .product(name: "SwiftSoup", package: "SwiftSoup")
            ],
            path: "Sources"
        ),
    ],
    swiftLanguageVersions: [.v5]
)
