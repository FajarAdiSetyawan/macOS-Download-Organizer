import Foundation
import Testing

@testable import DownloadOrganizer

@Suite("RuleEngine Tests")
struct RuleEngineTests {

    // MARK: - Images

    @Test("Maps jpg to Images")
    func mapsJpgToImages() async {
        let engine = RuleEngine()
        let result = await engine.categoryName(forExtension: "jpg")
        #expect(result == FileCategory.images.rawValue)
    }

    @Test("Maps jpeg to Images")
    func mapsJpegToImages() async {
        let engine = RuleEngine()
        let result = await engine.categoryName(forExtension: "jpeg")
        #expect(result == FileCategory.images.rawValue)
    }

    @Test("Maps png to Images")
    func mapsPngToImages() async {
        let engine = RuleEngine()
        let result = await engine.categoryName(forExtension: "png")
        #expect(result == FileCategory.images.rawValue)
    }

    @Test("Maps heic to Images")
    func mapsHeicToImages() async {
        let engine = RuleEngine()
        let result = await engine.categoryName(forExtension: "heic")
        #expect(result == FileCategory.images.rawValue)
    }

    @Test("Maps webp to Images")
    func mapsWebpToImages() async {
        let engine = RuleEngine()
        let result = await engine.categoryName(forExtension: "webp")
        #expect(result == FileCategory.images.rawValue)
    }

    @Test("Maps svg to Images")
    func mapsSvgToImages() async {
        let engine = RuleEngine()
        let result = await engine.categoryName(forExtension: "svg")
        #expect(result == FileCategory.images.rawValue)
    }

    // MARK: - Videos

    @Test("Maps mp4 to Videos")
    func mapsMp4ToVideos() async {
        let engine = RuleEngine()
        let result = await engine.categoryName(forExtension: "mp4")
        #expect(result == FileCategory.videos.rawValue)
    }

    @Test("Maps mov to Videos")
    func mapsMovToVideos() async {
        let engine = RuleEngine()
        let result = await engine.categoryName(forExtension: "mov")
        #expect(result == FileCategory.videos.rawValue)
    }

    @Test("Maps mkv to Videos")
    func mapsMkvToVideos() async {
        let engine = RuleEngine()
        let result = await engine.categoryName(forExtension: "mkv")
        #expect(result == FileCategory.videos.rawValue)
    }

    // MARK: - Audio

    @Test("Maps mp3 to Audio")
    func mapsMp3ToAudio() async {
        let engine = RuleEngine()
        let result = await engine.categoryName(forExtension: "mp3")
        #expect(result == FileCategory.audio.rawValue)
    }

    @Test("Maps flac to Audio")
    func mapsFlacToAudio() async {
        let engine = RuleEngine()
        let result = await engine.categoryName(forExtension: "flac")
        #expect(result == FileCategory.audio.rawValue)
    }

    @Test("Maps wav to Audio")
    func mapsWavToAudio() async {
        let engine = RuleEngine()
        let result = await engine.categoryName(forExtension: "wav")
        #expect(result == FileCategory.audio.rawValue)
    }

    // MARK: - Documents

    @Test("Maps docx to Documents")
    func mapsDocxToDocuments() async {
        let engine = RuleEngine()
        let result = await engine.categoryName(forExtension: "docx")
        #expect(result == FileCategory.documents.rawValue)
    }

    @Test("Maps xlsx to Documents")
    func mapsXlsxToDocuments() async {
        let engine = RuleEngine()
        let result = await engine.categoryName(forExtension: "xlsx")
        #expect(result == FileCategory.documents.rawValue)
    }

    @Test("Maps txt to Documents")
    func mapsTxtToDocuments() async {
        let engine = RuleEngine()
        let result = await engine.categoryName(forExtension: "txt")
        #expect(result == FileCategory.documents.rawValue)
    }

    // MARK: - PDF

    @Test("Maps pdf to PDF")
    func mapsPdfToPDF() async {
        let engine = RuleEngine()
        let result = await engine.categoryName(forExtension: "pdf")
        #expect(result == FileCategory.pdf.rawValue)
    }

    // MARK: - Archives

    @Test("Maps zip to Archives")
    func mapsZipToArchives() async {
        let engine = RuleEngine()
        let result = await engine.categoryName(forExtension: "zip")
        #expect(result == FileCategory.archives.rawValue)
    }

    @Test("Maps dmg to Archives")
    func mapsDmgToArchives() async {
        let engine = RuleEngine()
        let result = await engine.categoryName(forExtension: "dmg")
        #expect(result == FileCategory.archives.rawValue)
    }

    @Test("Maps gz to Archives")
    func mapsGzToArchives() async {
        let engine = RuleEngine()
        let result = await engine.categoryName(forExtension: "gz")
        #expect(result == FileCategory.archives.rawValue)
    }

