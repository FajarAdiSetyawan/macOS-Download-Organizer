import Foundation

public enum DuplicateNameResolver {

    public static func destination(
        for source: URL,
        in folder: URL,
        strategy: DuplicateStrategy = .rename
    ) -> URL {
        switch strategy {
        case .overwrite:
            return folder.appendingPathComponent(source.lastPathComponent)
        case .skip:
            return folder.appendingPathComponent(source.lastPathComponent)
        case .rename:
            return resolveRename(for: source, folder: folder)
        }
    }

    public static func shouldSkip(
        for source: URL,
        in folder: URL,
        strategy: DuplicateStrategy
    ) -> Bool {
        guard strategy == .skip else { return false }
        let destination = folder.appendingPathComponent(source.lastPathComponent)
        return FileManager.default.fileExists(atPath: destination.path)
    }

    private static func resolveRename(
        for source: URL,
        folder: URL
    ) -> URL {
        let manager = FileManager.default
        let filename = source.lastPathComponent
        let baseName = source.deletingPathExtension().lastPathComponent
        let fileExtension = source.pathExtension

        let initial = folder.appendingPathComponent(filename)

        guard manager.fileExists(atPath: initial.path) else {
            return initial
        }

        var index = 1

        while true {
            let candidate = buildName(
                baseName: baseName,
                extension: fileExtension,
                index: index
            )

            let candidateURL = folder.appendingPathComponent(candidate)

            if !manager.fileExists(atPath: candidateURL.path) {
                return candidateURL
            }

            index += 1
        }
    }

    public static func hasConflict(
        for source: URL,
        in folder: URL
    ) -> Bool {
        let filename = source.lastPathComponent
        let destination = folder.appendingPathComponent(filename)
        return FileManager.default.fileExists(atPath: destination.path)
    }

    private static func buildName(
        baseName: String,
        extension fileExtension: String,
        index: Int
    ) -> String {
        if fileExtension.isEmpty {
            return "\(baseName) (\(index))"
        }

        return "\(baseName) (\(index)).\(fileExtension)"
    }
}
