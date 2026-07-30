import Foundation
import Testing

@testable import DownloadOrganizer

@Suite("HistoryViewerService Tests")
struct HistoryViewerServiceTests {
    @Test("HistoryViewerService can be instantiated")
    func canBeInstantiated() {
        let service = HistoryViewerService()
        #expect(service != nil)
    }

    @Test("HistoryOptions default limit is 50")
    func defaultLimitIs50() {
        let options = HistoryOptions()
        #expect(options.limit == 50)
    }

    @Test("HistoryOptions todayOnly defaults to false")
    func todayOnlyDefaultsFalse() {
        let options = HistoryOptions()
        #expect(!options.todayOnly)
    }

    @Test("MoveRecord fields accessible by history viewer")
    func moveRecordFieldsAccessible() {
        let now = Date()

        let record = MoveRecord(
            filename: "test.pdf",
            originalPath: "/Users/user/Downloads/test.pdf",
            destinationPath: "/Users/user/Downloads/PDF/test.pdf",
            category: "PDF",
            fileExtension: "pdf",
            fileSize: 204_800,
            createdAt: now,
            movedAt: now,
            status: "moved"
        )

        #expect(record.filename == "test.pdf")
        #expect(record.category == "PDF")
        #expect(record.fileExtension == "pdf")
        #expect(record.fileSize == 204_800)
        #expect(record.status == "moved")
        #expect(record.originalPath == "/Users/user/Downloads/test.pdf")
        #expect(record.destinationPath == "/Users/user/Downloads/PDF/test.pdf")
    }

    @Test("HistoryOptions custom values override defaults")
    func customValuesOverrideDefaults() {
        let options = HistoryOptions(
            limit: 10,
            todayOnly: true,
            category: "PDF",
            fileExtension: "pdf"
        )

        #expect(options.limit == 10)
        #expect(options.todayOnly == true)
        #expect(options.category == "PDF")
        #expect(options.fileExtension == "pdf")
    }
}