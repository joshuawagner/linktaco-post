// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "LinkTacoQuickSave",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "LinkTacoQuickSave", targets: ["LinkTacoQuickSave"])
    ],
    targets: [
        .executableTarget(
            name: "LinkTacoQuickSave",
            path: "Sources/LinkTacoQuickSave"
        )
    ]
)
