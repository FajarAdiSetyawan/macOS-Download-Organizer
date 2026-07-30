@preconcurrency import SwiftTUI
import Foundation

public struct SimulatorPageView: View {
    let onHome: () -> Void
    @State private var showHelp = false
    @State private var filenameInput = ""
    @State private var result: (filename: String, category: String)?
    @State private var history: [(filename: String, category: String)] = []

    public init(onHome: @escaping () -> Void) {
        self.onHome = onHome
    }

    public var body: some View {
        let theme = ThemeManager.current

        if showHelp {
            helpOverlay(theme: theme, onClose: { showHelp = false })
        } else {
            VStack(alignment: .leading, spacing: 0) {
                pageTitle("\(TUIIcon.search) Rule Simulator", theme: theme)

                Divider()
                    .foregroundColor(theme.border)

                VStack(alignment: .leading, spacing: 0) {
                    sectionTitle("Test a File", theme: theme)

                    HStack(spacing: 1) {
                        Text("Filename:")
                            .foregroundColor(theme.textDim)
                        TextField(placeholder: "e.g. photo.jpg or song.mp3", action: { val in
                            filenameInput = val
                            simulate(val)
                        })
                        Button(action: { simulate(filenameInput) }) {
                            Text("Test")
                                .foregroundColor(theme.primary)
                                .bold()
                        }
                    }
                    .padding(.horizontal)
                }

                if let r = result {
                    Divider()
                        .foregroundColor(theme.border)

                    VStack(alignment: .leading, spacing: 0) {
                        sectionTitle("Result", theme: theme)

                        HStack(spacing: 1) {
                            Text(r.filename)
                                .foregroundColor(theme.highlight)
                            Text("→")
                                .foregroundColor(theme.textDim)
                            Text(r.category)
                                .foregroundColor(theme.accent)
                                .bold()
                        }
                        .padding(.horizontal)
                    }
                }

                Divider()
                    .foregroundColor(theme.border)

                VStack(alignment: .leading, spacing: 0) {
                    sectionTitle("Recent Tests", theme: theme)

                    if history.isEmpty {
                        emptyState("No tests yet.", theme: theme)
                    } else {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 0) {
                                ForEach(Array(history.enumerated()), id: \.offset) { _, entry in
                                    HStack(spacing: 1) {
                                        Text(entry.filename)
                                            .foregroundColor(theme.textDim)
                                        Text("→")
                                            .foregroundColor(theme.textDim)
                                        Text(entry.category)
                                            .foregroundColor(theme.accent)
                                            .bold()
                                        Spacer()
                                    }
                                    .padding(.horizontal)
                                    .padding(.vertical, 1)
                                }
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

    private func simulate(_ input: String) {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        Task {
            let ext: String
            if trimmed.contains(".") {
                ext = String(trimmed.split(separator: ".").last ?? "")
            } else {
                ext = trimmed
            }
            let category = await RuleEngine.shared.categoryName(forExtension: ext)
            let entry = (filename: trimmed, category: category)
            result = entry
            history.insert(entry, at: 0)
            if history.count > 20 {
                history.removeLast()
            }
            filenameInput = ""
        }
    }
}
