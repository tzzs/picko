// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Picko",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "PickoCore", targets: ["PickoCore"]),
        .library(name: "PickoPhotos", targets: ["PickoPhotos"]),
        .library(name: "PickoApp", targets: ["PickoApp"]),
        .library(name: "PickoMacApp", targets: ["PickoMacApp"]),
        .executable(name: "PickoBenchmarks", targets: ["PickoBenchmarks"])
    ],
    targets: [
        .target(name: "PickoCore"),
        .target(
            name: "PickoPhotos",
            dependencies: ["PickoCore"],
            linkerSettings: [
                .linkedFramework("Photos", .when(platforms: [.iOS, .macOS]))
            ]
        ),
        .target(
            name: "PickoApp",
            dependencies: ["PickoCore", "PickoPhotos"]
        ),
        .target(
            name: "PickoMacApp",
            dependencies: ["PickoApp", "PickoCore", "PickoPhotos"]
        ),
        .executableTarget(
            name: "PickoBenchmarks",
            dependencies: ["PickoPhotos"],
            path: "Tools/PickoBenchmarks"
        ),
        .testTarget(name: "PickoCoreTests", dependencies: ["PickoCore"]),
        .testTarget(name: "PickoPhotosTests", dependencies: ["PickoPhotos"]),
        .testTarget(name: "PickoAppTests", dependencies: ["PickoApp"]),
        .testTarget(name: "PickoMacAppTests", dependencies: ["PickoMacApp"])
    ]
)
