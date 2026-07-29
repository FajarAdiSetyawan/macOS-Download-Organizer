import Foundation

public actor ConfigurationManager {
    public static let shared = ConfigurationManager()

    private var cached: AppConfiguration = .default
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    public init() {
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    }

    public func bootstrap() throws {
        try FileManager.default.createDirectory(
            at: Paths.baseDirectory,
            withIntermediateDirectories: true
        )

        try FileManager.default.createDirectory(
            at: Paths.logsDirectory,
            withIntermediateDirectories: true
        )

        if !FileManager.default.fileExists(atPath: Paths.configFile.path) {
            let data = try encoder.encode(AppConfiguration.default)
            try data.write(to: Paths.configFile, options: .atomic)
        }

        if !FileManager.default.fileExists(atPath: Paths.rulesFile.path) {
            let data = try JSONSerialization.data(
                withJSONObject: [:],
                options: .prettyPrinted
            )
            try data.write(to: Paths.rulesFile, options: .atomic)
        }

        cached = try loadFromDisk()
    }

    public func current() -> AppConfiguration {
        cached
    }

    public func reload() async {
        do {
            cached = try loadFromDisk()
            await AppLogger.shared.log(.info, "Configuration reloaded successfully")
        } catch {
            await AppLogger.shared.log(
                .error,
                "Configuration reload failed: \(error.localizedDescription)"
            )
        }
    }

    public func save(_ configuration: AppConfiguration) throws {
        let data = try encoder.encode(configuration)
        try data.write(to: Paths.configFile, options: .atomic)
        cached = configuration
    }

    public func update(_ block: (inout AppConfiguration) -> Void) throws {
        var updated = cached
        block(&updated)
        try save(updated)
    }

    private func loadFromDisk() throws -> AppConfiguration {
        let data = try Data(contentsOf: Paths.configFile)
        return try decoder.decode(AppConfiguration.self, from: data)
    }
}