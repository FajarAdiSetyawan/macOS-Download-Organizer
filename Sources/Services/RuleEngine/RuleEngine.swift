import Foundation

public actor RuleEngine {
    public static let shared = RuleEngine()

    private var defaultRules: [String: FileCategory] = [:]
    private var customRules: [String: String] = [:]

    public init() {
        self.defaultRules = Self.buildDefaultRulesStatic()
        self.customRules = [:]
    }

    // MARK: - Public

    public func reloadRules() async {
        defaultRules = Self.buildDefaultRulesStatic()
        customRules = [:]
        await loadCustomRules()
        await AppLogger.shared.log(.info, "Rules reloaded")
    }

    public func categoryName(forExtension fileExtension: String) -> String {
        let ext = fileExtension.lowercased()

        if let customCategory = customRules[ext] {
            return customCategory
        }

        if let category = defaultRules[ext] {
            return category.rawValue
        }

        return FileCategory.others.rawValue
    }

    public func category(forExtension fileExtension: String) -> FileCategory {
        let ext = fileExtension.lowercased()

        if customRules[ext] != nil {
            return .others
        }

        return defaultRules[ext] ?? .others
    }

    // MARK: - Default Rules

    private static func buildDefaultRulesStatic() -> [String: FileCategory] {
        var rules: [String: FileCategory] = [:]

        // Images - Expanded with RAW formats
        let images: [String] = [
            "jpg", "jpeg", "png", "gif", "bmp",
            "webp", "svg", "heic", "heif", "tif",
            "tiff", "avif", "ico", "raw", "cr2",
            "nef", "dng", "arw", "orf", "rw2"
        ]

        // Videos - Added more formats
        let videos: [String] = [
            "mp4", "mov", "mkv", "avi", "wmv",
            "flv", "webm", "m4v", "mpg", "mpeg",
            "3gp", "3g2", "ogv", "vob", "ts",
            "m2ts", "mts", "divx", "xvid"
        ]

        // Audio - Added lossless and streaming formats
        let audio: [String] = [
            "mp3", "wav", "aac", "ogg", "flac",
            "m4a", "wma", "opus", "alac", "ape",
            "aiff", "aif", "mid", "midi", "amr"
        ]

        // Documents - Added more office formats
        let documents: [String] = [
            "doc", "docx", "xls", "xlsx", "ppt",
            "pptx", "txt", "csv", "rtf", "odt",
            "ods", "odp", "pages", "numbers", "key",
            "tex", "wpd", "wps"
        ]

        // PDF
        let pdf: [String] = [
            "pdf"
        ]

        // Archives - Comprehensive compression formats
        let archives: [String] = [
            "zip", "rar", "7z", "tar", "gz",
            "xz", "bz2", "dmg", "iso", "cab",
            "arj", "lz", "lzh", "ace", "img",
            "bin", "cue", "mdf", "nrg", "toast"
        ]

        // Applications - macOS, Windows, Linux
        let applications: [String] = [
            "app", "pkg", "exe", "msi", "apk",
            "aab", "ipa", "deb", "rpm", "appimage"
        ]

        // Books - All ebook formats
        let books: [String] = [
            "epub", "mobi", "azw", "azw3", "fb2",
            "lit", "lrf", "cbr", "cbz", "cbt"
        ]

        // Fonts - Complete font formats
        let fonts: [String] = [
            "ttf", "otf", "woff", "woff2", "eot",
            "dfont", "fon", "ttc"
        ]

        // Code - Expanded programming languages
        let code: [String] = [
            "dart", "swift", "java", "kt", "go",
            "rs", "cpp", "c", "h", "hpp", "cc",
            "cxx", "py", "js", "ts", "tsx", "jsx",
            "php", "cs", "sql", "json", "yaml",
            "yml", "xml", "html", "css", "scss",
            "sass", "less", "sh", "zsh", "bash",
            "rb", "pl", "lua", "r", "m", "mm",
            "toml", "ini", "cfg", "conf", "env",
            "vue", "svelte", "asm", "s", "f90",
            "f", "for", "pas", "pp", "gradle",
            "cmake", "mk", "makefile"
        ]

        // Design - Professional design tools
        let design: [String] = [
            "fig", "xd", "psd", "ai", "sketch",
            "indd", "afdesign", "afphoto", "blend",
            "c4d", "max", "fbx", "obj", "stl",
            "dae", "3ds", "gltf", "glb", "usdz",
            "dwg", "dxf", "igs", "iges", "step",
            "stp", "skp"
        ]

        // Populate rules
        for ext in images { rules[ext] = .images }
        for ext in videos { rules[ext] = .videos }
        for ext in audio { rules[ext] = .audio }
        for ext in documents { rules[ext] = .documents }
        for ext in pdf { rules[ext] = .pdf }
        for ext in archives { rules[ext] = .archives }
        for ext in applications { rules[ext] = .applications }
        for ext in books { rules[ext] = .books }
        for ext in fonts { rules[ext] = .fonts }
        for ext in code { rules[ext] = .code }
        for ext in design { rules[ext] = .design }

        return rules
    }

    // MARK: - Custom Rules

    private func loadCustomRules() async {
        guard FileManager.default.fileExists(atPath: Paths.rulesFile.path) else {
            await AppLogger.shared.log(.debug, "No custom rules file found, skipping")
            return
        }

        do {
            let data = try Data(contentsOf: Paths.rulesFile)

            guard !data.isEmpty else {
                await AppLogger.shared.log(.debug, "Custom rules file is empty")
                return
            }

            let decoded = try JSONDecoder().decode(
                [String: [String]].self,
                from: data
            )

            var resolved: [String: String] = [:]

            for (categoryName, extensions) in decoded {
                for fileExtension in extensions {
                    let ext = fileExtension.lowercased()
                    resolved[ext] = categoryName
                }
            }

            customRules = resolved

            await AppLogger.shared.log(
                .info,
                "Custom rules loaded: \(resolved.count) extension(s) overridden"
            )
        } catch {
            await AppLogger.shared.log(
                .error,
                "Failed to load custom rules: \(error.localizedDescription)"
            )
        }
    }
}