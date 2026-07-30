import Testing

@testable import DownloadOrganizer

@Suite("DoctorService Tests")
struct DoctorServiceTests {
    @Test("DoctorCheck stores title severity and message")
    func doctorCheckStoresValues() {
        let check = DoctorCheck(
            title: "Config OK",
            severity: .ok,
            message: "valid"
        )

        #expect(check.title == "Config OK")
        #expect(check.severity == .ok)
        #expect(check.message == "valid")
    }

    @Test("DoctorSeverity exit code ordering is correct")
    func doctorSeverityOrdering() {
        #expect(DoctorSeverity.ok.rawValue == 0)
        #expect(DoctorSeverity.warning.rawValue == 1)
        #expect(DoctorSeverity.fatal.rawValue == 2)
    }

    @Test("Terminal color values are not empty")
    func terminalColorsNotEmpty() {
        #expect(!TerminalColor.green.isEmpty)
        #expect(!TerminalColor.yellow.isEmpty)
        #expect(!TerminalColor.red.isEmpty)
        #expect(!TerminalColor.reset.isEmpty)
    }

    @Test("Doctor checks return at least required checks")
    func doctorReturnsRequiredChecks() async {
        let checks = await DoctorService().runChecks()

        #expect(checks.count >= 12)
        #expect(checks.contains { $0.title.contains("LaunchAgent") })
        #expect(checks.contains { $0.title.contains("Config") || $0.title.contains("Configuration") })
        #expect(checks.contains { $0.title.contains("Rules") })
        #expect(checks.contains { $0.title.contains("SQLite") })
        #expect(checks.contains { $0.title.contains("Logs") || $0.title.contains("Log") })
        #expect(checks.contains { $0.title.contains("Downloads") })
        #expect(checks.contains { $0.title.contains("Watch folder") })
        #expect(checks.contains { $0.title.contains("Retry queue") })
    }
}