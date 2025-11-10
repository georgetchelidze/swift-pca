// swift-tools-version: 5.9
import PackageDescription
import Foundation

let openblasPrefix: String = {
    let env = ProcessInfo.processInfo.environment["OPENBLAS_PREFIX"]
    if let env, !env.isEmpty { return env }
    #if os(macOS)
      #if arch(arm64)
      return "Vendor/build/darwin-arm64"
      #elseif arch(x86_64)
      return "Vendor/build/darwin-x86_64"
      #else
      return "Vendor/build/darwin-unknown"
      #endif
    #elseif os(Linux)
      #if arch(x86_64)
      return "Vendor/build/linux-x86_64"
      #else
      return "Vendor/build/linux-unknown" // Provide your own via OPENBLAS_PREFIX
      #endif
    #else
      return "Vendor/build/unknown"
    #endif
}()

let includeFlags = ["-I", "\(openblasPrefix)/include"]
let libFlags = ["-L", "\(openblasPrefix)/lib"]

let package = Package(
    name: "swift-pca",
    platforms: [
        .macOS(.v13)
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
            name: "COpenBLAS",
            dependencies: [],
            cSettings: [
                .unsafeFlags(includeFlags, .when(platforms: [.linux]))
            ],
            linkerSettings: [
                // Linux: search path for vendored OpenBLAS and runtime libs
                .unsafeFlags(libFlags, .when(platforms: [.linux])),

                // Linux: link static OpenBLAS and deps
                .linkedLibrary("openblas", .when(platforms: [.linux])),
                .linkedLibrary("m", .when(platforms: [.linux])),
                .linkedLibrary("pthread", .when(platforms: [.linux])),
                .linkedLibrary("gfortran", .when(platforms: [.linux])),
                .linkedLibrary("quadmath", .when(platforms: [.linux])),

                // macOS: use Accelerate instead of vendored OpenBLAS
                .linkedFramework("Accelerate", .when(platforms: [.macOS]))
            ]
        ),
        .target(
            name: "PCA",
            dependencies: ["COpenBLAS"]
        ),
        .testTarget(
            name: "PCATests",
            dependencies: ["PCA"]
        ),
    ]
)