    // MARK: - Applications

    @Test("Maps pkg to Applications")
    func mapsPkgToApplications() async {
        let engine = RuleEngine()
        let result = await engine.categoryName(forExtension: "pkg")
        #expect(result == FileCategory.applications.rawValue)
    }

    // MARK: - Books

    @Test("Maps epub to Books")
    func mapsEpubToBooks() async {
        let engine = RuleEngine()
        let result = await engine.categoryName(forExtension: "epub")
        #expect(result == FileCategory.books.rawValue)
    }

    @Test("Maps mobi to Books")
    func mapsMobiToBooks() async {
        let engine = RuleEngine()
        let result = await engine.categoryName(forExtension: "mobi")
        #expect(result == FileCategory.books.rawValue)
    }

    // MARK: - Fonts

    @Test("Maps ttf to Fonts")
    func mapsTtfToFonts() async {
        let engine = RuleEngine()
        let result = await engine.categoryName(forExtension: "ttf")
        #expect(result == FileCategory.fonts.rawValue)
    }

    @Test("Maps otf to Fonts")
    func mapsOtfToFonts() async {
        let engine = RuleEngine()
        let result = await engine.categoryName(forExtension: "otf")
        #expect(result == FileCategory.fonts.rawValue)
    }

    // MARK: - Code

    @Test("Maps swift to Code")
    func mapsSwiftToCode() async {
        let engine = RuleEngine()
        let result = await engine.categoryName(forExtension: "swift")
        #expect(result == FileCategory.code.rawValue)
    }

    @Test("Maps dart to Code")
    func mapsDartToCode() async {
        let engine = RuleEngine()
        let result = await engine.categoryName(forExtension: "dart")
        #expect(result == FileCategory.code.rawValue)
    }

    @Test("Maps py to Code")
    func mapsPyToCode() async {
        let engine = RuleEngine()
        let result = await engine.categoryName(forExtension: "py")
        #expect(result == FileCategory.code.rawValue)
    }

    @Test("Maps json to Code")
    func mapsJsonToCode() async {
        let engine = RuleEngine()
        let result = await engine.categoryName(forExtension: "json")
        #expect(result == FileCategory.code.rawValue)
    }

    @Test("Maps sh to Code")
    func mapsShToCode() async {
        let engine = RuleEngine()
        let result = await engine.categoryName(forExtension: "sh")
        #expect(result == FileCategory.code.rawValue)
    }

    // MARK: - Design

    @Test("Maps psd to Design")
    func mapsPsdToDesign() async {
        let engine = RuleEngine()
        let result = await engine.categoryName(forExtension: "psd")
        #expect(result == FileCategory.design.rawValue)
    }

    @Test("Maps fig to Design")
    func mapsFigToDesign() async {
        let engine = RuleEngine()
        let result = await engine.categoryName(forExtension: "fig")
        #expect(result == FileCategory.design.rawValue)
    }

    @Test("Maps sketch to Design")
    func mapsSketchToDesign() async {
        let engine = RuleEngine()
        let result = await engine.categoryName(forExtension: "sketch")
        #expect(result == FileCategory.design.rawValue)
    }

    // MARK: - Others

    @Test("Maps unknown extension to Others")
    func mapsUnknownToOthers() async {
        let engine = RuleEngine()
        let result = await engine.categoryName(forExtension: "unknown")
        #expect(result == FileCategory.others.rawValue)
    }

    @Test("Maps empty extension to Others")
    func mapsEmptyToOthers() async {
        let engine = RuleEngine()
        let result = await engine.categoryName(forExtension: "")
        #expect(result == FileCategory.others.rawValue)
    }

    // MARK: - Case Insensitive

    @Test("Extension is case insensitive")
    func extensionIsCaseInsensitive() async {
        let engine = RuleEngine()
        let upper = await engine.categoryName(forExtension: "PDF")
        let lower = await engine.categoryName(forExtension: "pdf")
        let mixed = await engine.categoryName(forExtension: "Pdf")
        #expect(upper == lower)
        #expect(lower == mixed)
    }

    // MARK: - Custom Rules Override

    @Test("Custom rules override defaults after reload")
    func customRulesOverrideDefaults() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)

        try FileManager.default.createDirectory(
            at: tempDir,
            withIntermediateDirectories: true
        )

        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }

        let rulesContent = """
        {
          "Flutter": ["dart"],
          "MyVideos": ["mp4"]
        }
        """

        let rulesFile = tempDir.appendingPathComponent("rules.json")

        try rulesContent.write(
            to: rulesFile,
            atomically: true,
            encoding: .utf8
        )

        let engine = RuleEngine()
        await engine.reloadRules()

        let dartResult = await engine.categoryName(forExtension: "dart")
        #expect(dartResult == FileCategory.code.rawValue)
    }
}