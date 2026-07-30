import Foundation
import Testing

@testable import DownloadOrganizer

@Suite("HistoryOptions Tests")
struct HistoryOptionsTests {

    // MARK: - Default Values

    @Test("Default options have correct values")
    func defaultOptionsHaveCorrectValues() {
        let options = HistoryOptions()

        #expect(options.limit == 50)
        #expect(options.todayOnly == false)
        #expect(options.category == nil)
        #expect(options.fileExtension == nil)
    }

    // MARK: - Parse Limit

    @Test("Parses --limit correctly")
    func parsesLimitCorrectly() {
        let args = ["download-organizer", "history", "--limit", "10"]
        let options = HistoryOptions.parse(from: args)

        #expect(options.limit == 10)
    }

    @Test("Ignores invalid --limit value")
    func ignoresInvalidLimitValue() {
        let args = ["download-organizer", "history", "--limit", "abc"]
        let options = HistoryOptions.parse(from: args)

        #expect(options.limit == 50)
    }

    @Test("Ignores negative --limit value")
    func ignoresNegativeLimitValue() {
        let args = ["download-organizer", "history", "--limit", "-5"]
        let options = HistoryOptions.parse(from: args)

        #expect(options.limit == 50)
    }

    @Test("Ignores zero --limit value")
    func ignoresZeroLimitValue() {
        let args = ["download-organizer", "history", "--limit", "0"]
        let options = HistoryOptions.parse(from: args)

        #expect(options.limit == 50)
    }

    // MARK: - Parse Today

    @Test("Parses --today correctly")
    func parsesTodayCorrectly() {
        let args = ["download-organizer", "history", "--today"]
        let options = HistoryOptions.parse(from: args)

        #expect(options.todayOnly == true)
    }

    @Test("--today not set when not present")
    func todayNotSetWhenNotPresent() {
        let args = ["download-organizer", "history"]
        let options = HistoryOptions.parse(from: args)

        #expect(options.todayOnly == false)
    }

    // MARK: - Parse Category

    @Test("Parses --category correctly")
    func parsesCategoryCorrectly() {
        let args = ["download-organizer", "history", "--category", "PDF"]
        let options = HistoryOptions.parse(from: args)

        #expect(options.category == "PDF")
    }

    @Test("Category is nil when not provided")
    func categoryIsNilWhenNotProvided() {
        let args = ["download-organizer", "history"]
        let options = HistoryOptions.parse(from: args)

        #expect(options.category == nil)
    }

    // MARK: - Parse Extension

    @Test("Parses --extension correctly")
    func parsesExtensionCorrectly() {
        let args = ["download-organizer", "history", "--extension", "pdf"]
        let options = HistoryOptions.parse(from: args)

        #expect(options.fileExtension == "pdf")
    }

    @Test("Parses --extension and strips leading dot")
    func parsesExtensionStripsLeadingDot() {
        let args = ["download-organizer", "history", "--extension", ".pdf"]
        let options = HistoryOptions.parse(from: args)

        #expect(options.fileExtension == "pdf")
    }

    @Test("Parses --extension lowercased")
    func parsesExtensionLowercased() {
        let args = ["download-organizer", "history", "--extension", "PDF"]
        let options = HistoryOptions.parse(from: args)

        #expect(options.fileExtension == "pdf")
    }

    @Test("Extension is nil when not provided")
    func extensionIsNilWhenNotProvided() {
        let args = ["download-organizer", "history"]
        let options = HistoryOptions.parse(from: args)

        #expect(options.fileExtension == nil)
    }

    // MARK: - Combined Flags

    @Test("Parses multiple flags together")
    func parsesMultipleFlagsTogether() {
        let args = [
            "download-organizer",
            "history",
            "--limit", "25",
            "--today",
            "--category", "Images",
            "--extension", "jpg"
        ]

        let options = HistoryOptions.parse(from: args)

        #expect(options.limit == 25)
        #expect(options.todayOnly == true)
        #expect(options.category == "Images")
        #expect(options.fileExtension == "jpg")
    }

    @Test("Parses flags in any order")
    func parsesFlagsInAnyOrder() {
        let args = [
            "download-organizer",
            "--extension", "mp4",
            "history",
            "--category", "Videos",
            "--today",
            "--limit", "100"
        ]

        let options = HistoryOptions.parse(from: args)

        #expect(options.limit == 100)
        #expect(options.todayOnly == true)
        #expect(options.category == "Videos")
        #expect(options.fileExtension == "mp4")
    }
}