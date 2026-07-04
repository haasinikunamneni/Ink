// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "BulletJournal",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "BulletJournal",
            path: "Sources/BulletJournal"
        )
    ]
)
