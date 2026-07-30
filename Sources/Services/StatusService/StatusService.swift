import Foundation

public struct StatusService {
    private let label = "com.downloadorganizer.agent"

    public init() {}

    @discardableResult
    public func run() async -> Int32 {
        let status = await collectStatus()
        print(format(status))
        return status.isFatal ? 2 : 0
    }

    public func collectStatus() async -> AppStatus {
        let service = serviceStatus()
        let config = loadConfiguration()
        let watching = config.map { Paths.pathByAbbreviatingHome(Paths.expandingTilde($0.watchFolder)) } ?? "~/Downloads"

        await HistoryService.shared.start()
        await RuleEngine.shared.reloadRules()

        let movedToday = await HistoryService.shared.movedTodayCount()
        let databaseHealthy = await HistoryService.shared.isDatabaseHealthy()
        let retryQueue = await FileMover.shared.retryQueueCount()
        let activeQueue = await FileMover.shared.activeQueueCount()
        let rulesCount = await RuleEngine.shared.ruleCount()

        return AppStatus(
            isRunning: service.isRunning,
            pid: service.pid,
            watchFolder: watching,
            movedToday: movedToday,
            queueCount: retryQueue + activeQueue,
            rulesCount: rulesCount,
            databaseHealthy: databaseHealthy,
            memoryUsage: service.pid.flatMap { memoryUsage(pid: $0) },
            uptime: service.pid.flatMap { uptime(pid: $0) }
        )
    }

    private func loadConfiguration() -> AppConfiguration? {
        do {
            let data = try Data(contentsOf: Paths.configFile)
            return try JSONDecoder().decode(AppConfiguration.self, from: data)
        } catch {
            return nil
        }
    }

    private func serviceStatus() -> ServiceStatus {
        let process = Process()
        let pipe = Pipe()

        process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        process.arguments = ["print", "gui/\(getuid())/\(label)"]
        process.standardOutput = pipe
        process.standardError = pipe

        do {
            try process.run()
            process.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""

            guard process.terminationStatus == 0 else {
                return ServiceStatus(isRunning: false, pid: nil)
            }

            let pid = parsePID(from: output)
            let isRunning = output.contains("state = running")

            return ServiceStatus(isRunning: isRunning, pid: pid)
        } catch {
            return ServiceStatus(isRunning: false, pid: nil)
        }
    }

    private func parsePID(from output: String) -> Int32? {
        for line in output.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.hasPrefix("pid =") {
                let value = trimmed
                    .replacingOccurrences(of: "pid =", with: "")
                    .trimmingCharacters(in: .whitespaces)

                return Int32(value)
            }
        }

        return nil
    }

    private func memoryUsage(pid: Int32) -> String? {
        let process = Process()
        let pipe = Pipe()

        process.executableURL = URL(fileURLWithPath: "/bin/ps")
        process.arguments = ["-o", "rss=", "-p", "\(pid)"]
        process.standardOutput = pipe
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()

            guard process.terminationStatus == 0 else {
                return nil
            }

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

            guard let kilobytes = Double(output) else {
                return nil
            }

            let megabytes = kilobytes / 1024.0
            return String(format: "%.1f MB", megabytes)
        } catch {
            return nil
        }
    }

    private func uptime(pid: Int32) -> String? {
        let process = Process()
        let pipe = Pipe()

        process.executableURL = URL(fileURLWithPath: "/bin/ps")
        process.arguments = ["-o", "etime=", "-p", "\(pid)"]
        process.standardOutput = pipe
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()

            guard process.terminationStatus == 0 else {
                return nil
            }

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

            return formatUptime(output)
        } catch {
            return nil
        }
    }

    private func formatUptime(_ etime: String) -> String {
        let value = etime.trimmingCharacters(in: .whitespacesAndNewlines)

        if value.contains("-") {
            let parts = value.split(separator: "-", maxSplits: 1)
            let days = parts.first.map(String.init) ?? "0"
            let time = parts.dropFirst().first.map(String.init) ?? "00:00:00"
            let hours = time.split(separator: ":").first.map(String.init) ?? "0"
            return "\(days)d \(hours)h"
        }

        let parts = value.split(separator: ":").map(String.init)

        if parts.count == 3 {
            return "\(Int(parts[0]) ?? 0)h \(Int(parts[1]) ?? 0)m"
        }

        if parts.count == 2 {
            return "\(Int(parts[0]) ?? 0)m"
        }

        return value
    }

    private func format(_ status: AppStatus) -> String {
        let runningText = status.isRunning ? "Running" : "Not Running"
        let databaseText = status.databaseHealthy ? "Healthy" : "Unavailable"
        let memoryText = status.memoryUsage ?? "Unknown"
        let uptimeText = status.uptime ?? "Unknown"

        return """
        Status:
        \(runningText)

        Watching:
        \(status.watchFolder)

        Moved today:
        \(status.movedToday) files

        Queue:
        \(status.queueCount)

        Rules:
        \(status.rulesCount)

        Database:
        \(databaseText)

        Memory:
        \(memoryText)

        Uptime:
        \(uptimeText)
        """
    }
}

public struct AppStatus: Sendable {
    public let isRunning: Bool
    public let pid: Int32?
    public let watchFolder: String
    public let movedToday: Int
    public let queueCount: Int
    public let rulesCount: Int
    public let databaseHealthy: Bool
    public let memoryUsage: String?
    public let uptime: String?

    public var isFatal: Bool {
        !isRunning || !databaseHealthy
    }
}

private struct ServiceStatus {
    let isRunning: Bool
    let pid: Int32?
}