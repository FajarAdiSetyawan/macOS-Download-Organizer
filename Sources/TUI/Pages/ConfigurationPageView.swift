@preconcurrency import SwiftTUI
import Foundation

public struct ConfigurationPageView: View {
    let onHome: () -> Void
    @ObservedObject var store: TUIStore = .shared
    @State private var editingKey: String? = nil
    @State private var browsing: Bool = false
    @State private var importing: Bool = false
    @State private var restoring: Bool = false
    @State private var confirmImportPath: String? = nil
    @State private var feedbackMessage: String? = nil
    @State private var showHelp = false

    public init(onHome: @escaping () -> Void) {
        self.onHome = onHome
    }

    public var body: some View {
        let theme = ThemeManager.current
        let entries = store.configEntries

        if showHelp {
            helpOverlay(theme: theme, onClose: { showHelp = false })
        } else if browsing {
            FolderBrowserView(
                startPath: store.configuration.watchFolder,
                onSelect: { path in
                    Task { await store.updateConfig("Watch Folder", value: path) }
                    browsing = false
                    editingKey = nil
                },
                onCancel: {
                    browsing = false
                    editingKey = nil
                }
            )
        } else if importing {
            FolderBrowserView(
                startPath: "~/Desktop",
                onSelect: { path in
                    importing = false
                    confirmImportPath = path
                },
                onCancel: {
                    importing = false
                }
            )
        } else if restoring {
            FolderBrowserView(
                startPath: "~/Desktop",
                onSelect: { path in
                    restoring = false
                    Task { await restore(from: path) }
                },
                onCancel: {
                    restoring = false
                }
            )
        } else {
            VStack(spacing: 0) {
                pageTitle("\(TUIIcon.config) Configuration", theme: theme)
                Divider().foregroundColor(theme.border)

                if let msg = feedbackMessage {
                    Text(msg)
                        .foregroundColor(theme.accent)
                        .padding(.horizontal)
                    Divider().foregroundColor(theme.border)
                }

                if let path = confirmImportPath {
                    HStack(spacing: 2) {
                        Text("Import config from this file?")
                            .foregroundColor(theme.warning)
                        Button(action: {
                            Task {
                                do {
                                    try await store.importConfig(from: URL(fileURLWithPath: path))
                                    feedbackMessage = "Config imported successfully"
                                } catch {
                                    feedbackMessage = "Import failed: \(error.localizedDescription)"
                                }
                                confirmImportPath = nil
                            }
                        }) {
                            Text("Yes")
                                .foregroundColor(theme.error)
                                .bold()
                        }
                        Button(action: { confirmImportPath = nil }) {
                            Text("No")
                                .foregroundColor(theme.textDim)
                        }
                        Spacer()
                    }
                    .padding(.horizontal)
                    Divider().foregroundColor(theme.border)
                }

                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(entries, id: \.key) { entry in
                            entryRow(entry: entry, theme: theme)
                            Divider().foregroundColor(theme.border)
                        }
                    }
                }

                Group {
                    Divider().foregroundColor(theme.border)
                        .padding(.vertical, 1)

                    HStack(spacing: 2) {
                        Button(action: exportConfig) {
                            HStack(spacing: 1) {
                                Text(TUIIcon.save)
                                    .foregroundColor(theme.success)
                                Text("Export")
                                    .foregroundColor(theme.success)
                                    .bold()
                            }
                        }
                        Button(action: { importing = true }) {
                            HStack(spacing: 1) {
                                Text(TUIIcon.folder)
                                    .foregroundColor(theme.primary)
                                Text("Import")
                                    .foregroundColor(theme.primary)
                                    .bold()
                            }
                        }
                        Spacer()
                        Button(action: backupAll) {
                            HStack(spacing: 1) {
                                Text(TUIIcon.save)
                                    .foregroundColor(theme.accent)
                                Text("Backup")
                                    .foregroundColor(theme.accent)
                                    .bold()
                            }
                        }
                        Button(action: { restoring = true }) {
                            HStack(spacing: 1) {
                                Text(TUIIcon.folder)
                                    .foregroundColor(theme.warning)
                                Text("Restore")
                                    .foregroundColor(theme.warning)
                                    .bold()
                            }
                        }
                    }
                    .padding(.horizontal)

                    HStack {
                        keyHint("↑↓", "Scroll", theme: theme)
                        keyHint("R", "Refresh", theme: theme)
                        Spacer()
                        helpButton(theme: theme, action: { showHelp = true })
                        homeButton(theme: theme, action: onHome)
                    }
                    .padding(.horizontal)
                }
            }
        }
    }

    private func entryRow(entry: ConfigEntry, theme: ThemeColors) -> some View {
        VStack(spacing: 0) {
            if editingKey == entry.key && entry.type == "Seconds" {
                HStack(spacing: 1) {
                    Text(entry.key)
                        .foregroundColor(theme.textDim)
                    Spacer()
                    TextField(placeholder: entry.value, action: { newValue in
                        let sanitized = newValue.filter { $0.isNumber || $0 == "." }
                        Task { await store.updateConfig(entry.key, value: sanitized) }
                        editingKey = nil
                    })
                }
                .padding(.horizontal)
                .padding(.vertical, 1)
            } else if editingKey == entry.key && entry.type == "Select" {
                VStack(spacing: 0) {
                    HStack(spacing: 1) {
                        Text(entry.key)
                            .foregroundColor(theme.textDim)
                        Spacer()
                        Text(entry.value)
                            .foregroundColor(theme.accent)
                            .bold()
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 1)
                    ForEach(DuplicateStrategy.allCases, id: \.rawValue) { strategy in
                        Button(action: {
                            Task { await store.updateConfig("Duplicate Strategy", value: strategy.rawValue) }
                            editingKey = nil
                            feedbackMessage = "Strategy: \(strategy.label)"
                        }) {
                            HStack(spacing: 1) {
                                Text("  ")
                                Text(strategy == store.configuration.parsedDuplicateStrategy ? TUIIcon.circleFilled : TUIIcon.circleEmpty)
                                    .foregroundColor(strategy == store.configuration.parsedDuplicateStrategy ? theme.accent : theme.textDim)
                                Text(strategy.label)
                                    .foregroundColor(strategy == store.configuration.parsedDuplicateStrategy ? theme.highlight : theme.textDim)
                                    .bold(strategy == store.configuration.parsedDuplicateStrategy)
                                Text(strategy.description)
                                    .foregroundColor(theme.textDim)
                                Spacer()
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            } else if editingKey == entry.key && entry.type == "String" {
                HStack(spacing: 1) {
                    Text(entry.key)
                        .foregroundColor(theme.textDim)
                    Spacer()
                    TextField(placeholder: entry.value, action: { newValue in
                        Task { await store.updateConfig(entry.key, value: newValue) }
                        editingKey = nil
                    })
                }
                .padding(.horizontal)
                .padding(.vertical, 1)
            } else {
                Button(action: { edit(entry) }) {
                    HStack(spacing: 1) {
                        Text(editingKey == entry.key ? TUIIcon.chevronRight : " ")
                            .foregroundColor(theme.accent)
                        Text(entry.key)
                            .foregroundColor(theme.textDim)
                        Spacer()
                        Text(entry.value)
                            .foregroundColor(editingKey == entry.key ? theme.accent : theme.highlight)
                            .bold()
                        Text(entry.type)
                            .foregroundColor(theme.textDim)
                        if entry.type == "Bool" {
                            Text(TUIIcon.edit).foregroundColor(theme.accent)
                        }
                        if entry.type == "Path" {
                            Text(TUIIcon.folder).foregroundColor(theme.textDim)
                        }
                        if entry.type == "Select" {
                            Text(TUIIcon.refresh).foregroundColor(theme.primary)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 1)
                }
            }
        }
    }

    private func edit(_ entry: ConfigEntry) {
        if entry.type == "Bool" {
            Task { await store.toggleConfig(entry.key) }
        } else if entry.type == "Select" || entry.type == "Seconds" || entry.type == "String" {
            editingKey = editingKey == entry.key ? nil : entry.key
        } else if entry.type == "Path" {
            editingKey = entry.key
            browsing = true
        }
    }

    private func backupAll() {
        Task {
            let desktop = FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent("Desktop")
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd-HHmmss"
            let dirName = "download-organizer-backup-\(formatter.string(from: Date()))"
            let url = desktop.appendingPathComponent(dirName)
            do {
                try await store.backupAllData(to: url)
                feedbackMessage = "Backup saved to Desktop/\(dirName)"
            } catch {
                feedbackMessage = "Backup failed: \(error.localizedDescription)"
            }
        }
    }

    private func restore(from path: String) {
        Task {
            let url = URL(fileURLWithPath: path)
            do {
                try await store.restoreAllData(from: url)
                feedbackMessage = "Restore completed from \(path)"
            } catch {
                feedbackMessage = "Restore failed: \(error.localizedDescription)"
            }
        }
    }

    private func exportConfig() {
        Task {
            let desktop = FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent("Desktop")
            let url = desktop.appendingPathComponent("download-organizer-config.json")
            do {
                try await store.exportConfig(to: url)
                feedbackMessage = "Exported to Desktop"
            } catch {
                feedbackMessage = "Export failed: \(error.localizedDescription)"
            }
        }
    }
}
