@preconcurrency import SwiftTUI
import Testing
import Foundation

@testable import DownloadOrganizer

@Suite("TUIStore Tests")
struct TUIStoreTests {
    @Test("TUIStore shared instance accessible")
    @MainActor
    func sharedInstanceAccessible() {
        let store = TUIStore.shared
        _ = store
    }

    @Test("TUIStore default values are correct")
    @MainActor
    func defaultValuesAreCorrect() {
        let store = TUIStore.shared

        #expect(store.serviceRunning == false)
        #expect(store.watchFolder == "~/Downloads")
        #expect(store.movedToday >= 0)
        #expect(store.queueCount >= 0)
        #expect(store.rulesCount >= 0)
        #expect(store.memoryUsage == "...")
        #expect(store.cpuUsage == "0.0%")
        #expect(store.databaseHealthy == false)
        #expect(!store.isLoading)
        #expect(store.allRecords.isEmpty)
        #expect(store.recentRecords.isEmpty)
        #expect(store.statistics.isEmpty)
        #expect(store.doctorChecks.isEmpty)
    }

    @Test("TUIStore refreshTimestamp is distantPast initially")
    @MainActor
    func refreshTimestampInitialValue() {
        let store = TUIStore.shared
        #expect(store.refreshTimestamp == Date.distantPast)
    }

    @Test("TUIStore lastRefreshAgo returns valid string")
    @MainActor
    func lastRefreshAgoReturnsString() {
        let store = TUIStore.shared
        let ago = store.lastRefreshAgo
        #expect(!ago.isEmpty)
    }

    @Test("TUIStore clearDoctorChecks empties checks")
    @MainActor
    func clearDoctorChecksEmptiesArray() {
        let store = TUIStore.shared
        store.clearDoctorChecks()
        #expect(store.doctorChecks.isEmpty)
    }
}
