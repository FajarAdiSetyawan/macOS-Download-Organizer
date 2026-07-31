@preconcurrency import SwiftTUI
import Foundation

public struct MainMenuPage: View {
    let onSelect: (AppPage) -> Void

    public init(onSelect: @escaping (AppPage) -> Void) {
        self.onSelect = onSelect
    }

    @ObservedObject private var store: TUIStore = .shared
    @State private var organizeFeedback: String? = nil

    public var body: some View {
        let theme = ThemeManager.current

        VStack(spacing: 0) {
            VStack(spacing: 0) {
                logoView(asciiLogo, theme: theme)
                Text("Download Organizer  v1.1.3")
                    .foregroundColor(theme.highlight)
                    .bold()
                Text("Native Swift 6  •  macOS 14+")
                    .foregroundColor(theme.textDim)
            }

            statusBar(store: store, theme: theme)
            
            watchFolderInfo(store: store, theme: theme)
            
            if let feedback = organizeFeedback {
                HStack(spacing: 2) {
                    Text(feedback)
                        .foregroundColor(theme.success)
                        .bold()
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 1)
            }

            Divider()
                .foregroundColor(theme.border)

            ScrollView {
                VStack(spacing: 0) {
                    ForEach(AppPage.allCases, id: \.self) { menuPage in
                        Button(action: { onSelect(menuPage) }) {
                            HStack(spacing: 2) {
                                Text(menuPage.icon)
                                    .foregroundColor(theme.primary)
                                Text(menuPage.title)
                                    .foregroundColor(theme.textDim)
                                Spacer()
                            }
                            .padding(.horizontal)
                        }
                    }
                    Text(separatorLine(theme: theme))
                        .foregroundColor(theme.textDim)
                        .padding(.horizontal)
                    Button(action: {
                        Task { 
                            let result = await store.organizeNow()
                            await store.refresh()
                            organizeFeedback = result
                            try? await Task.sleep(for: .seconds(5))
                            organizeFeedback = nil
                        }
                    }) {
                        HStack(spacing: 2) {
                            Text(TUIIcon.refresh)
                                .foregroundColor(theme.success)
                            Text("Organize Now")
                                .foregroundColor(theme.success)
                                .bold()
                            Spacer()
                        }
                        .padding(.horizontal)
                    }
                    Text(separatorLine(theme: theme))
                        .foregroundColor(theme.textDim)
                        .padding(.horizontal)
                    Button(action: {
                        store.stopAutoRefresh()
                        exit(0)
                    }) {
                        HStack(spacing: 2) {
                            Text(TUIIcon.crossmark)
                                .foregroundColor(theme.error)
                            Text("Quit")
                                .foregroundColor(theme.error)
                            Spacer()
                        }
                        .padding(.horizontal)
                    }
                }
            }

            Divider()
                .foregroundColor(theme.border)

            HStack(spacing: 2) {
                keyHint("\u{2191}\u{2193}", "Nav", theme: theme)
                keyHint("\u{23CE}", "Select", theme: theme)
                keyHint("T", "Theme", theme: theme)
                keyHint("R", "Refresh", theme: theme)
                keyHint("Q", "Quit", theme: theme)
                Spacer()
                Text(store.lastRefreshAgo)
                    .foregroundColor(theme.textDim)
            }
            .padding(.horizontal)
        }
    }

    private func statusBar(store: TUIStore, theme: ThemeColors) -> some View {
        HStack(spacing: 2) {
            Text("Theme:")
                .foregroundColor(theme.textDim)
            Button(action: { Task { await store.cycleTheme() } }) {
                Text(store.configuration.theme)
                    .foregroundColor(theme.primary)
                    .bold()
            }

            Spacer()

            Text(store.serviceRunning ? TUIIcon.running : TUIIcon.stopped)
                .foregroundColor(store.serviceRunning ? theme.success : theme.error)
            Text(store.serviceRunning ? "Running" : "Stopped")
                .foregroundColor(store.serviceRunning ? theme.success : theme.error)
                .bold()

            Text(store.databaseHealthy ? TUIIcon.checkmark : TUIIcon.crossmark)
                .foregroundColor(store.databaseHealthy ? theme.success : theme.error)
            Text("DB")
                .foregroundColor(theme.textDim)
        }
        .padding(.horizontal)
        .padding(.vertical, 1)
    }
    
    private func watchFolderInfo(store: TUIStore, theme: ThemeColors) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 2) {
                Text("Watching:")
                    .foregroundColor(theme.textDim)
                Text(store.configuration.watchFolder)
                    .foregroundColor(theme.primary)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 1)
            
            if let additional = store.configuration.additionalWatchFolder, !additional.isEmpty {
                HStack(spacing: 2) {
                    Text("Additional:")
                        .foregroundColor(theme.textDim)
                    Text(additional)
                        .foregroundColor(theme.primary)
                    Spacer()
                }
                .padding(.horizontal)
            }
        }
    }

    private func separatorLine(theme: ThemeColors) -> String {
        String(repeating: TUIIcon.horizontalLine, count: 24)
    }

    private var asciiLogo: String {
        """
   ____                        _        _             
  |  _ \\  ___  _ __ ___   ___ | |_ __ _(_)_ __   ___ 
  | | | |/ _ \\| '_ ` _ \\ / _ \\| __/ _` | | '_ \\ / _ \\
  | |_| | (_) | | | | | | (_) | || (_| | | | | |  __/
  |____/ \\___/|_| |_| |_|\\___/ \\__\\__, |_|_| |_|\\___|
                                  |___/              
"""
    }
}
