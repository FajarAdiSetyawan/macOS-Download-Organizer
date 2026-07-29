import Foundation

public final class DownloadOrganizerService: @unchecked Sendable {
    private var fileWatcher: FSEventsWatcher?
    private var configWatcher: ConfigurationWatcher?
    private var rulesWatcher: ConfigurationWatcher?
    private var retryTask: Task<Void, Never>?
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