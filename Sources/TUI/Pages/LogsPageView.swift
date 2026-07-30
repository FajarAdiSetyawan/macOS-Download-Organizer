@preconcurrency import SwiftTUI
import Foundation

public struct LogsPageView: View {
    let onHome: () -> Void
    @ObservedObject var store: TUIStore = .shared
    @State private var showHelp = false

    public init(onHome: @escaping () -> Void) {
        self.onHome = onHome
    }

    public var body: some View {
        let theme = ThemeManager.current
        let lines = store.logLines

        if showHelp {
            helpOverlay(theme: theme, onClose: { showHelp = false })
        } else {
            VStack(alignment: .leading, spacing: 0) {
            pageTitle("\(TUIIcon.logs) Logs", theme: theme)

            Divider()
                .foregroundColor(theme.border)

            HStack(spacing: 2) {
                Text("Log lines: \(lines.count)")
                    .foregroundColor(theme.textDim)
                Spacer()
            }
            .padding(.horizontal)

            Divider()
                .foregroundColor(theme.border)

            if lines.isEmpty {
                emptyState("No log entries.", theme: theme)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                            HStack(spacing: 1) {
                                Text("\(index + 1)")
                                    .foregroundColor(theme.textDim)
                                Text(line.isEmpty ? " " : line)
                                    .foregroundColor(theme.textDim)
                                Spacer()
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            }

            Spacer()

            Divider()
                .foregroundColor(theme.border)

            HStack(spacing: 2) {
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
