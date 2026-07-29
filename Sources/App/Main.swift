import Foundation

@main
struct Main {
    static func main() async {
        let arguments = CommandLine.arguments

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