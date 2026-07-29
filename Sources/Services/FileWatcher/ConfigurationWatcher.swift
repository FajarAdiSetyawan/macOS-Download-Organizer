import Foundation

public final class ConfigurationWatcher: @unchecked Sendable {
    private var dispatchSource: DispatchSourceFileSystemObject?
    private var fileDescriptor: CInt = -1
    private let watchedURL: URL
    private let onChange: @Sendable () -> Void
    private let queue = DispatchQueue(
        label: "com.downloadorganizer.configwatcher",
        qos: .utility
    )

    public init(
        url: URL,
        onChange: @escaping @Sendable () -> Void
    ) {
        self.watchedURL = url
        self.onChange = onChange
    }

    deinit {
        stop()
    }

    // MARK: - Lifecycle

    public func start() {
        stop()

        guard FileManager.default.fileExists(atPath: watchedURL.path) else {
            Task {
                await AppLogger.shared.log(
                    .debug,
                    "Config file not found, watcher will not start: \(watchedURL.lastPathComponent)"
                )
            }
            return
        }

        let descriptor = open(watchedURL.path, O_EVTONLY)

        guard descriptor >= 0 else {
            Task {
                await AppLogger.shared.log(
                    .warning,
                    "Failed to open file descriptor for: \(watchedURL.lastPathComponent)"
                )
            }
            return
        }

        fileDescriptor = descriptor

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: descriptor,
            eventMask: [.write, .rename, .delete, .extend],
            queue: queue
        )

        source.setEventHandler { [weak self] in
            guard let self else { return }

            Task {
                await AppLogger.shared.log(
                    .debug,
                    "Config changed: \(self.watchedURL.lastPathComponent)"
                )
            }

            self.onChange()
            self.restart()
        }

        source.setCancelHandler {
            if descriptor >= 0 {
                close(descriptor)
            }
        }

        dispatchSource = source
        source.resume()

        Task {
            await AppLogger.shared.log(
                .info,
                "Config watcher started: \(watchedURL.lastPathComponent)"
            )
        }
    }

    public func stop() {
        dispatchSource?.cancel()
        dispatchSource = nil
        fileDescriptor = -1
    }

    // MARK: - Restart

    private func restart() {
        queue.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.stop()
            self?.start()
        }
    }
}