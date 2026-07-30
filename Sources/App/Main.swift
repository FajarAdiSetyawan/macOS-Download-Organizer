@preconcurrency import SwiftTUI
import Foundation

@main
struct Main {
    static func main() async {
        let arguments = CommandLine.arguments

        if arguments.contains("dashboard") || arguments.contains("--dashboard") {
            // Panggil langsung tanpa await MainActor.run
            Application(rootView: DashboardRootView()).start()
            return
        }

        if arguments.contains("status") || arguments.contains("--status") {
            let exitCode = await StatusService().run()
            Foundation.exit(exitCode)
        }

        if arguments.contains("doctor") || arguments.contains("--doctor") {
            let exitCode = await DoctorService().run()
            Foundation.exit(exitCode)
        }

        if arguments.contains("history") || arguments.contains("--history") {
            let options = HistoryOptions.parse(from: arguments)
            let exitCode = await HistoryViewerService().run(options: options)
            Foundation.exit(exitCode)
        }

        if arguments.contains("--undo-last") {
            do {
                try await ConfigurationManager.shared.bootstrap()
                await HistoryService.shared.start()
                await HistoryService.shared.undoLastMove()
            } catch {
                await AppLogger.shared.log(.error, "Undo bootstrap failed: \(error)")
            }
            return
        }

        if arguments.contains("--stats") {
            do {
                try await ConfigurationManager.shared.bootstrap()
                await HistoryService.shared.start()

                let stats = await HistoryService.shared.statistics()
                for key in stats.keys.sorted() {
                    print("\(key): \(stats[key] ?? 0)")
                }
            } catch {
                await AppLogger.shared.log(.error, "Stats bootstrap failed: \(error)")
            }
            return
        }

        await DownloadOrganizerService().start()
    }
}