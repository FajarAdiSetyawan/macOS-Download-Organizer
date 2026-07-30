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
        let ext = normalizedExtension(fileExtension)

        if let customCategory = customRules[ext] {
            return customCategory
        }

        if let category = defaultRules[ext] {
            return category.rawValue
        }

        return FileCategory.others.rawValue
    }

    public func category(forExtension fileExtension: String) -> FileCategory {
        let ext = normalizedExtension(fileExtension)

        if customRules[ext] != nil {
            return .others
        }

        return defaultRules[ext] ?? .others
    }

    public func extensions(for category: FileCategory) -> [String] {
        defaultRules
            .filter { $0.value == category }
            .map(\.key)
            .sorted()
    }

    public func ruleCount() -> Int {
        let uniqueExtensions = Set(defaultRules.keys).union(customRules.keys)
        return uniqueExtensions.count
    }

    public func defaultRuleCount() -> Int {
        defaultRules.count
    }

    public func customRuleCount() -> Int {
        customRules.count
    }

    public func hasCustomRules() -> Bool {
        !customRules.isEmpty
    }

    public func allCategories() -> [String] {
        var cats = Set<String>()
        for cat in defaultRules.values { cats.insert(cat.rawValue) }
        for cat in customRules.values { cats.insert(cat) }
        return cats.sorted()
    }

    public func extensionsForDisplay(category: String) -> [String] {
        var exts = Set<String>()
        for (ext, cat) in customRules where cat == category {
            exts.insert(ext)
        }
        for (ext, cat) in defaultRules where cat.rawValue == category {
            exts.insert(ext)
        }
        return exts.sorted()
    }

    public func setCustomRule(category: String, extensions: [String]) async {
        for ext in customRules.keys where customRules[ext] == category {
            customRules.removeValue(forKey: ext)
        }
        for ext in extensions {
            let normalized = normalizedExtension(ext)
            guard !normalized.isEmpty else { continue }
            customRules[normalized] = category
        }
        await saveCustomRules()
    }

    public func removeCustomRule(category: String) async {
        for ext in customRules.keys where customRules[ext] == category {
            customRules.removeValue(forKey: ext)
        }
        await saveCustomRules()
    }

    public func resetToDefaults() async {
        customRules = [:]
        await saveCustomRules()
    }

    public func saveCustomRules() async {
        var grouped: [String: [String]] = [:]
        for (ext, category) in customRules {
            grouped[category, default: []].append(ext)
        }
        for (category, exts) in grouped {
            grouped[category] = exts.sorted()
        }
        do {
            try FileManager.default.createDirectory(
                at: Paths.baseDirectory,
                withIntermediateDirectories: true
            )
            let data = try JSONSerialization.data(
                withJSONObject: grouped,
                options: [.prettyPrinted, .sortedKeys]
            )
            try data.write(to: Paths.rulesFile, options: .atomic)
            await AppLogger.shared.log(.info, "Custom rules saved")
        } catch {
            await AppLogger.shared.log(.error, "Failed to save custom rules: \(error.localizedDescription)")
        }
    }

    // MARK: - Default Rules

    private static func buildDefaultRulesStatic() -> [String: FileCategory] {
        var rules: [String: FileCategory] = [:]

        let images: [String] = [
            "jpg", "jpeg", "png", "gif", "bmp",
            "webp", "svg", "heic", "heif", "tif",
            "tiff", "avif", "ico", "raw", "cr2",
            "nef", "dng", "arw", "orf", "rw2",
            "jxl", "xcf", "kra", "psb", "svgz"
        ]

        let videos: [String] = [
            "mp4", "mov", "mkv", "avi", "wmv",
            "flv", "webm", "m4v", "mpg", "mpeg",
            "3gp", "3g2", "ogv", "vob", "ts",
            "m2ts", "mts", "divx", "xvid"
        ]

        let audio: [String] = [
            "mp3", "wav", "aac", "ogg", "flac",
            "m4a", "wma", "opus", "alac", "ape",
            "aiff", "aif", "mid", "midi", "amr"
        ]

        let documents: [String] = [
            "doc", "docx", "xls", "xlsx", "ppt",
            "pptx", "txt", "csv", "rtf", "odt",
            "ods", "odp", "pages", "numbers", "key",
            "tex", "wpd", "wps", "md", "markdown",
            "log", "msg", "eml", "ics", "vcf"
        ]

        let pdf: [String] = [
            "pdf"
        ]

        let archives: [String] = [
            "zip", "rar", "7z", "tar", "gz",
            "xz", "bz2", "dmg", "iso", "cab",
            "arj", "lz", "lzh", "ace", "img",
            "bin", "cue", "mdf", "nrg", "toast",
            "zst", "zstd", "lz4", "jar", "war",
            "ear", "sitx", "wim"
        ]

        let applications: [String] = [
            "app", "pkg", "exe", "msi", "apk",
            "aab", "ipa", "deb", "rpm", "appimage"
        ]

        let books: [String] = [
            "epub", "mobi", "azw", "azw3", "fb2",
            "lit", "lrf", "cbr", "cbz", "cbt"
        ]

        let fonts: [String] = [
            "ttf", "otf", "woff", "woff2", "eot",
            "dfont", "fon", "ttc"
        ]

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
            "cmake", "mk", "makefile",
            "zig", "hs", "lhs", "ex", "exs",
            "erl", "hrl", "scala", "sc", "clj",
            "cljs", "cljc", "edn", "graphql", "gql",
            "tf", "tfvars", "hcl", "nix", "ps1",
            "wasm", "prisma", "bzl", "lisp", "cl",
            "el", "rkt", "groovy", "gvy", "gsh",
            "jl", "cr", "nim", "pony", "purs",
            "res", "ml", "mli", "v", "vb",
            "asmx", "awk", "tcl", "coffee"
        ]

        let design: [String] = [
            "fig", "xd", "psd", "ai", "sketch",
            "indd", "afdesign", "afphoto", "blend",
            "c4d", "max", "fbx", "obj", "stl",
            "dae", "3ds", "gltf", "glb", "usdz",
            "dwg", "dxf", "igs", "iges", "step",
            "stp", "skp", "eps", "ps",
            "storyboard", "xib"
        ]

        let database: [String] = [
            "sqlite", "sqlite3", "db", "db3",
            "sql", "sqlitedb", "sdb", "frm",
            "myd", "myi", "mdf", "ldf", "ndf"
        ]

        let config: [String] = [
            "plist", "strings", "xcconfig",
            "entitlements", "mobileprovision",
            "xcscheme", "xcworkspacedata",
            "pbxproj", "xcsettings"
        ]

        let certificates: [String] = [
            "cer", "crt", "pem", "key",
            "p12", "pfx", "der", "ca-bundle",
            "csr"
        ]

        add(images, to: &rules, category: .images)
        add(videos, to: &rules, category: .videos)
        add(audio, to: &rules, category: .audio)
        add(documents, to: &rules, category: .documents)
        add(pdf, to: &rules, category: .pdf)
        add(archives, to: &rules, category: .archives)
        add(applications, to: &rules, category: .applications)
        add(books, to: &rules, category: .books)
        add(fonts, to: &rules, category: .fonts)
        add(code, to: &rules, category: .code)
        add(design, to: &rules, category: .design)
        add(database, to: &rules, category: .database)
        add(config, to: &rules, category: .config)
        add(certificates, to: &rules, category: .certificates)

        return rules
    }

    private static func add(
        _ extensions: [String],
        to rules: inout [String: FileCategory],
        category: FileCategory
    ) {
        for fileExtension in extensions {
            rules[normalize(fileExtension)] = category
        }
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
                    let ext = normalizedExtension(fileExtension)
                    guard !ext.isEmpty else { continue }
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

    // MARK: - Normalization

    private func normalizedExtension(_ fileExtension: String) -> String {
        Self.normalize(fileExtension)
    }

    private static func normalize(_ fileExtension: String) -> String {
        fileExtension
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "."))
            .lowercased()
    }
}