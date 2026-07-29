import Foundation

public enum Paths {
    public static var home: URL {
        FileManager.default.homeDirectoryForCurrentUser
    }

    public static var baseDirectory: URL {
        home.appendingPathComponent(".download-organizer", isDirectory: true)
    }

    public static var configFile: URL {
        baseDirectory.appendingPathComponent("config.json")
    }

    public static var rulesFile: URL {
        baseDirectory.appendingPathComponent("rules.json")
    }

    public static var databaseFile: URL {
        baseDirectory.appendingPathComponent("history.db")
    }

    public static var logsDirectory: URL {
        baseDirectory.appendingPathComponent("logs", isDirectory: true)
    }

    public static var launchAgentFile: URL {
        home
            .appendingPathComponent("Library", isDirectory: true)
            .appendingPathComponent("LaunchAgents", isDirectory: true)
            .appendingPathComponent("com.downloadorganizer.agent.plist")
    }

    public static func expandingTilde(_ path: String) -> URL {
        if path == "~" {
            return home
        }

        if path.hasPrefix("~/") {
            let relativePath = String(path.dropFirst(2))
            return home.appendingPathComponent(relativePath)
        }

        return URL(fileURLWithPath: path)
    }

    public static func pathByAbbreviatingHome(_ url: URL) -> String {
        let homePath = home.path
        let path = url.path

        if path == homePath {
            return "~"
        }

        if path.hasPrefix(homePath + "/") {
            return "~" + String(path.dropFirst(homePath.count))
        }

        return path
    }
}