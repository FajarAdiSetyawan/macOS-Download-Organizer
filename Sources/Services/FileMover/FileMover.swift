import Foundation

public actor FileMover {
    public static let shared = FileMover()

    private var activeQueue: Set<URL> = []
    private var retryQueue: Set<URL> = []

    public init() {}

    // MARK: - Enqueue

    public func enqueue(_ url: URL) async {
        guard !activeQueue.contains(url) else { return }
        guard !retryQueue.contains(url) else { return }
        guard FileUtilities.isCandidateForMove(url) else { return }

        activeQueue.insert(url)

        // Process immediately in detached task
        Task.detached {
            await self.processFile(url)
        }
    }

    // MARK: - Process

    private func processFile(_ url: URL) async {
        defer {
            Task {
                await self.removeFromActive(url)
            }
        }

        let config = await ConfigurationManager.shared.current()

        guard config.enabled else { return }
        guard FileManager.default.fileExists(atPath: url.path) else { return }

        let stable = await waitUntilStable(url, delay: config.delay, maxAttempts: 10)

        guard stable else {
            await addToRetry(url)
            await AppLogger.shared.log(.warning, "File not stable: \(url.lastPathComponent)")
            return
        }

        do {
            try await moveFile(url, config: config)
        } catch {
            await addToRetry(url)
            await AppLogger.shared.log(.error, "Move failed: \(url.lastPathComponent) - \(error.localizedDescription)")
        }
    }

    private func removeFromActive(_ url: URL) {
        activeQueue.remove(url)
    }

    private func addToRetry(_ url: URL) {
        retryQueue.insert(url)
    }

    // MARK: - Stability

    private func waitUntilStable(_ url: URL, delay: TimeInterval, maxAttempts: Int) async -> Bool {
        var previousSize: Int64 = -1
        var stableCount = 0

        for _ in 1...maxAttempts {
            guard FileManager.default.fileExists(atPath: url.path) else { return false }
            guard FileUtilities.isCandidateForMove(url) else {
                try? await Task.sleep(for: .seconds(delay))
                continue
            }

            let currentSize = FileUtilities.fileSize(url)

            if currentSize > 0 && currentSize == previousSize {
                stableCount += 1
                if stableCount >= 2 {
                    return true
                }
            } else {
                stableCount = 0
            }

            previousSize = currentSize
            try? await Task.sleep(for: .seconds(delay))
        }

        return false
    }

    // MARK: - Move

    private func moveFile(_ url: URL, config: AppConfiguration) async throws {
        let watchFolder = Paths.expandingTilde(config.watchFolder)
        let fileExtension = url.pathExtension.lowercased()
        let categoryName = await RuleEngine.shared.categoryName(forExtension: fileExtension)
        let destinationFolder = watchFolder.appendingPathComponent(categoryName, isDirectory: true)

        if config.autoCreateFolders {
            try FileManager.default.createDirectory(at: destinationFolder, withIntermediateDirectories: true)
        }

        guard FileManager.default.fileExists(atPath: destinationFolder.path) else {
            throw NSError(domain: "FileMover", code: 1, userInfo: [NSLocalizedDescriptionKey: "Destination unavailable"])
        }

        let strategy = config.parsedDuplicateStrategy

        if DuplicateNameResolver.shouldSkip(for: url, in: destinationFolder, strategy: strategy) {
            await AppLogger.shared.log(.info, "Skipped (duplicate): \(url.lastPathComponent)")
            return
        }

        let destination = DuplicateNameResolver.destination(for: url, in: destinationFolder, strategy: strategy)
        let originalSize = FileUtilities.fileSize(url)

        if strategy == .overwrite {
            try? FileManager.default.removeItem(at: destination)
        }

        try FileManager.default.moveItem(at: url, to: destination)

        let record = MoveRecord(
            filename: url.lastPathComponent,
            originalPath: url.path,
            destinationPath: destination.path,
            category: categoryName,
            fileExtension: fileExtension,
            fileSize: originalSize,
            createdAt: Date(),
            movedAt: Date(),
            status: "moved"
        )

        if config.history {
            await HistoryService.shared.record(record)
        }

        await NotificationService.shared.notifyMoved(
            filename: url.lastPathComponent,
            destination: "Downloads/\(categoryName)",
            enabled: config.notifications
        )

        await AppLogger.shared.log(.info, "Moved: \(url.lastPathComponent) → \(categoryName)/")
    }

    public func organizeFolder(at url: URL) async -> Int {
        let fm = FileManager.default
        guard let contents = try? fm.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.isRegularFileKey]
        ) else { return 0 }

        var count = 0
        for fileURL in contents {
            let isRegular = (try? fileURL.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile) ?? false
            guard isRegular, FileUtilities.isCandidateForMove(fileURL) else { continue }
            await enqueue(fileURL)
            count += 1
        }
        await AppLogger.shared.log(.info, "Organize now: \(count) files queued from \(url.path)")
        return count
    }

    public func retryQueueCount() -> Int {
        retryQueue.count
    }

    public func activeQueueCount() -> Int {
        activeQueue.count
    }
    

    // MARK: - Retry

    public func retryPending() async {
        let pending = retryQueue
        retryQueue.removeAll()

        for url in pending {
            await enqueue(url)
        }
    }
}