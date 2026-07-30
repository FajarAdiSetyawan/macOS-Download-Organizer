import Foundation
import UserNotifications

public actor NotificationService {
    public static let shared = NotificationService()
    
    private var isAuthorized = false

    public init() {}

    public func requestPermission() async {
        let center = UNUserNotificationCenter.current()
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound])
            isAuthorized = granted
            if granted {
                await AppLogger.shared.log(.info, "Notification permission granted")
            } else {
                await AppLogger.shared.log(.warning, "Notification permission denied")
            }
        } catch {
            await AppLogger.shared.log(.error, "Failed to request notification permission: \(error.localizedDescription)")
        }
    }

    public func notifyMoved(
        filename: String,
        destination: String,
        enabled: Bool
    ) async {
        guard enabled && isAuthorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "File Organized"
        content.body = "\(filename) → \(destination)"
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

    public func notifyError(
        title: String,
        message: String,
        enabled: Bool
    ) async {
        guard enabled && isAuthorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            await AppLogger.shared.log(.error, "Failed to send error notification: \(error.localizedDescription)")
        }
    }
    
    public func sendSummary(movedCount: Int, categories: [String: Int]) async {
        guard isAuthorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Daily Summary"
        
        if movedCount == 0 {
            content.body = "No files organized today"
        } else {
            let topCategories = categories.sorted { $0.value > $1.value }.prefix(3)
            let categorySummary = topCategories.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
            content.body = "\(movedCount) files organized. \(categorySummary)"
        }
        
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            await AppLogger.shared.log(.error, "Failed to send summary notification: \(error.localizedDescription)")
        }
    }
}