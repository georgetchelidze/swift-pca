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
let rpathFlags: [LinkedSetting] = [
    .unsafeFlags(["-Xlinker", "-rpath", "-Xlinker", "\(openblasPrefix)/lib"]) 
]

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
            cSettings: [ .unsafeFlags(includeFlags) ],
            linkerSettings: [ .unsafeFlags(libFlags) ] + rpathFlags + [
                .linkedLibrary("openblas"),
                .linkedLibrary("m", .when(platforms: [.linux])),
                .linkedLibrary("pthread", .when(platforms: [.linux])),
                .linkedLibrary("gfortran")
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
