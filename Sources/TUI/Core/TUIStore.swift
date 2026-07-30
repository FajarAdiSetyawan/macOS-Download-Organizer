@preconcurrency import SwiftTUI
import Foundation

public final class TUIStore: ObservableObject, @unchecked Sendable {
    public static let shared = TUIStore()

    @Published public var serviceRunning: Bool = false
    @Published public var watchFolder: String = "~/Downloads"
    @Published public var movedToday: Int = 0
    @Published public var queueCount: Int = 0
    @Published public var rulesCount: Int = 0
    @Published public var memoryUsage: String = "..."
    @Published public var cpuUsage: String = "0.0%"
    @Published public var uptime: String = "..."
    @Published public var databaseHealthy: Bool = false
    @Published public var recentRecords: [MoveRecord] = []
    @Published public var allRecords: [MoveRecord] = []
    @Published public var statistics: [String: Int] = [:]
    @Published public var configuration: AppConfiguration = .default
    @Published public var logLines: [String] = []
    @Published public var doctorChecks: [DoctorCheck] = []
    @Published public var rulesDisplay: [RuleDisplay] = []
    @Published public var isLoading: Bool = false
    @Published public var autoRefresh: Bool = true
    @Published public var refreshTimestamp: Date = .distantPast

    public var lastRefreshAgo: String {
        let elapsed = -refreshTimestamp.timeIntervalSinceNow
        if elapsed < 60 { return "\(Int(elapsed))s ago" }
        return "\(Int(elapsed / 60))m ago"
    }

    private var refreshTask: Task<Void, Never>?
    private var refreshCount: Int = 0

    private init() {}

    public func bootstrap() async {
        do {
            try await ConfigurationManager.shared.bootstrap()
            await HistoryService.shared.start()
            await RuleEngine.shared.reloadRules()
        } catch {}
    }

    public func refresh() async {
        isLoading = true
        refreshCount += 1
        defer {
            isLoading = false
            refreshTimestamp = Date()
        }

        async let status: Void = refreshStatus()
        async let records: Void = refreshRecords()
        async let stats: Void = refreshStatistics()
        async let config: Void = refreshConfiguration()
        async let rls: Void = refreshRules()

        let _ = await (status, records, stats, config, rls)

        if refreshCount.isMultiple(of: 3) {
            refreshLogs()
        }
    }

