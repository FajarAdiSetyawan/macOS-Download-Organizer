import Foundation

public struct AppConfiguration: Codable, Sendable {
    public var enabled: Bool
    public var watchFolder: String
    public var delay: TimeInterval
    public var notifications: Bool
    public var autoCreateFolders: Bool
    public var duplicateStrategy: String
    public var history: Bool

    public init(
        enabled: Bool,
        watchFolder: String,
        delay: TimeInterval,
        notifications: Bool,
        autoCreateFolders: Bool,
        duplicateStrategy: String,
        history: Bool
    ) {
        self.enabled = enabled
        self.watchFolder = watchFolder
        self.delay = delay
        self.notifications = notifications
        self.autoCreateFolders = autoCreateFolders
        self.duplicateStrategy = duplicateStrategy
        self.history = history
    }

    public static let `default` = AppConfiguration(
        enabled: true,
        watchFolder: "~/Downloads",
        delay: 3,
        notifications: true,
        autoCreateFolders: true,
        duplicateStrategy: "rename",
        history: true
    )
}