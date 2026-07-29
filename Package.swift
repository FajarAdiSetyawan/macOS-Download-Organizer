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
    targets: [
        .executableTarget(
            name: "DownloadOrganizer",
            path: "Sources",
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