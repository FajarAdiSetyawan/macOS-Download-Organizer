import Foundation
import SQLite3

public actor SQLiteDatabase {
    public static let shared = SQLiteDatabase()

    private var db: OpaquePointer?

    public init() {}

    // MARK: - Lifecycle

    public func open() throws {
        try FileManager.default.createDirectory(
            at: Paths.baseDirectory,
            withIntermediateDirectories: true
        )

        let result = sqlite3_open(Paths.databaseFile.path, &db)

        guard result == SQLITE_OK else {
            throw makeError("Failed to open database, code: \(result)")
        }

        try enableWAL()
        try createSchema()
    }

    public enum SQLiteBindValue: Sendable {
        case text(String)
        case double(Double)
        case integer(Int64)
    }

    public func close() {
        guard db != nil else { return }
        sqlite3_close(db)
        db = nil
    }

    // MARK: - Schema

    private func enableWAL() throws {
        try execute("PRAGMA journal_mode=WAL;")
        try execute("PRAGMA synchronous=NORMAL;")
        try execute("PRAGMA foreign_keys=ON;")
    }

    private func createSchema() throws {
        try execute(
            """
            CREATE TABLE IF NOT EXISTS history (
                id              TEXT    PRIMARY KEY NOT NULL,
                filename        TEXT    NOT NULL,
                originalPath    TEXT    NOT NULL,
                destinationPath TEXT    NOT NULL,
                category        TEXT    NOT NULL,
                extension       TEXT    NOT NULL,
                fileSize        INTEGER NOT NULL DEFAULT 0,
                createdAt       REAL    NOT NULL,
                movedAt         REAL    NOT NULL,
                status          TEXT    NOT NULL DEFAULT 'moved'
            );
            """
        )

        try execute(
            """
            CREATE INDEX IF NOT EXISTS idx_history_status
            ON history (status);
            """
        )

        try execute(
            """
            CREATE INDEX IF NOT EXISTS idx_history_movedAt
            ON history (movedAt);
            """
        )

        try execute(
            """
            CREATE INDEX IF NOT EXISTS idx_history_category
            ON history (category);
            """
        )
    }

    // MARK: - Insert

    public func insert(_ record: MoveRecord) throws {
        let sql = """
            INSERT INTO history (
                id,
                filename,
                originalPath,
                destinationPath,
                category,
                extension,
                fileSize,
                createdAt,
                movedAt,
                status
            )
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
            """

        var statement: OpaquePointer?

        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw makeError("Failed to prepare insert statement")
        }

        defer {
            sqlite3_finalize(statement)
        }

        bindText(statement, index: 1, value: record.id.uuidString)
        bindText(statement, index: 2, value: record.filename)
        bindText(statement, index: 3, value: record.originalPath)
        bindText(statement, index: 4, value: record.destinationPath)
        bindText(statement, index: 5, value: record.category)
        bindText(statement, index: 6, value: record.fileExtension)
        sqlite3_bind_int64(statement, 7, record.fileSize)
        sqlite3_bind_double(statement, 8, record.createdAt.timeIntervalSince1970)
        sqlite3_bind_double(statement, 9, record.movedAt.timeIntervalSince1970)
        bindText(statement, index: 10, value: record.status)

        guard sqlite3_step(statement) == SQLITE_DONE else {
            throw makeError("Failed to execute insert")
        }
    }

    // MARK: - Queries

    public func lastMovedRecords(limit: Int = 10) throws -> [MoveRecord] {
        let sql = """
            SELECT
                id,
                filename,
                originalPath,
                destinationPath,
                category,
                extension,
                fileSize,
                createdAt,
                movedAt,
                status
            FROM history
            WHERE status = 'moved'
            ORDER BY movedAt DESC
            LIMIT ?;
            """

        var statement: OpaquePointer?

        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw makeError("Failed to prepare lastMovedRecords statement")
        }

        defer { sqlite3_finalize(statement) }

        sqlite3_bind_int(statement, 1, Int32(limit))

        var records: [MoveRecord] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            records.append(readRecord(from: statement))
        }
        return records
    }

    public func lastMovedRecord() throws -> MoveRecord? {
        let sql = """
            SELECT
                id,
                filename,
                originalPath,
                destinationPath,
                category,
                extension,
                fileSize,
                createdAt,
                movedAt,
                status
            FROM history
            WHERE status = 'moved'
            ORDER BY movedAt DESC
            LIMIT 1;
            """

        var statement: OpaquePointer?

        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw makeError("Failed to prepare lastMovedRecord statement")
        }

        defer {
            sqlite3_finalize(statement)
        }

        guard sqlite3_step(statement) == SQLITE_ROW else {
            return nil
        }

        return readRecord(from: statement)
    }

    public func movedTodayCount() throws -> Int {
        let startOfDay = Calendar.current.startOfDay(for: Date()).timeIntervalSince1970

        let sql = """
            SELECT COUNT(*)
            FROM history
            WHERE status = 'moved'
            AND movedAt >= ?;
            """

        var statement: OpaquePointer?

        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw makeError("Failed to prepare movedTodayCount statement")
        }

        defer {
            sqlite3_finalize(statement)
        }

        sqlite3_bind_double(statement, 1, startOfDay)

        guard sqlite3_step(statement) == SQLITE_ROW else {
            return 0
        }

        return Int(sqlite3_column_int(statement, 0))
    }

    public func queryHistory(
        limit: Int,
        todayOnly: Bool,
        category: String?,
        fileExtension: String?
    ) throws -> [MoveRecord] {
        var conditions: [String] = []
        var bindings: [(index: Int32, value: SQLiteBindValue)] = []
        var bindIndex: Int32 = 1

        if todayOnly {
            let startOfDay = Calendar.current
                .startOfDay(for: Date())
                .timeIntervalSince1970

            conditions.append("movedAt >= ?")
            bindings.append((index: bindIndex, value: .double(startOfDay)))
            bindIndex += 1
        }

        if let category {
            conditions.append("category = ?")
            bindings.append((index: bindIndex, value: .text(category)))
            bindIndex += 1
        }

        if let fileExtension {
            conditions.append("extension = ?")
            bindings.append((index: bindIndex, value: .text(fileExtension.lowercased())))
            bindIndex += 1
        }

        let whereClause = conditions.isEmpty
            ? ""
            : "WHERE " + conditions.joined(separator: " AND ")

        let sql = """
            SELECT
                id,
                filename,
                originalPath,
                destinationPath,
                category,
                extension,
                fileSize,
                createdAt,
                movedAt,
                status
            FROM history
            \(whereClause)
            ORDER BY movedAt DESC
            LIMIT ?;
            """

        var statement: OpaquePointer?

        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw makeError("Failed to prepare queryHistory statement")
        }

        defer { sqlite3_finalize(statement) }

        for binding in bindings {
            switch binding.value {
            case .text(let value):
                bindText(statement, index: binding.index, value: value)
            case .double(let value):
                sqlite3_bind_double(statement, binding.index, value)
            case .integer(let value):
                sqlite3_bind_int64(statement, binding.index, value)
            }
        }

        sqlite3_bind_int(statement, bindIndex, Int32(limit))

        var records: [MoveRecord] = []

        while sqlite3_step(statement) == SQLITE_ROW {
            records.append(readRecord(from: statement))
        }

        return records
    }

    public func allRecords(
        limit: Int = 100,
        offset: Int = 0
    ) throws -> [MoveRecord] {
        let sql = """
            SELECT
                id,
                filename,
                originalPath,
                destinationPath,
                category,
                extension,
                fileSize,
                createdAt,
                movedAt,
                status
            FROM history
            ORDER BY movedAt DESC
            LIMIT ? OFFSET ?;
            """

        var statement: OpaquePointer?

        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw makeError("Failed to prepare allRecords statement")
        }

        defer {
            sqlite3_finalize(statement)
        }

        sqlite3_bind_int(statement, 1, Int32(limit))
        sqlite3_bind_int(statement, 2, Int32(offset))

        var records: [MoveRecord] = []

        while sqlite3_step(statement) == SQLITE_ROW {
            records.append(readRecord(from: statement))
        }

        return records
    }

    public func categoryStats() throws -> [(category: String, count: Int, totalSize: Int64)] {
        let sql = """
            SELECT category, COUNT(*) as total, SUM(fileSize) as totalSize
            FROM history
            WHERE status = 'moved'
            GROUP BY category
            ORDER BY total DESC;
            """

        var statement: OpaquePointer?

        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw makeError("Failed to prepare categoryStats statement")
        }

        defer {
            sqlite3_finalize(statement)
        }

        var result: [(category: String, count: Int, totalSize: Int64)] = []

        while sqlite3_step(statement) == SQLITE_ROW {
            let category = columnText(from: statement, index: 0)
            let count = Int(sqlite3_column_int(statement, 1))
            let totalSize = Int64(sqlite3_column_int64(statement, 2))
            result.append((category, count, totalSize))
        }

        return result
    }

    public func statistics() throws -> [String: Int] {
        let sql = """
            SELECT category, COUNT(*) as total
            FROM history
            WHERE status = 'moved'
            GROUP BY category
            ORDER BY total DESC;
            """

        var statement: OpaquePointer?

        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw makeError("Failed to prepare statistics statement")
        }

        defer {
            sqlite3_finalize(statement)
        }

        var result: [String: Int] = [:]

        while sqlite3_step(statement) == SQLITE_ROW {
            let category = columnText(from: statement, index: 0)
            let count = Int(sqlite3_column_int(statement, 1))
            result[category] = count
        }

        return result
    }

    public func totalMoved() throws -> Int {
        let sql = """
            SELECT COUNT(*) FROM history WHERE status = 'moved';
            """

        var statement: OpaquePointer?

        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw makeError("Failed to prepare totalMoved statement")
        }

        defer {
            sqlite3_finalize(statement)
        }

        guard sqlite3_step(statement) == SQLITE_ROW else {
            return 0
        }

        return Int(sqlite3_column_int(statement, 0))
    }

    // MARK: - Updates

    public func markRestored(id: UUID) throws {
        let sql = """
            UPDATE history
            SET status = 'restored'
            WHERE id = ?;
            """

        var statement: OpaquePointer?

        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw makeError("Failed to prepare markRestored statement")
        }

        defer {
            sqlite3_finalize(statement)
        }

        bindText(statement, index: 1, value: id.uuidString)

        guard sqlite3_step(statement) == SQLITE_DONE else {
            throw makeError("Failed to execute markRestored")
        }
    }

    public func markFailed(id: UUID) throws {
        let sql = """
            UPDATE history
            SET status = 'failed'
            WHERE id = ?;
            """

        var statement: OpaquePointer?

        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw makeError("Failed to prepare markFailed statement")
        }

        defer {
            sqlite3_finalize(statement)
        }

        bindText(statement, index: 1, value: id.uuidString)

        guard sqlite3_step(statement) == SQLITE_DONE else {
            throw makeError("Failed to execute markFailed")
        }
    }

    // MARK: - Execute

    private func execute(_ sql: String) throws {
        var errorPointer: UnsafeMutablePointer<Int8>?

        let result = sqlite3_exec(db, sql, nil, nil, &errorPointer)

        if result != SQLITE_OK {
            let message = errorPointer.map { String(cString: $0) } ?? "Unknown error"
            sqlite3_free(errorPointer)
            throw makeError(message)
        }
    }

    // MARK: - Helpers

    private func readRecord(from statement: OpaquePointer?) -> MoveRecord {
        MoveRecord(
            id: UUID(uuidString: columnText(from: statement, index: 0)) ?? UUID(),
            filename: columnText(from: statement, index: 1),
            originalPath: columnText(from: statement, index: 2),
            destinationPath: columnText(from: statement, index: 3),
            category: columnText(from: statement, index: 4),
            fileExtension: columnText(from: statement, index: 5),
            fileSize: sqlite3_column_int64(statement, 6),
            createdAt: Date(
                timeIntervalSince1970: sqlite3_column_double(statement, 7)
            ),
            movedAt: Date(
                timeIntervalSince1970: sqlite3_column_double(statement, 8)
            ),
            status: columnText(from: statement, index: 9)
        )
    }

    private func bindText(
        _ statement: OpaquePointer?,
        index: Int32,
        value: String
    ) {
        // Use unsafeBitCast to get SQLITE_TRANSIENT equivalent
        let transient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
        sqlite3_bind_text(statement, index, value, -1, transient)
    }

    private func columnText(
        from statement: OpaquePointer?,
        index: Int32
    ) -> String {
        guard let pointer = sqlite3_column_text(statement, index) else {
            return ""
        }

        return String(cString: pointer)
    }

    private func makeError(_ message: String) -> NSError {
        NSError(
            domain: "DownloadOrganizer.SQLiteDatabase",
            code: Int(sqlite3_errcode(db)),
            userInfo: [NSLocalizedDescriptionKey: message]
        )
    }
}