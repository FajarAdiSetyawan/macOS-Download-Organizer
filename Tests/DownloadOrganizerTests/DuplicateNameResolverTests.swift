import Foundation
import Testing

@testable import DownloadOrganizer

@Suite("DuplicateNameResolver Tests")
struct DuplicateNameResolverTests {

    // MARK: - No Conflict

    @Test("Returns original name when no conflict")
    func returnsOriginalNameWhenNoConflict() throws {
        let tempDir = try makeTempDirectory()
        defer { cleanup(tempDir) }

        let source = URL(fileURLWithPath: "/tmp/photo.jpg")
        let result = DuplicateNameResolver.destination(for: source, in: tempDir)

        #expect(result.lastPathComponent == "photo.jpg")
        #expect(result.deletingLastPathComponent().path == tempDir.path)
    }

    @Test("Returns original name for file without extension when no conflict")
    func returnsOriginalNameNoExtensionNoConflict() throws {
        let tempDir = try makeTempDirectory()
        defer { cleanup(tempDir) }

        let source = URL(fileURLWithPath: "/tmp/Makefile")
        let result = DuplicateNameResolver.destination(for: source, in: tempDir)

        #expect(result.lastPathComponent == "Makefile")
    }

    // MARK: - Single Conflict

    @Test("Returns (1) when original exists")
    func returnsOneWhenOriginalExists() throws {
        let tempDir = try makeTempDirectory()
        defer { cleanup(tempDir) }

        try createFile(named: "photo.jpg", in: tempDir)

        let source = URL(fileURLWithPath: "/tmp/photo.jpg")
        let result = DuplicateNameResolver.destination(for: source, in: tempDir)

        #expect(result.lastPathComponent == "photo (1).jpg")
    }

    @Test("Returns (1) for file without extension when original exists")
    func returnsOneNoExtensionWhenOriginalExists() throws {
        let tempDir = try makeTempDirectory()
        defer { cleanup(tempDir) }

        try createFile(named: "Makefile", in: tempDir)

        let source = URL(fileURLWithPath: "/tmp/Makefile")
        let result = DuplicateNameResolver.destination(for: source, in: tempDir)

        #expect(result.lastPathComponent == "Makefile (1)")
    }

    // MARK: - Multiple Conflicts

    @Test("Returns (2) when original and (1) exist")
    func returnsTwoWhenOriginalAndOneExist() throws {
        let tempDir = try makeTempDirectory()
        defer { cleanup(tempDir) }

        try createFile(named: "photo.jpg", in: tempDir)
        try createFile(named: "photo (1).jpg", in: tempDir)

        let source = URL(fileURLWithPath: "/tmp/photo.jpg")
        let result = DuplicateNameResolver.destination(for: source, in: tempDir)

        #expect(result.lastPathComponent == "photo (2).jpg")
    }

    @Test("Returns (3) when original, (1), and (2) exist")
    func returnsThreeWhenMultipleConflict() throws {
        let tempDir = try makeTempDirectory()
        defer { cleanup(tempDir) }

        try createFile(named: "report.pdf", in: tempDir)
        try createFile(named: "report (1).pdf", in: tempDir)
        try createFile(named: "report (2).pdf", in: tempDir)

        let source = URL(fileURLWithPath: "/tmp/report.pdf")
        let result = DuplicateNameResolver.destination(for: source, in: tempDir)

        #expect(result.lastPathComponent == "report (3).pdf")
    }

    @Test("Handles many conflicts sequentially")
    func handlesManyConflicts() throws {
        let tempDir = try makeTempDirectory()
        defer { cleanup(tempDir) }

        try createFile(named: "video.mp4", in: tempDir)

        for index in 1...9 {
            try createFile(named: "video (\(index)).mp4", in: tempDir)
        }

        let source = URL(fileURLWithPath: "/tmp/video.mp4")
        let result = DuplicateNameResolver.destination(for: source, in: tempDir)

        #expect(result.lastPathComponent == "video (10).mp4")
    }

    // MARK: - Conflict Detection

    @Test("Detects conflict when file exists")
    func detectsConflictWhenFileExists() throws {
        let tempDir = try makeTempDirectory()
        defer { cleanup(tempDir) }

        try createFile(named: "document.docx", in: tempDir)

        let source = URL(fileURLWithPath: "/tmp/document.docx")
        let hasConflict = DuplicateNameResolver.hasConflict(
            for: source,
            in: tempDir
        )

        #expect(hasConflict == true)
    }

    @Test("No conflict when file does not exist")
    func noConflictWhenFileDoesNotExist() throws {
        let tempDir = try makeTempDirectory()
        defer { cleanup(tempDir) }

        let source = URL(fileURLWithPath: "/tmp/newfile.txt")
        let hasConflict = DuplicateNameResolver.hasConflict(
            for: source,
            in: tempDir
        )

        #expect(hasConflict == false)
    }

    // MARK: - Different Extensions

    @Test("Handles different extensions independently")
    func handlesDifferentExtensionsIndependently() throws {
        let tempDir = try makeTempDirectory()
        defer { cleanup(tempDir) }

        try createFile(named: "archive.zip", in: tempDir)

        let sourceZip = URL(fileURLWithPath: "/tmp/archive.zip")
        let sourceRar = URL(fileURLWithPath: "/tmp/archive.rar")

        let resultZip = DuplicateNameResolver.destination(
            for: sourceZip,
            in: tempDir
        )
        let resultRar = DuplicateNameResolver.destination(
            for: sourceRar,
            in: tempDir
        )

        #expect(resultZip.lastPathComponent == "archive (1).zip")
        #expect(resultRar.lastPathComponent == "archive.rar")
    }

    // MARK: - Helpers

    private func makeTempDirectory() throws -> URL {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(
            at: dir,
            withIntermediateDirectories: true
        )
        return dir
    }

    private func createFile(named name: String, in directory: URL) throws {
        let file = directory.appendingPathComponent(name)
        try Data().write(to: file)
    }

    private func cleanup(_ directory: URL) {
        try? FileManager.default.removeItem(at: directory)
    }
}