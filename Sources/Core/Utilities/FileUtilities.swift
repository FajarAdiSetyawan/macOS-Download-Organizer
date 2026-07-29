import CryptoKit
import Foundation

public enum FileUtilities {
    public static let ignoredNames: Set<String> = [
        ".DS_Store"
    ]

    public static let ignoredExtensions: Set<String> = [
        "tmp",
        "part",
        "download",
        "crdownload",
        "opdownload",
        "downloading",
        "partial",
        "hidden"
    ]

    public static func shouldIgnore(_ url: URL) -> Bool {
        let filename = url.lastPathComponent

        if filename.isEmpty {
            return true
        }

        if filename.hasPrefix(".") {
            return true
        }

        if ignoredNames.contains(filename) {
            return true
        }

        let fileExtension = url.pathExtension.lowercased()

        if ignoredExtensions.contains(fileExtension) {
            return true
        }

        return false
    }

    public static func fileExists(_ url: URL) -> Bool {
        FileManager.default.fileExists(atPath: url.path)
    }

    public static func isDirectory(_ url: URL) -> Bool {
        var isDirectory: ObjCBool = false

        let exists = FileManager.default.fileExists(
            atPath: url.path,
            isDirectory: &isDirectory
        )

        return exists && isDirectory.boolValue
    }

    public static func isRegularFile(_ url: URL) -> Bool {
        do {
            let values = try url.resourceValues(forKeys: [
                .isRegularFileKey,
                .isDirectoryKey
            ])

            return values.isRegularFile == true && values.isDirectory != true
        } catch {
            return false
        }
    }

    public static func fileSize(_ url: URL) -> Int64 {
        do {
            let values = try url.resourceValues(forKeys: [
                .fileSizeKey
            ])

            return Int64(values.fileSize ?? 0)
        } catch {
            return 0
        }
    }

    public static func isReadable(_ url: URL) -> Bool {
        let descriptor = open(url.path, O_RDONLY)

        if descriptor < 0 {
            return false
        }

        close(descriptor)
        return true
    }

    public static func isLocked(_ url: URL) -> Bool {
        do {
            let values = try url.resourceValues(forKeys: [
                .isUserImmutableKey,
                .isSystemImmutableKey
            ])

            return values.isUserImmutable == true || values.isSystemImmutable == true
        } catch {
            return true
        }
    }

    public static func isCandidateForMove(_ url: URL) -> Bool {
        if shouldIgnore(url) {
            return false
        }

        if isDirectory(url) {
            return false
        }

        if !isRegularFile(url) {
            return false
        }

        if !isReadable(url) {
            return false
        }

        if isLocked(url) {
            return false
        }

        return true
    }

    public static func checksum(_ url: URL) throws -> String {
        let data = try Data(contentsOf: url)
        let digest = SHA256.hash(data: data)

        return digest
            .map { byte in
                String(format: "%02x", byte)
            }
            .joined()
    }
}