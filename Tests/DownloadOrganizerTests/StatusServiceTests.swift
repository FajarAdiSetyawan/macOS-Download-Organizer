import Testing

@testable import DownloadOrganizer

@Suite("StatusService Tests")
struct StatusServiceTests {
    @Test("AppStatus fatal when not running")
    func appStatusFatalWhenNotRunning() {
        let status = AppStatus(
            isRunning: false,
            pid: nil,
            watchFolder: "~/Downloads",
            movedToday: 0,
            queueCount: 0,
            rulesCount: 0,
            databaseHealthy: true,
            memoryUsage: nil,
            uptime: nil
        )

        #expect(status.isFatal)
    }

    @Test("AppStatus fatal when database unhealthy")
    func appStatusFatalWhenDatabaseUnhealthy() {
        let status = AppStatus(
            isRunning: true,
            pid: 1,
            watchFolder: "~/Downloads",
            movedToday: 0,
            queueCount: 0,
            rulesCount: 0,
            databaseHealthy: false,
            memoryUsage: "4.2 MB",
            uptime: "1h 2m"
        )

        #expect(status.isFatal)
    }

    @Test("AppStatus healthy when running and database healthy")
    func appStatusHealthyWhenRunningAndDatabaseHealthy() {
        let status = AppStatus(
            isRunning: true,
            pid: 1,
            watchFolder: "~/Downloads",
            movedToday: 10,
            queueCount: 0,
            rulesCount: 34,
            databaseHealthy: true,
            memoryUsage: "4.2 MB",
            uptime: "3d 12h"
        )

        #expect(!status.isFatal)
    }

    @Test("Status service collect does not crash")
    func statusServiceCollectDoesNotCrash() async {
        let status = await StatusService().collectStatus()

        #expect(!status.watchFolder.isEmpty)
        #expect(status.movedToday >= 0)
        #expect(status.queueCount >= 0)
        #expect(status.rulesCount >= 0)
    }
}