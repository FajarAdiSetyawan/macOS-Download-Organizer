@preconcurrency import SwiftTUI
import Foundation

public struct AboutPageView: View {
    let onHome: () -> Void
    @State private var showHelp = false

    public init(onHome: @escaping () -> Void) {
        self.onHome = onHome
    }

    public var body: some View {
        let theme = ThemeManager.current

        if showHelp {
            helpOverlay(theme: theme, onClose: { showHelp = false })
        } else {
            VStack(alignment: .center, spacing: 0) {
            HStack(spacing: 2) {
                Text(TUIIcon.info)
                    .foregroundColor(theme.primary)
                Text("About")
                    .foregroundColor(theme.primary)
                    .bold()
            }
            .padding(.vertical, 1)

            Divider()
                .foregroundColor(theme.border)

            Spacer()

            VStack(alignment: .center, spacing: 1) {
                logoView(asciiLogo, theme: theme)

                Text("Download Organizer")
                    .foregroundColor(theme.highlight)
                    .bold()

                Text("Version 1.1.0")
                    .foregroundColor(theme.textDim)

                Spacer().frame(height: 1)

                Group {
                    Text("A native macOS download organizer built with Swift 6.")
                        .foregroundColor(theme.textDim)
                    Text("Automatically categorizes and organizes files")
                        .foregroundColor(theme.textDim)
                    Text("in your Downloads folder using configurable rules.")
                        .foregroundColor(theme.textDim)
                }

                Spacer().frame(height: 1)

                Text("Tech Stack")
                    .foregroundColor(theme.accent)
                    .bold()

                VStack(alignment: .leading, spacing: 0) {
                    detailRow("Language", "Swift 6", theme: theme)
                    detailRow("Framework", "SwiftTUI", theme: theme)
                    detailRow("Database", "SQLite (WAL mode)", theme: theme)
                    detailRow("File Watching", "FSEvents / kqueue", theme: theme)
                    detailRow("Package Manager", "SwiftPM", theme: theme)
                    detailRow("Min. macOS", "14.0 (Sonoma)", theme: theme)
                }
                .padding(.horizontal)

                Spacer().frame(height: 1)

                Group {
                    Text("License")
                        .foregroundColor(theme.accent)
                        .bold()

                    Text("MIT License")
                        .foregroundColor(theme.textDim)

                    Text("© \(Calendar.current.component(.year, from: Date())) Download Organizer")
                        .foregroundColor(theme.textDim)
                }
            }

            Spacer()

            Divider()
                .foregroundColor(theme.border)

            HStack(spacing: 2) {
                Spacer()
                helpButton(theme: theme, action: { showHelp = true })
                homeButton(theme: theme)
            }
            .padding(.horizontal)
        }
        }
    }

    private func detailRow(_ label: String, _ value: String, theme: ThemeColors) -> some View {
        HStack(spacing: 1) {
            Text("  \(label):")
                .foregroundColor(theme.textDim)
            Text(value)
                .foregroundColor(theme.highlight)
        }
    }

    private func homeButton(theme: ThemeColors) -> some View {
        Button(action: onHome) {
            HStack(spacing: 1) {
                Text(TUIIcon.arrow)
                    .foregroundColor(theme.accent)
                Text("Back to Menu")
                    .foregroundColor(theme.accent)
                    .bold()
            }
        }
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
