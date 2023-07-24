// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "LocoPipe",
    platforms: [.macOS(.v13)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .executable(name: "locopipe", targets: ["LocoPipe"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.0.0")
    ],
    targets: [
        
        .executableTarget(
            name: "LocoPipe",
            dependencies: [
                "LocoPipeLib"
            ]),
        .target(
            name: "LocoPipeLib",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]),
        .testTarget(
            name: "LocoPipeLibTests",
            dependencies: ["LocoPipeLib"],
            resources: [
                .copy("Resources/TestFile.tsv")
            ]
        )
    ],
    swiftLanguageVersions: [.v5]
)
