// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "JsonSyntax",
    platforms: [
        .macOS(.v10_14),
        .iOS(.v12),
    ],
    products: [
        .library(
            name: "JsonSyntax",
            type: .dynamic,
            targets: ["JsonSyntax"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "JsonSyntax",
            dependencies: [],
            path: "Sources"),

        .testTarget(
            name: "JsonSyntaxTests",
            dependencies: ["JsonSyntax"],
            path: "Tests/JsonSyntaxTests"),

        .testTarget(
            name: "FuzzTests",
            dependencies: ["JsonSyntax"],
            path: "Tests/FuzzTests")
    ],
    swiftLanguageVersions: [.v5]
)
