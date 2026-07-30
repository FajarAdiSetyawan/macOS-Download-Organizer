@preconcurrency import SwiftTUI
import Foundation

public struct StatisticsPageView: View {
    let onHome: () -> Void
    @ObservedObject var store: TUIStore = .shared
    @State private var showHelp = false
    @State private var catStats: [TUIStore.CatStat] = []
    @State private var confirmDelete = false

    public init(onHome: @escaping () -> Void) {
        self.onHome = onHome
    }

    public var body: some View {
        let theme = ThemeManager.current
        let maxCount = catStats.map(\.count).max() ?? 1

        Group {
            if showHelp {
                helpOverlay(theme: theme, onClose: { showHelp = false })
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    pageTitle("\(TUIIcon.stats) Statistics", theme: theme)

                    Divider()
                        .foregroundColor(theme.border)

                    sectionTitle("Per Folder", theme: theme)

                    if catStats.isEmpty {
                        emptyState("No data yet.", theme: theme)
                    } else {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 0) {
                                ForEach(Array(catStats.enumerated()), id: \.offset) { _, cs in
                                    folderRow(cs: cs, maxCount: maxCount, theme: theme)
                                    Divider()
                                        .foregroundColor(theme.border)
                                }

                            }
                        }
                    }

                    Spacer()

                    if confirmDelete {
                        HStack(spacing: 2) {
                            Text("Delete all history?")
                                .foregroundColor(theme.warning)
                            Button(action: {
                                Task { await store.deleteAllHistory() }
                                confirmDelete = false
                                catStats = []
                            }) {
                                Text("Yes")
                                    .foregroundColor(theme.error)
                                    .bold()
                            }
                            Button(action: { confirmDelete = false }) {
                                Text("No")
                                    .foregroundColor(theme.textDim)
                            }
                            Spacer()
                        }
                        .padding(.horizontal)
                        Divider()
                            .foregroundColor(theme.border)
                    }

                    Divider()
                        .foregroundColor(theme.border)

                    HStack(spacing: 2) {
                        keyHint("R", "Refresh", theme: theme)
                        Button(action: { confirmDelete = true }) {
                            Text("Clear")
                                .foregroundColor(theme.error)
                                .bold()
                        }
                        Spacer()
                        helpButton(theme: theme, action: { showHelp = true })
                        homeButton(theme: theme, action: onHome)
                    }
                    .padding(.horizontal)
                }
            }
        }
        .onAppear { Task { await loadStats() } }
    }

    private func loadStats() async {
        catStats = await store.detailedStatistics()
    }

    private func folderRow(cs: TUIStore.CatStat, maxCount: Int, theme: ThemeColors) -> some View {
        let barLen = max(Double(cs.count) / Double(maxCount) * 25, cs.count > 0 ? 1 : 0)
        let bar = String(repeating: TUIIcon.bar, count: Int(barLen))
        let barColor: Color = {
            switch cs.count {
            case 0: return theme.textDim
            case 1..<5: return theme.primary
            case 5..<20: return theme.accent
            default: return theme.success
            }
        }()

        return VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 1) {
                Text("  \(cs.category)")
                    .foregroundColor(cs.count > 0 ? theme.textDim : theme.textDim)
                Spacer()
                if cs.totalSize > 0 {
                    Text(formatByte(cs.totalSize))
                        .foregroundColor(theme.primary)
                }
                if cs.count > 0 {
                    Text("\(cs.count)")
                        .foregroundColor(theme.highlight)
                        .bold()
                } else {
                    Text("-")
                        .foregroundColor(theme.textDim)
                }
            }
            .padding(.horizontal)

            if cs.count > 0 {
                Text("    \(bar)")
                    .foregroundColor(barColor)
                    .padding(.horizontal)
            }
        }
        .padding(.vertical, 1)
    }

    private func formatByte(_ bytes: Int64) -> String {
        let f = ByteCountFormatter()
        f.countStyle = .file
        return f.string(fromByteCount: bytes)
    }
}
