import Foundation

public enum DuplicateNameResolver {

    /// Resolves a non-conflicting destination URL for the given source file
    /// inside the target folder. If no conflict exists, returns the original
    /// filename. If a conflict exists, appends an incrementing index.
    ///
    /// Example:
    /// - photo.jpg        (exists)
    /// - photo (1).jpg    (exists)
    /// - photo (2).jpg    ← returned
    public static func destination(
        for source: URL,
        in folder: URL
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

    /// Checks whether a file at the given URL would conflict with any
    /// existing file in the destination folder.
    public static func hasConflict(
        for source: URL,
        in folder: URL
    ) -> Bool {
        let filename = source.lastPathComponent
        let destination = folder.appendingPathComponent(filename)
        return FileManager.default.fileExists(atPath: destination.path)
    }

    // MARK: - Private

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