    public func startAutoRefresh() {
        refreshTask?.cancel()
        refreshTask = Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(5))
                guard self.autoRefresh else { continue }
                await self.refresh()
            }
        }
    }

    public func stopAutoRefresh() {
        refreshTask?.cancel()
        refreshTask = nil
    }

    public func toggleAutoRefresh() {
        autoRefresh.toggle()
    }

    private func refreshStatus() async {
        let status = await StatusService().collectStatus()
        serviceRunning = status.isRunning
        watchFolder = status.watchFolder
        movedToday = status.movedToday
        queueCount = status.queueCount
        rulesCount = status.rulesCount
        memoryUsage = status.memoryUsage ?? "N/A"
        uptime = status.uptime ?? "N/A"
        databaseHealthy = status.databaseHealthy
    }

    private func refreshRecords() async {
        recentRecords = await HistoryService.shared.queryHistory(limit: 10)
        allRecords = await HistoryService.shared.queryHistory(limit: 200)
    }

    private func refreshStatistics() async {
        statistics = await HistoryService.shared.statistics()
    }

    private func refreshConfiguration() async {
        configuration = await ConfigurationManager.shared.current()
    }

    private func refreshLogs() {
        let logFile = Paths.logsDirectory
            .appendingPathComponent("download-organizer.log")

        guard let data = try? Data(contentsOf: logFile),
              let content = String(data: data, encoding: .utf8) else {
            logLines = ["No logs found"]
            return
        }

        logLines = content
            .components(separatedBy: .newlines)
            .filter { !$0.isEmpty }
            .suffix(200)
    }

    public func runDoctorChecks() async {
        doctorChecks = await DoctorService().runChecks()
    }

    public func saveConfiguration(_ config: AppConfiguration) async {
        do {
            try await ConfigurationManager.shared.save(config)
            configuration = config
        } catch {}
    }

    public func clearDoctorChecks() {
        doctorChecks = []
    }

    public func toggleConfig(_ key: String) async {
        var c = configuration
        switch key {
        case "Enabled": c.enabled.toggle()
        case "Notifications": c.notifications.toggle()
        case "Auto-create Folders": c.autoCreateFolders.toggle()
        case "History": c.history.toggle()
        default: return
        }
        await saveConfiguration(c)
    }

    public func updateConfig(_ key: String, value: String) async {
        var c = configuration
        switch key {
        case "Watch Folder": c.watchFolder = value
        case "Delay":
            let sanitized = value
                .filter { $0.isNumber || $0 == "." }
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if let seconds = Double(sanitized), seconds >= 0 {
                c.delay = seconds
            }
        case "Duplicate Strategy": c.duplicateStrategy = value
        default: return
        }
        await saveConfiguration(c)
    }

    public func cycleDuplicateStrategy() async {
        let current = configuration.parsedDuplicateStrategy
        let all = DuplicateStrategy.allCases
        let next = all[(all.firstIndex(of: current) ?? 0 + 1) % all.count]
        await updateConfig("Duplicate Strategy", value: next.rawValue)
    }

    public func exportConfig(to url: URL) async throws {
        let data = try JSONEncoder().encode(configuration)
        try data.write(to: url, options: .atomic)
    }

    public func organizeNow() async -> String {
        let watchFolder = Paths.expandingTilde(configuration.watchFolder)
        let count = await FileMover.shared.organizeFolder(at: watchFolder)
        await refresh()
        return "Organized \(count) file(s)"
    }

    public func undoLastMove() async -> String {
        await HistoryService.shared.undoLastMove()
        await refresh()
        return "Undo completed"
    }

    public func undoLastMoves(count: Int) async -> String {
        let undone = await HistoryService.shared.undoLastMoves(count: count)
        await refresh()
        return "Undid \(undone) file(s)"
    }

    public func backupAllData(to url: URL) async throws {
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        let configSrc = Paths.configFile
        let rulesSrc = Paths.rulesFile
        if FileManager.default.fileExists(atPath: configSrc.path) {
            let dest = url.appendingPathComponent("config.json")
            try FileManager.default.copyItem(at: configSrc, to: dest)
        }
        if FileManager.default.fileExists(atPath: rulesSrc.path) {
            let dest = url.appendingPathComponent("rules.json")
            try FileManager.default.copyItem(at: rulesSrc, to: dest)
        }
    }

    public func restoreAllData(from url: URL) async throws {
        let configSrc = url.appendingPathComponent("config.json")
        let rulesSrc = url.appendingPathComponent("rules.json")
        if FileManager.default.fileExists(atPath: configSrc.path) {
            try? FileManager.default.removeItem(at: Paths.configFile)
            try FileManager.default.copyItem(at: configSrc, to: Paths.configFile)
            let data = try Data(contentsOf: Paths.configFile)
            let decoded = try JSONDecoder().decode(AppConfiguration.self, from: data)
            var c = decoded
            if c.watchFolder.isEmpty { c.watchFolder = "~/Downloads" }
            try await ConfigurationManager.shared.save(c)
            configuration = c
        }
        if FileManager.default.fileExists(atPath: rulesSrc.path) {
            try? FileManager.default.removeItem(at: Paths.rulesFile)
            try FileManager.default.copyItem(at: rulesSrc, to: Paths.rulesFile)
            await RuleEngine.shared.reloadRules()
            await refreshRulesDisplay()
        }
    }

    public func importConfig(from url: URL) async throws {
        let data = try Data(contentsOf: url)
        let decoded = try JSONDecoder().decode(AppConfiguration.self, from: data)
        var c = decoded
        if c.watchFolder.isEmpty { c.watchFolder = "~/Downloads" }
        try await ConfigurationManager.shared.save(c)
        configuration = c
    }

    // MARK: - Rule Editing

    public func refreshRulesDisplay() async {
        let engine = RuleEngine.shared
        let cats = await engine.allCategories()
        var result: [RuleDisplay] = []
        for cat in cats {
            let exts = await engine.extensionsForDisplay(category: cat)
            if !exts.isEmpty {
                result.append(RuleDisplay(
                    id: cat,
                    name: cat,
                    pattern: exts.joined(separator: ", "),
                    category: cat,
                    destination: "~/Downloads/\(cat)",
                    enabled: true
                ))
            }
        }
        rulesDisplay = result
        _ = await engine.extensions(for: .others)
    }

    public func updateRuleExtensions(category: String, extensions: String) async {
        let list = extensions
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        await RuleEngine.shared.setCustomRule(category: category, extensions: list)
        await refreshRulesDisplay()
    }

    public func addCustomRule(category: String, extensions: String) async {
        let list = extensions
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        await RuleEngine.shared.setCustomRule(category: category, extensions: list)
        await refreshRulesDisplay()
    }

    public func removeCustomRule(category: String) async {
        await RuleEngine.shared.removeCustomRule(category: category)
        await refreshRulesDisplay()
    }

    public func resetRulesToDefaults() async {
        await RuleEngine.shared.resetToDefaults()
        await refreshRulesDisplay()
    }

    private func refreshRules() async {
        await refreshRulesDisplay()
    }

    public var configEntries: [ConfigEntry] {
        let c = configuration
        let strategy = c.parsedDuplicateStrategy
        return [
            ConfigEntry(key: "Enabled", value: c.enabled ? "true" : "false", type: "Bool"),
            ConfigEntry(key: "Watch Folder", value: c.watchFolder, type: "Path"),
            ConfigEntry(key: "Delay", value: "\(Int(c.delay))s", type: "Seconds"),
            ConfigEntry(key: "Notifications", value: c.notifications ? "on" : "off", type: "Bool"),
            ConfigEntry(key: "Auto-create Folders", value: c.autoCreateFolders ? "on" : "off", type: "Bool"),
            ConfigEntry(key: "Duplicate Strategy", value: "\(strategy.label) (\(strategy.description))", type: "Select"),
            ConfigEntry(key: "History", value: c.history ? "enabled" : "disabled", type: "Bool"),
        ]
    }

}

public struct ConfigEntry: Sendable {
    public let key: String
    public let value: String
    public let type: String
    public init(key: String, value: String, type: String) {
        self.key = key
        self.value = value
        self.type = type
    }
}

public struct RuleDisplay: Sendable, Identifiable {
    public let id: String
    public let name: String
    public let pattern: String
    public let category: String
    public let destination: String
    public let enabled: Bool
    public init(id: String, name: String, pattern: String, category: String, destination: String, enabled: Bool) {
        self.id = id
        self.name = name
        self.pattern = pattern
        self.category = category
        self.destination = destination
        self.enabled = enabled
    }
}
