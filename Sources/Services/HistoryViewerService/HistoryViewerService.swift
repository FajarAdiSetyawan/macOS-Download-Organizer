import Foundation

public struct HistoryViewerService: Sendable {
    private let dateFormatter: DateFormatter

    public init() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        self.dateFormatter = formatter
    }

    @discardableResult
    public func run(options: HistoryOptions) async -> Int32 {
        do {
            try await ConfigurationManager.shared.bootstrap()
        } catch {
            printError("Failed to load configuration: \(error.localizedDescription)")
            return 2
        }

        await HistoryService.shared.start()

        let records = await HistoryService.shared.queryHistory(
            limit: options.limit,
            todayOnly: options.todayOnly,
            category: options.category,
            fileExtension: options.fileExtension
        )

        if records.isEmpty {
            printEmpty(options: options)
            return 0
        }

        printHeader(options: options, count: records.count)
        printSeparator()

        for record in records {
            printRecord(record)
            printSeparator()
        }

        printSummary(count: records.count, options: options)

        return 0
    }

    private func printHeader(options: HistoryOptions, count: Int) {
        print("")
        print("\(TerminalColor.cyan)Download Organizer - History\(TerminalColor.reset)")

        var filters: [String] = []

        if options.todayOnly {
            filters.append("today")
        }

        if let category = options.category {
            filters.append("category: \(category)")
        }

        if let ext = options.fileExtension {
            filters.append("extension: .\(ext)")
        }

        if !filters.isEmpty {
            print("\(TerminalColor.dim)Filters: \(filters.joined(separator: " · "))\(TerminalColor.reset)")
        }

        print("\(TerminalColor.dim)Showing \(count) record(s) · newest first\(TerminalColor.reset)")
        print("")
    }

    private func printRecord(_ record: MoveRecord) {
        let timestamp = dateFormatter.string(from: record.movedAt)
        let fileSize = formatFileSize(record.fileSize)
        let filename = record.filename
        let category = record.category
        let source = abbreviateHome(record.originalPath)
        let destination = abbreviateHome(record.destinationPath)

        print("\(TerminalColor.dim)\(timestamp)\(TerminalColor.reset)")
        print("\(TerminalColor.green)  \(filename)\(TerminalColor.reset) \(TerminalColor.dim)(\(fileSize))\(TerminalColor.reset)")
        print("  \(TerminalColor.cyan)Category:\(TerminalColor.reset)    \(category)")
        print("  \(TerminalColor.cyan)From:\(TerminalColor.reset)        \(source)")
        print("  \(TerminalColor.cyan)To:\(TerminalColor.reset)          \(destination)")
        print("  \(TerminalColor.cyan)Extension:\(TerminalColor.reset)   .\(record.fileExtension)")
        print("  \(TerminalColor.cyan)Status:\(TerminalColor.reset)      \(formatStatus(record.status))")
    }

    private func printSeparator() {
        print("\(TerminalColor.dim)──────────────────────────────────────────\(TerminalColor.reset)")
    }

    private func printSummary(count: Int, options: HistoryOptions) {
        print("")
        print("\(TerminalColor.dim)Total: \(count) record(s) · limit: \(options.limit)\(TerminalColor.reset)")
        print("")
    }

    private func printEmpty(options: HistoryOptions) {
        print("")
        print("\(TerminalColor.cyan)Download Organizer - History\(TerminalColor.reset)")
        print("\(TerminalColor.yellow)No records found.\(TerminalColor.reset)")

        if options.todayOnly {
            print("\(TerminalColor.dim)No files were organized today.\(TerminalColor.reset)")
        } else {
            print("\(TerminalColor.dim)The history database is empty or no matches found.\(TerminalColor.reset)")
        }

        print("")
    }

    private func printError(_ message: String) {
        print("\(TerminalColor.red)Error: \(message)\(TerminalColor.reset)")
    }

    private func formatStatus(_ status: String) -> String {
        switch status.lowercased() {
        case "moved":
            return "\(TerminalColor.green)moved\(TerminalColor.reset)"
        case "restored":
            return "\(TerminalColor.yellow)restored\(TerminalColor.reset)"
        case "failed":
            return "\(TerminalColor.red)failed\(TerminalColor.reset)"
        default:
            return "\(TerminalColor.dim)\(status)\(TerminalColor.reset)"
        }
    }

    private func formatFileSize(_ bytes: Int64) -> String {
        let kb = Double(bytes) / 1024.0
        let mb = kb / 1024.0
        let gb = mb / 1024.0

        if bytes == 0 {
            return "0 B"
        } else if gb >= 1 {
            return String(format: "%.2f GB", gb)
        } else if mb >= 1 {
            return String(format: "%.2f MB", mb)
        } else if kb >= 1 {
            return String(format: "%.2f KB", kb)
        } else {
            return "\(bytes) B"
        }
    }

    private func abbreviateHome(_ path: String) -> String {
        let homePath = FileManager.default.homeDirectoryForCurrentUser.path

        if path.hasPrefix(homePath) {
            return "~" + String(path.dropFirst(homePath.count))
        }

        return path
    }
}