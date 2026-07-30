import Foundation
import Testing

@testable import DownloadOrganizer

@Suite("Doctor Integration Tests")
struct DoctorIntegrationTests {
    @Test("Doctor can run without crashing")
    func doctorCanRunWithoutCrashing() async {
        let checks = await DoctorService().runChecks()
        #expect(!checks.isEmpty)
    }

    @Test("Doctor includes valid severity values")
    func doctorSeverityValuesAreValid() async {
        let checks = await DoctorService().runChecks()

        for check in checks {
            #expect(check.severity.rawValue >= 0)
            #expect(check.severity.rawValue <= 2)
        }
    }

    @Test("Doctor does not mutate configuration")
    func doctorDoesNotMutateConfiguration() async throws {
        let configExistsBefore = FileManager.default.fileExists(
            atPath: Paths.configFile.path
        )

        _ = await DoctorService().runChecks()

        let configExistsAfter = FileManager.default.fileExists(
            atPath: Paths.configFile.path
        )

        #expect(configExistsBefore == configExistsAfter)
    }
}