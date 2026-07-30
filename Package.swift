// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "DownloadOrganizer",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "download-organizer",
            targets: ["DownloadOrganizer"]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/rensbreur/SwiftTUI.git",
            branch: "main"
        )
    ],
    targets: [
        .executableTarget(
            name: "DownloadOrganizer",
            dependencies: [
                .product(name: "SwiftTUI", package: "SwiftTUI")
            ],
            path: "Sources",
            swiftSettings: [
                .unsafeFlags(["-strict-concurrency=minimal"])
            ],
            linkerSettings: [
                .linkedLibrary("sqlite3")
            ]
        ),
        .testTarget(
            name: "DownloadOrganizerTests",
            dependencies: ["DownloadOrganizer"],
            path: "Tests/DownloadOrganizerTests",
            linkerSettings: [
                .linkedLibrary("sqlite3")
            ]
        )
    ]
)