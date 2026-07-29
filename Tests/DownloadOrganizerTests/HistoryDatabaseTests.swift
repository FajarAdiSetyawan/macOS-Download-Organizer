import Foundation
import Testing

@testable import DownloadOrganizer

@Suite("HistoryDatabase Tests")
struct HistoryDatabaseTests {

    // MARK: - MoveRecord Model

    @Test("Creates MoveRecord with correct values")
    func createsMoveRecordWithCorrectValues() {
        let id = UUID()
        let now = Date()

        let record = MoveRecord(
            id: id,
            filename: "document.pdf",
            originalPath: "/Users/user/Downloads/document.pdf",
            destinationPath: "/Users/user/Downloads/PDF/document.pdf",
            category: "PDF",
            fileExtension: "pdf",
            fileSize: 204_800,
            createdAt: now,
            movedAt: now,
            status: "moved"
        )

        #expect(record.id == id)
        #expect(record.filename == "document.pdf")
        #expect(record.originalPath == "/Users/user/Downloads/document.pdf")
        #expect(record.destinationPath == "/Users/user/Downloads/PDF/document.pdf")
        #expect(record.category == "PDF")
        #expect(record.fileExtension == "pdf")
        #expect(record.fileSize == 204_800)
        #expect(record.status == "moved")
    }

    @Test("Creates MoveRecord with auto-generated UUID")
    func createsMoveRecordWithAutoUUID() {
        let record = MoveRecord(
            filename: "photo.jpg",
            originalPath: "/Downloads/photo.jpg",
            destinationPath: "/Downloads/Images/photo.jpg",
            category: "Images",
            fileExtension: "jpg",
            fileSize: 1024,
            createdAt: Date(),
            movedAt: Date(),
            status: "moved"
        )

        #expect(record.id.uuidString.count > 0)
    }

    @Test("MoveRecord status is moved by default")
    func moveRecordStatusIsMovedByDefault() {
        let record = MoveRecord(
            filename: "video.mp4",
            originalPath: "/Downloads/video.mp4",
            destinationPath: "/Downloads/Videos/video.mp4",
            category: "Videos",
            fileExtension: "mp4",
            fileSize: 10_485_760,
            createdAt: Date(),
            movedAt: Date(),
            status: "moved"
        )

        #expect(record.status == "moved")
    }

    // MARK: - Helpers

    private func makeRecord(
        filename: String,
        category: String,
        ext: String
    ) -> MoveRecord {
        MoveRecord(
            filename: filename,
            originalPath: "/Downloads/\(filename)",
            destinationPath: "/Downloads/\(category)/\(filename)",
            category: category,
            fileExtension: ext,
            fileSize: 1024,
            createdAt: Date(),
            movedAt: Date(),
            status: "moved"
        )
    }

    private func makeTempDirectory() throws -> URL {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(
            at: dir,
            withIntermediateDirectories: true
        )
        return dir
    }

    private func cleanup(_ directory: URL) {
        try? FileManager.default.removeItem(at: directory)
    }
}