@preconcurrency import SwiftTUI
import Foundation

public struct FolderBrowserView: View {
    let onSelect: (String) -> Void
    let onCancel: () -> Void
    @State private var currentPath: String
    @State private var entries: [FileEntry] = []
    @State private var errorMessage: String? = nil

    public init(startPath: String = "~/Downloads", onSelect: @escaping (String) -> Void, onCancel: @escaping () -> Void) {
        self.currentPath = (startPath as NSString).expandingTildeInPath
        self.onSelect = onSelect
        self.onCancel = onCancel
    }

    public var body: some View {
        let theme = ThemeManager.current

        VStack(spacing: 0) {
            HStack(spacing: 2) {
                Text(TUIIcon.folder)
                    .foregroundColor(theme.primary)
                Text("Select Folder")
                    .foregroundColor(theme.primary)
                    .bold()
                Spacer()
                Button(action: onCancel) {
                    Text("Cancel")
                        .foregroundColor(theme.error)
                }
            }
            .padding(.horizontal)

            Divider()
                .foregroundColor(theme.border)

            Text(currentPath)
                .foregroundColor(theme.accent)
                .padding(.horizontal)

            Divider()
                .foregroundColor(theme.border)

            if let error = errorMessage {
                Text(error)
                    .foregroundColor(theme.error)
                    .padding(.horizontal)
                Divider()
                    .foregroundColor(theme.border)
            }

            ScrollView {
                VStack(spacing: 0) {
                    if currentPath != "/" {
                        Button(action: { navigateToParent() }) {
                            HStack(spacing: 2) {
                                Text("..")
                                    .foregroundColor(theme.primary)
                                    .bold()
                                Text("Parent directory")
                                    .foregroundColor(theme.textDim)
                                Spacer()
                            }
                            .padding(.horizontal)
                        }
                        Divider()
                            .foregroundColor(theme.border)
                    }

                    ForEach(entries, id: \.path) { entry in
                        Button(action: { selectEntry(entry) }) {
                            HStack(spacing: 2) {
                                Text(entry.isDirectory ? TUIIcon.folder : TUIIcon.file)
                                    .foregroundColor(entry.isDirectory ? theme.primary : theme.textDim)
                                Text(entry.name)
                                    .foregroundColor(theme.textDim)
                                Spacer()
                            }
                            .padding(.horizontal)
                        }
                        Divider()
                            .foregroundColor(theme.border)
                    }
                }
            }

            Divider()
                .foregroundColor(theme.border)

            Button(action: { onSelect(currentPath) }) {
                HStack(spacing: 2) {
                    Text(TUIIcon.checkmark)
                        .foregroundColor(theme.success)
                    Text("Select this folder")
                        .foregroundColor(theme.success)
                        .bold()
                    Spacer()
                }
                .padding(.horizontal)
            }
        }
        .onAppear {
            loadEntries()
        }
    }

    private func navigateToParent() {
        let parent = (currentPath as NSString).deletingLastPathComponent
        currentPath = parent
        loadEntries()
    }

    private func selectEntry(_ entry: FileEntry) {
        if entry.isDirectory {
            currentPath = entry.path
            loadEntries()
        } else {
            onSelect(entry.path)
        }
    }

    private func loadEntries() {
        do {
            let fm = FileManager.default
            let contents = try fm.contentsOfDirectory(at: URL(fileURLWithPath: currentPath), includingPropertiesForKeys: [.isDirectoryKey])
            entries = contents.compactMap { url in
                guard let isDir = try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory else { return nil }
                return FileEntry(name: url.lastPathComponent, path: url.path, isDirectory: isDir)
            }.sorted { a, b in
                if a.isDirectory != b.isDirectory { return a.isDirectory }
                return a.name.localizedStandardCompare(b.name) == .orderedAscending
            }
            errorMessage = nil
        } catch {
            errorMessage = "Error: \(error.localizedDescription)"
            entries = []
        }
    }
}

public struct FileEntry: Sendable {
    public let name: String
    public let path: String
    public let isDirectory: Bool
}
