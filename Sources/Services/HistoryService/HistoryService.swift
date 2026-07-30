import Foundation

public actor HistoryService {
    public static let shared = HistoryService()

    private let database = SQLiteDatabase.shared
    private var isOpen = false

    public init() {}

    // MARK: - Lifecycle

    public func start() async {
        guard !isOpen else { return }

        do {
            try await database.open()
            isOpen = true
            await AppLogger.shared.log(.info, "History database opened")
        } catch {
            await AppLogger.shared.log(
                .error,
                "Failed to open history database: \(error.localizedDescription)"
            )
        }
    }

    public func stop() async {
        guard isOpen else { return }
        await database.close()
        isOpen = false
        await AppLogger.shared.log(.info, "History database closed")
    }

    // MARK: - Record

    public func record(_ moveRecord: MoveRecord) async {
        guard isOpen else {
            await AppLogger.shared.log(
                .warning,
                "History database is not open, skipping record"
            )
            return
        }

        do {
            try await database.insert(moveRecord)
            await AppLogger.shared.log(
                .debug,
                "Recorded: \(moveRecord.filename) → \(moveRecord.category)"
            )
        } catch {
            await AppLogger.shared.log(
                .error,
                "Failed to record history: \(error.localizedDescription)"
            )
        }
    }

    // MARK: - Undo

    public func undoLastMoves(count: Int) async -> Int {
        guard isOpen else {
            await AppLogger.shared.log(.warning, "History database is not open")
            return 0
        }

        var undone = 0
        do {
            let records = try await database.lastMovedRecords(limit: count)
            for record in records {
                let source = URL(fileURLWithPath: record.destinationPath)
                let originalDir = URL(fileURLWithPath: record.originalPath)
                    .deletingLastPathComponent()

                guard FileManager.default.fileExists(atPath: source.path) else {
                    await AppLogger.shared.log(.warning, "Bulk undo: file no longer exists at \(source.path)")
                    continue
                }

                try FileManager.default.createDirectory(
                    at: originalDir,
                    withIntermediateDirectories: true
                )

                let finalDestination = DuplicateNameResolver.destination(
                    for: source,
                    in: originalDir
                )

                try FileManager.default.moveItem(at: source, to: finalDestination)
                try await database.markRestored(id: record.id)
                undone += 1
            }
            await AppLogger.shared.log(.info, "Bulk undo completed: \(undone) file(s) restored")
        } catch {
            await AppLogger.shared.log(.error, "Bulk undo failed: \(error.localizedDescription)")
        }
        return undone
    }

    public func undoLastMove() async {
        guard isOpen else {
            await AppLogger.shared.log(
                .warning,
                "History database is not open"
            )
            return
        }

        do {
            guard let record = try await database.lastMovedRecord() else {
                await AppLogger.shared.log(
                    .warning,
                    "No move record found to undo"
                )
                return
            }

            let source = URL(fileURLWithPath: record.destinationPath)
            let originalDir = URL(fileURLWithPath: record.originalPath)
                .deletingLastPathComponent()

            guard FileManager.default.fileExists(atPath: source.path) else {
                await AppLogger.shared.log(
                    .error,
                    "Undo failed: file no longer exists at \(source.path)"
                )
                return
            }

            try FileManager.default.createDirectory(
                at: originalDir,
                withIntermediateDirectories: true
            )

            let finalDestination = DuplicateNameResolver.destination(
                for: source,
                in: originalDir
            )

            try FileManager.default.moveItem(at: source, to: finalDestination)
            try await database.markRestored(id: record.id)

            await AppLogger.shared.log(
                .info,
                "Undo successful: \(source.path) → \(finalDestination.path)"
            )
        } catch {
            await AppLogger.shared.log(
                .error,
                "Undo failed: \(error.localizedDescription)"
            )
        }
    }

    // MARK: - Statistics

    public func statistics() async -> [String: Int] {
        guard isOpen else {
            return [:]
        }

        do {
            return try await database.statistics()
        } catch {
            await AppLogger.shared.log(
                .error,
                "Failed to fetch statistics: \(error.localizedDescription)"
            )
            return [:]
        }
    }

    public func totalMoved() async -> Int {
        guard isOpen else {
            return 0
        }

        do {
            return try await database.totalMoved()
        } catch {
            await AppLogger.shared.log(
                .error,
                "Failed to fetch total moved: \(error.localizedDescription)"
            )
            return 0
        }
    }

    // MARK: - All Records

    public func allRecords(
        limit: Int = 100,
        offset: Int = 0
    ) async -> [MoveRecord] {
        guard isOpen else {
            return []
        }

        do {
            return try await database.allRecords(limit: limit, offset: offset)
        } catch {
            await AppLogger.shared.log(
                .error,
                "Failed to fetch records: \(error.localizedDescription)"
            )
            return []
        }
    }

    public func movedTodayCount() async -> Int {
        guard isOpen else {
            return 0
        }

        do {
            return try await database.movedTodayCount()
        } catch {
            await AppLogger.shared.log(
                .error,
                "Failed to fetch moved today count: \(error.localizedDescription)"
            )
            return 0
        }
    }

    public func queryHistory(
        limit: Int = 50,
        todayOnly: Bool = false,
        category: String? = nil,
        fileExtension: String? = nil
    ) async -> [MoveRecord] {
        guard isOpen else {
            return []
        }

        do {
            return try await database.queryHistory(
                limit: limit,
                todayOnly: todayOnly,
                category: category,
                fileExtension: fileExtension
            )
        } catch {
            await AppLogger.shared.log(
                .error,
                "Failed to query history: \(error.localizedDescription)"
            )
            return []
        }
    }

    public func isDatabaseHealthy() async -> Bool {
        guard isOpen else {
            return false
        }

        do {
            _ = try await database.totalMoved()
            return true
        } catch {
            return false
        }
    }
}