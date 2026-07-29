import CoreServices
import Foundation

public final class FSEventsWatcher: @unchecked Sendable {
    private var stream: FSEventStreamRef?
    private let watchedPath: URL
    private let onChange: @Sendable (URL) -> Void
    private let queue = DispatchQueue(
        label: "com.downloadorganizer.fseventswatcher",
        qos: .utility
    )

    public init(
        path: URL,
        onChange: @escaping @Sendable (URL) -> Void
    ) {
        self.watchedPath = path
        self.onChange = onChange
    }

    deinit {
        stop()
    }

    // MARK: - Lifecycle

    public func start() {
        guard stream == nil else { return }

        let callback: FSEventStreamCallback = {
            _, contextInfo, numEvents, eventPaths, _, _ in

            guard let contextInfo else { return }

            let watcher = Unmanaged<FSEventsWatcher>
                .fromOpaque(contextInfo)
                .takeUnretainedValue()

            let paths = unsafeBitCast(
                eventPaths,
                to: NSArray.self
            ) as? [String] ?? []

            for index in 0..<numEvents {
                guard index < paths.count else { continue }
                let url = URL(fileURLWithPath: paths[index])
                watcher.handleEvent(at: url)
            }
        }

        let selfPointer = UnsafeMutableRawPointer(
            Unmanaged.passUnretained(self).toOpaque()
        )

        var context = FSEventStreamContext(
            version: 0,
            info: selfPointer,
            retain: nil,
            release: nil,
            copyDescription: nil
        )

        let flags = FSEventStreamCreateFlags(
            kFSEventStreamCreateFlagFileEvents |
            kFSEventStreamCreateFlagNoDefer |
            kFSEventStreamCreateFlagUseCFTypes
        )

        guard let createdStream = FSEventStreamCreate(
            kCFAllocatorDefault,
            callback,
            &context,
            [watchedPath.path] as CFArray,
            FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
            0.5,
            flags
        ) else {
            Task {
                await AppLogger.shared.log(
                    .error,
                    "Failed to create FSEventStream for: \(watchedPath.path)"
                )
            }
            return
        }

        stream = createdStream

        FSEventStreamSetDispatchQueue(createdStream, queue)
        FSEventStreamStart(createdStream)

        Task {
            await AppLogger.shared.log(
                .info,
                "Watching: \(watchedPath.path)"
            )
        }

        scanExistingFiles()
    }

    public func stop() {
        guard let stream else { return }

        FSEventStreamStop(stream)
        FSEventStreamInvalidate(stream)
        FSEventStreamRelease(stream)

        self.stream = nil

        Task {
            await AppLogger.shared.log(
                .info,
                "Stopped watching: \(watchedPath.path)"
            )
        }
    }

    // MARK: - Event Handler

    private func handleEvent(at url: URL) {
        let manager = FileManager.default

        if FileUtilities.isDirectory(url) {
            guard url.path == watchedPath.path else { return }
            scanExistingFiles()
            return
        }

        guard manager.fileExists(atPath: url.path) else { return }
        guard url.deletingLastPathComponent().path == watchedPath.path else {
            return
        }

        onChange(url)
    }

    // MARK: - Initial Scan

    private func scanExistingFiles() {
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: watchedPath,
            includingPropertiesForKeys: [
                .isRegularFileKey,
                .isDirectoryKey
            ],
            options: [.skipsHiddenFiles]
        ) else { return }

        for file in contents {
            guard !FileUtilities.isDirectory(file) else { continue }
            guard FileUtilities.isCandidateForMove(file) else { continue }
            onChange(file)
        }
    }
}