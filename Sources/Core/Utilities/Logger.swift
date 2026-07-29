import Foundation

public enum LogLevel: String, Sendable {
    case info = "INFO"
    case warning = "WARNING"
    case error = "ERROR"
    case debug = "DEBUG"
}

public actor AppLogger {
    public static let shared = AppLogger()

    private let fileManager = FileManager.default
    private let maxRotatedLogFiles = 7

    public init() {}

    public func log(_ level: LogLevel, _ message: String) async {
        do {
            try fileManager.createDirectory(
                at: Paths.logsDirectory,
                withIntermediateDirectories: true
            )

            try rotateIfNeeded()

            let timestamp = ISO8601DateFormatter().string(from: Date())
            let line = "[\(timestamp)] [\(level.rawValue)] \(message)\n"
            let logFile = Paths.logsDirectory.appendingPathComponent(
                "download-organizer.log"
            )

            if !fileManager.fileExists(atPath: logFile.path) {
                try line.write(
                    to: logFile,
                    atomically: true,
                    encoding: .utf8
                )
                return
            }

            let handle = try FileHandle(forWritingTo: logFile)
            defer {
                try? handle.close()
            }

            try handle.seekToEnd()

            if let data = line.data(using: .utf8) {
                try handle.write(contentsOf: data)
            }
        } catch {
            fputs("DownloadOrganizer log error: \(error)\n", stderr)
        }
    }

    private func rotateIfNeeded() throws {
        let currentLog = Paths.logsDirectory.appendingPathComponent(
            "download-organizer.log"
        )

        guard fileManager.fileExists(atPath: currentLog.path) else {
            return
        }

        let attributes = try fileManager.attributesOfItem(
            atPath: currentLog.path
        )

        let modifiedDate = attributes[.modificationDate] as? Date ?? Date()

        guard !Calendar.current.isDateInToday(modifiedDate) else {
            return
        }

        let timestamp = ISO8601DateFormatter()
            .string(from: modifiedDate)
            .replacingOccurrences(of: ":", with: "-")

        let rotatedLog = Paths.logsDirectory.appendingPathComponent(
            "download-organizer-\(timestamp).log"
        )

        try? fileManager.moveItem(at: currentLog, to: rotatedLog)

        let rotatedLogs = try fileManager
            .contentsOfDirectory(
                at: Paths.logsDirectory,
                includingPropertiesForKeys: [.contentModificationDateKey]
            )
            .filter { url in
                url.lastPathComponent.hasPrefix("download-organizer-")
            }
            .sorted { left, right in
                let leftDate = try? left
                    .resourceValues(forKeys: [.contentModificationDateKey])
                    .contentModificationDate

                let rightDate = try? right
                    .resourceValues(forKeys: [.contentModificationDateKey])
                    .contentModificationDate

                return (leftDate ?? .distantPast) > (rightDate ?? .distantPast)
            }

        for logFile in rotatedLogs.dropFirst(maxRotatedLogFiles) {
            try? fileManager.removeItem(at: logFile)
        }
    }
}