import Foundation
import Darwin
import SQLite3

public enum DoctorSeverity: Int, Sendable {
    case ok = 0
    case warning = 1
    case fatal = 2
}

public struct DoctorCheck: Sendable {
    public let title: String
    public let severity: DoctorSeverity
    public let message: String?

    public init(
        title: String,
        severity: DoctorSeverity,
        message: String? = nil
    ) {
        self.title = title
        self.severity = severity
        self.message = message
    }
}

public enum TerminalColor {
    private static let useColor = isatty(1) != 0

    public static let reset = useColor ? "\u{001B}[0m" : ""
    public static let green = useColor ? "\u{001B}[32m" : ""
    public static let yellow = useColor ? "\u{001B}[33m" : ""
    public static let red = useColor ? "\u{001B}[31m" : ""
    public static let cyan = useColor ? "\u{001B}[36m" : ""
    public static let dim = useColor ? "\u{001B}[2m" : ""
}

public struct DoctorService {
    private let fileManager: FileManager

    public init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }
    
    @discardableResult
    public func run() async -> Int32 {
        print("\(TerminalColor.cyan)Download Organizer Doctor\(TerminalColor.reset)")
        print("\(TerminalColor.dim)Running health checks...\(TerminalColor.reset)")
        print("")

        let checks = await runChecks()

        for check in checks {
            print(format(check))
        }

        print("")

        let finalSeverity = checks.map(\.severity.rawValue).max() ?? 0

        switch finalSeverity {
        case DoctorSeverity.fatal.rawValue:
            print("\(TerminalColor.red)Doctor finished with fatal errors.\(TerminalColor.reset)")
            return 2
        case DoctorSeverity.warning.rawValue:
            print("\(TerminalColor.yellow)Doctor finished with warnings.\(TerminalColor.reset)")
            return 1
        default:
            print("\(TerminalColor.green)Everything looks good.\(TerminalColor.reset)")
            return 0
        }
    }

    public func runChecks() async -> [DoctorCheck] {
        var checks: [DoctorCheck] = []

        checks.append(checkLaunchAgentInstalled())
        checks.append(checkLaunchAgentRunning())
        checks.append(checkDownloadsExists())
        checks.append(checkDownloadsReadable())
        checks.append(checkDownloadsWritable())
        checks.append(checkConfigurationExists())
        checks.append(checkConfigurationJSONValid())
        checks.append(checkRulesExists())
        checks.append(checkRulesJSONValid())
        checks.append(checkSQLiteAccessible())
        checks.append(checkLogDirectoryExists())
        checks.append(await checkRetryQueueStatus())
        checks.append(checkWatchFolderAccessible())

        return checks
    }

    // MARK: - LaunchAgent

    private func checkLaunchAgentInstalled() -> DoctorCheck {
        if fileManager.fileExists(atPath: Paths.launchAgentFile.path) {
            return DoctorCheck(title: "LaunchAgent installed", severity: .ok)
        }

        return DoctorCheck(
            title: "LaunchAgent missing",
            severity: .fatal,
            message: Paths.launchAgentFile.path
        )
    }

    private func checkLaunchAgentRunning() -> DoctorCheck {
        let label = "com.downloadorganizer.agent"
        let process = Process()
        let pipe = Pipe()

        process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        process.arguments = ["print", "gui/\(getuid())/\(label)"]
        process.standardOutput = pipe
        process.standardError = pipe

        do {
            try process.run()
            process.waitUntilExit()

            if process.terminationStatus == 0 {
                return DoctorCheck(title: "Service running", severity: .ok)
            }

            return DoctorCheck(
                title: "Service not running",
                severity: .warning,
                message: "LaunchAgent exists but is not currently active"
            )
        } catch {
            return DoctorCheck(
                title: "Service status unavailable",
                severity: .warning,
                message: error.localizedDescription
            )
        }
    }

    // MARK: - Downloads

    private func checkDownloadsExists() -> DoctorCheck {
        let url = Paths.home.appendingPathComponent("Downloads", isDirectory: true)

        var isDirectory: ObjCBool = false
        let exists = fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory)

        if exists && isDirectory.boolValue {
            return DoctorCheck(title: "Downloads folder exists", severity: .ok)
        }

        return DoctorCheck(
            title: "Downloads folder missing",
            severity: .fatal,
            message: url.path
        )
    }

    private func checkDownloadsReadable() -> DoctorCheck {
        let url = Paths.home.appendingPathComponent("Downloads", isDirectory: true)

        if fileManager.isReadableFile(atPath: url.path) {
            return DoctorCheck(title: "Downloads readable", severity: .ok)
        }

        return DoctorCheck(
            title: "Downloads not readable",
            severity: .fatal,
            message: url.path
        )
    }

    private func checkDownloadsWritable() -> DoctorCheck {
        let url = Paths.home.appendingPathComponent("Downloads", isDirectory: true)

        if fileManager.isWritableFile(atPath: url.path) {
            return DoctorCheck(title: "Downloads writable", severity: .ok)
        }

        return DoctorCheck(
            title: "Downloads not writable",
            severity: .fatal,
            message: url.path
        )
    }

    // MARK: - Config

    private func checkConfigurationExists() -> DoctorCheck {
        if fileManager.fileExists(atPath: Paths.configFile.path) {
            return DoctorCheck(title: "Configuration file exists", severity: .ok)
        }

        return DoctorCheck(
            title: "Config missing",
            severity: .fatal,
            message: Paths.configFile.path
        )
    }

    private func checkConfigurationJSONValid() -> DoctorCheck {
        guard fileManager.fileExists(atPath: Paths.configFile.path) else {
            return DoctorCheck(
                title: "Config invalid",
                severity: .fatal,
                message: "File does not exist"
            )
        }

        do {
            let data = try Data(contentsOf: Paths.configFile)
            _ = try JSONDecoder().decode(AppConfiguration.self, from: data)
            return DoctorCheck(title: "Config OK", severity: .ok)
        } catch {
            return DoctorCheck(
                title: "Config invalid",
                severity: .fatal,
                message: error.localizedDescription
            )
        }
    }

    // MARK: - Rules

    private func checkRulesExists() -> DoctorCheck {
        if fileManager.fileExists(atPath: Paths.rulesFile.path) {
            return DoctorCheck(title: "Rules file exists", severity: .ok)
        }

        return DoctorCheck(
            title: "Rules missing",
            severity: .warning,
            message: Paths.rulesFile.path
        )
    }

    private func checkRulesJSONValid() -> DoctorCheck {
        guard fileManager.fileExists(atPath: Paths.rulesFile.path) else {
            return DoctorCheck(
                title: "Rules skipped",
                severity: .warning,
                message: "Rules file does not exist"
            )
        }

        do {
            let data = try Data(contentsOf: Paths.rulesFile)

            if data.isEmpty {
                return DoctorCheck(
                    title: "Rules invalid",
                    severity: .warning,
                    message: "rules.json is empty"
                )
            }

            _ = try JSONDecoder().decode([String: [String]].self, from: data)
            return DoctorCheck(title: "Rules OK", severity: .ok)
        } catch {
            return DoctorCheck(
                title: "Rules invalid",
                severity: .warning,
                message: error.localizedDescription
            )
        }
    }

    // MARK: - SQLite

    private func checkSQLiteAccessible() -> DoctorCheck {
        do {
            try fileManager.createDirectory(
                at: Paths.baseDirectory,
                withIntermediateDirectories: true
            )

            var db: OpaquePointer?
            let result = sqlite3_open_v2(
                Paths.databaseFile.path,
                &db,
                SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_FULLMUTEX,
                nil
            )

            defer {
                if db != nil {
                    sqlite3_close(db)
                }
            }

            guard result == SQLITE_OK else {
                let message = db.map { String(cString: sqlite3_errmsg($0)) } ?? "Unable to open database"
                return DoctorCheck(
                    title: "SQLite failed",
                    severity: .fatal,
                    message: message
                )
            }

            return DoctorCheck(title: "SQLite OK", severity: .ok)
        } catch {
            return DoctorCheck(
                title: "SQLite failed",
                severity: .fatal,
                message: error.localizedDescription
            )
        }
    }

    // MARK: - Logs

    private func checkLogDirectoryExists() -> DoctorCheck {
        var isDirectory: ObjCBool = false
        let exists = fileManager.fileExists(
            atPath: Paths.logsDirectory.path,
            isDirectory: &isDirectory
        )

        if exists && isDirectory.boolValue {
            return DoctorCheck(title: "Logs OK", severity: .ok)
        }

        return DoctorCheck(
            title: "Log directory missing",
            severity: .warning,
            message: Paths.logsDirectory.path
        )
    }

    // MARK: - Retry Queue

    private func checkRetryQueueStatus() async -> DoctorCheck {
        let retryCount = await FileMover.shared.retryQueueCount()
        let activeCount = await FileMover.shared.activeQueueCount()

        if retryCount == 0 {
            return DoctorCheck(
                title: "Retry queue OK",
                severity: .ok,
                message: "active: \(activeCount), retry: \(retryCount)"
            )
        }

        return DoctorCheck(
            title: "Retry queue has pending files",
            severity: .warning,
            message: "active: \(activeCount), retry: \(retryCount)"
        )
    }

    // MARK: - Watch Folder

    private func checkWatchFolderAccessible() -> DoctorCheck {
        let config: AppConfiguration

        do {
            if fileManager.fileExists(atPath: Paths.configFile.path) {
                let data = try Data(contentsOf: Paths.configFile)
                config = try JSONDecoder().decode(AppConfiguration.self, from: data)
            } else {
                config = .default
            }
        } catch {
            return DoctorCheck(
                title: "Watch folder unavailable",
                severity: .fatal,
                message: "Unable to read config: \(error.localizedDescription)"
            )
        }

        let watchFolder = Paths.expandingTilde(config.watchFolder)

        var isDirectory: ObjCBool = false
        let exists = fileManager.fileExists(
            atPath: watchFolder.path,
            isDirectory: &isDirectory
        )

        guard exists && isDirectory.boolValue else {
            return DoctorCheck(
                title: "Watch folder missing",
                severity: .fatal,
                message: watchFolder.path
            )
        }

        guard fileManager.isReadableFile(atPath: watchFolder.path) else {
            return DoctorCheck(
                title: "Watch folder not readable",
                severity: .fatal,
                message: watchFolder.path
            )
        }

        guard fileManager.isWritableFile(atPath: watchFolder.path) else {
            return DoctorCheck(
                title: "Watch folder not writable",
                severity: .fatal,
                message: watchFolder.path
            )
        }

        return DoctorCheck(
            title: "Watch folder accessible",
            severity: .ok,
            message: watchFolder.path
        )
    }

    // MARK: - Formatting

    private func format(_ check: DoctorCheck) -> String {
        let prefix: String
        let color: String

        switch check.severity {
        case .ok:
            prefix = "✓"
            color = TerminalColor.green
        case .warning:
            prefix = "!"
            color = TerminalColor.yellow
        case .fatal:
            prefix = "✗"
            color = TerminalColor.red
        }

        if let message = check.message, !message.isEmpty {
            return "\(color)\(prefix) \(check.title)\(TerminalColor.reset) \(TerminalColor.dim)(\(message))\(TerminalColor.reset)"
        }

        return "\(color)\(prefix) \(check.title)\(TerminalColor.reset)"
    }
}