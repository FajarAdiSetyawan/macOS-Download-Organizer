@preconcurrency import SwiftTUI
import Testing
import Foundation

@testable import DownloadOrganizer

@Suite("AppPage Tests")
struct DashboardPageTests {
    @Test("AppPage allCases returns all pages")
    func allCasesNotEmpty() {
        #expect(AppPage.allCases.count == 8)
    }

    @Test("AppPage title returns non-empty string for all cases")
    func allTitlesNonEmpty() {
        for page in AppPage.allCases {
            #expect(!page.title.isEmpty)
        }
    }

    @Test("AppPage icon returns non-empty string for all cases")
    func allIconsNonEmpty() {
        for page in AppPage.allCases {
            #expect(!page.icon.isEmpty)
        }
    }

    @Test("AppPage titles match expected values")
    func titlesCorrect() {
        #expect(AppPage.dashboard.title == "Dashboard")
        #expect(AppPage.history.title == "History")
        #expect(AppPage.statistics.title == "Statistics")
        #expect(AppPage.configuration.title == "Configuration")
        #expect(AppPage.rules.title == "Rules")
        #expect(AppPage.logs.title == "Logs")
        #expect(AppPage.doctor.title == "Doctor")
        #expect(AppPage.about.title == "About")
    }
}
