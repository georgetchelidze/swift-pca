// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "swift-pca",
    platforms: [
        .macOS(.v13),
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "PCA",
            targets: ["PCA"]
        ),
    ],
    dependencies: [
        // No dependencies — pure Swift
    ],
    targets: [
        .target(
            name: "PCA",
            dependencies: []
        ),
        .testTarget(
            name: "PCATests",
            dependencies: ["PCA"]
        ),
    ]
)
