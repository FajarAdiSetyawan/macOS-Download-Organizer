import Foundation

public enum DuplicateStrategy: String, Codable, CaseIterable, Sendable {
    case rename
    case overwrite
    case skip

    public var label: String {
        switch self {
        case .rename: return "Rename"
        case .overwrite: return "Overwrite"
        case .skip: return "Skip"
        }
    }

    public var description: String {
        switch self {
        case .rename: return "Add (1), (2), ..."
        case .overwrite: return "Replace existing"
        case .skip: return "Leave existing"
        }
    }
}

public struct AppConfiguration: Codable, Sendable {
    public var enabled: Bool
    public var watchFolder: String
    public var additionalWatchFolder: String?
    public var delay: TimeInterval
    public var notifications: Bool
    public var autoCreateFolders: Bool
    public var duplicateStrategy: String
    public var history: Bool
    public var theme: String
    public var dailySummary: Bool
    public var lastSummaryDate: String?

    public init(
        enabled: Bool,
        watchFolder: String,
        additionalWatchFolder: String? = nil,
        delay: TimeInterval,
        notifications: Bool,
        autoCreateFolders: Bool,
        duplicateStrategy: String,
        history: Bool,
        theme: String = "dark",
        dailySummary: Bool = true,
        lastSummaryDate: String? = nil
    ) {
        self.enabled = enabled
        self.watchFolder = watchFolder
        self.additionalWatchFolder = additionalWatchFolder
        self.delay = delay
        self.notifications = notifications
        self.autoCreateFolders = autoCreateFolders
        self.duplicateStrategy = duplicateStrategy
        self.history = history
        self.theme = theme
        self.dailySummary = dailySummary
        self.lastSummaryDate = lastSummaryDate
    }

    public var parsedDuplicateStrategy: DuplicateStrategy {
        DuplicateStrategy(rawValue: duplicateStrategy) ?? .rename
    }

    public static let `default` = AppConfiguration(
        enabled: true,
        watchFolder: "~/Downloads",
        additionalWatchFolder: nil,
        delay: 3,
        notifications: true,
        autoCreateFolders: true,
        duplicateStrategy: "rename",
        history: true,
        theme: "dark",
        dailySummary: true,
        lastSummaryDate: nil
    )
}
