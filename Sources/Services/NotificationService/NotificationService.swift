import Foundation
import UserNotifications

public actor NotificationService {
    public static let shared = NotificationService()

    private var isAuthorized = false
    private var isBundled: Bool {
        Bundle.main.bundleIdentifier != nil
    }

    public init() {}

    public func requestPermission() async {
        guard isBundled else {
            await AppLogger.shared.log(.info, "Notifications skipped (no app bundle)")
            return
        }
        let center = UNUserNotificationCenter.current()
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound])
            isAuthorized = granted
            await AppLogger.shared.log(
                granted ? .info : .warning,
                granted ? "Notification permission granted" : "Notification permission denied"
            )
        } catch {
            await AppLogger.shared.log(.error, "Failed to request notification permission: \(error.localizedDescription)")
        }
    }

    public func notifyMoved(filename: String, destination: String, enabled: Bool) async {
        guard enabled && isAuthorized && isBundled else { return }
        await send(title: "File Organized", body: "\(filename) → \(destination)")
    }

    public func notifyError(title: String, message: String, enabled: Bool) async {
        guard enabled && isAuthorized && isBundled else { return }
        await send(title: title, body: message)
    }

    public func sendSummary(movedCount: Int, categories: [String: Int]) async {
        guard isAuthorized && isBundled else { return }
        let body: String
        if movedCount == 0 {
            body = "No files organized today"
        } else {
            let top = categories.sorted { $0.value > $1.value }.prefix(3)
                .map { "\($0.key): \($0.value)" }.joined(separator: ", ")
            body = "\(movedCount) files organized — \(top)"
        }
        await send(title: "Daily Summary", body: body)
    }

    private func send(title: String, body: String) async {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            await AppLogger.shared.log(.error, "Failed to send notification: \(error.localizedDescription)")
        }
    }
}