import Foundation

public actor NotificationService {
    public static let shared = NotificationService()

    public init() {}

    public func requestPermission() async {
        // Skip completely for command-line tools
        await AppLogger.shared.log(
            .info,
            "Notifications disabled (command-line tool)"
        )
    }

    public func notifyMoved(
        filename: String,
        destination: String,
        enabled: Bool
    ) async {
        // No-op for command-line tools
    }

    public func notifyError(
        title: String,
        message: String,
        enabled: Bool
    ) async {
        // No-op for command-line tools
    }
}