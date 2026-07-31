import Foundation

public final class DownloadOrganizerService: @unchecked Sendable {
    private var fileWatcher: FSEventsWatcher?
    private var additionalFileWatcher: FSEventsWatcher?
    private var configWatcher: ConfigurationWatcher?
    private var rulesWatcher: ConfigurationWatcher?
    private var retryTask: Task<Void, Never>?
    private var summaryTask: Task<Void, Never>?
    private let shutdownFlag: UnsafeMutablePointer<Bool>

    public init() {
        shutdownFlag = UnsafeMutablePointer<Bool>.allocate(capacity: 1)
        shutdownFlag.initialize(to: false)
    }

    deinit {
        shutdownFlag.deinitialize(count: 1)
        shutdownFlag.deallocate()
    }

    public func start() async {
        do {
            try await ConfigurationManager.shared.bootstrap()
            try FileManager.default.createDirectory(
                at: Paths.logsDirectory,
                withIntermediateDirectories: true
            )
        } catch {
            await AppLogger.shared.log(.error, "Bootstrap failed: \(error)")
        }

        await HistoryService.shared.start()
        await RuleEngine.shared.reloadRules()
        await NotificationService.shared.requestPermission()

        await createDefaultFolders()
        await startWatchers()
        startRetryLoop()
        startDailySummaryLoop()
        installSignalHandlers()

        await AppLogger.shared.log(.info, "Download Organizer started")

        // Keep running forever until shutdown
        while !shutdownFlag.pointee {
            try? await Task.sleep(for: .seconds(60))
        }

        await AppLogger.shared.log(.info, "Download Organizer shutting down gracefully")
    }

    private func startWatchers() async {
        let config = await ConfigurationManager.shared.current()
        let watchFolder = Paths.expandingTilde(config.watchFolder)

        fileWatcher = FSEventsWatcher(path: watchFolder) { url in
            Task {
                await FileMover.shared.enqueue(url)
            }
        }
        fileWatcher?.start()

        // Start additional watcher if configured
        if let additionalFolder = config.additionalWatchFolder, !additionalFolder.isEmpty {
            let additionalPath = Paths.expandingTilde(additionalFolder)
            additionalFileWatcher = FSEventsWatcher(path: additionalPath) { url in
                Task {
                    await FileMover.shared.enqueue(url)
                }
            }
            additionalFileWatcher?.start()
            await AppLogger.shared.log(.info, "Watching additional folder: \(additionalFolder)")
        }

        configWatcher = ConfigurationWatcher(url: Paths.configFile) {
            Task {
                await ConfigurationManager.shared.reload()
            }
        }
        configWatcher?.start()

        rulesWatcher = ConfigurationWatcher(url: Paths.rulesFile) {
            Task {
                await RuleEngine.shared.reloadRules()
            }
        }
        rulesWatcher?.start()
    }

    private func createDefaultFolders() async {
        let config = await ConfigurationManager.shared.current()

        guard config.autoCreateFolders else {
            return
        }

        let root = Paths.expandingTilde(config.watchFolder)

        for category in FileCategory.allCases {
            do {
                try FileManager.default.createDirectory(
                    at: root.appendingPathComponent(category.rawValue, isDirectory: true),
                    withIntermediateDirectories: true
                )
            } catch {
                await AppLogger.shared.log(
                    .warning,
                    "Failed creating \(category.rawValue): \(error)"
                )
            }
        }
    }

    private func startRetryLoop() {
        retryTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(30))
                await FileMover.shared.retryPending()
            }
        }
    }

    private func startDailySummaryLoop() {
        summaryTask = Task {
            while !Task.isCancelled {
                // Check every hour
                try? await Task.sleep(for: .seconds(3600))
                await checkAndSendDailySummary()
            }
        }
    }

    private func checkAndSendDailySummary() async {
        let config = await ConfigurationManager.shared.current()
        guard config.dailySummary && config.notifications else { return }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let today = dateFormatter.string(from: Date())
        
        // Check if we already sent summary today
        if config.lastSummaryDate == today {
            return
        }
        
        // Send summary
        let stats = await HistoryService.shared.statistics()
        let totalMoved = stats.values.reduce(0, +)
        
        await NotificationService.shared.sendSummary(movedCount: totalMoved, categories: stats)
        
        // Update last summary date
        do {
            try await ConfigurationManager.shared.update { configuration in
                configuration.lastSummaryDate = today
            }
        } catch {
            await AppLogger.shared.log(.error, "Failed to update lastSummaryDate: \(error.localizedDescription)")
        }
    }

    private func installSignalHandlers() {
        signal(SIGTERM, SIG_IGN)
        signal(SIGINT, SIG_IGN)

        let signalQueue = DispatchQueue(label: "com.downloadorganizer.signals")
        let shutdownPtr = shutdownFlag

        for signalNumber in [SIGTERM, SIGINT] {
            let source = DispatchSource.makeSignalSource(
                signal: signalNumber,
                queue: signalQueue
            )

            source.setEventHandler {
                shutdownPtr.pointee = true
                Task {
                    await AppLogger.shared.log(.info, "Shutdown signal received")
                }
            }

            source.resume()
        }
    }
}