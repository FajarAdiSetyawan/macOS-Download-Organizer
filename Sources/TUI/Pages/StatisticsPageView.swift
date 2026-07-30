@preconcurrency import SwiftTUI
import Foundation

public struct StatisticsPageView: View {
    let onHome: () -> Void
    @ObservedObject var store: TUIStore = .shared
    @State private var showHelp = false
    @State private var catStats: [TUIStore.CatStat] = []
    @State private var totalSize: Int64 = 0

    public init(onHome: @escaping () -> Void) {
        self.onHome = onHome
    }

    public var body: some View {
        let theme = ThemeManager.current
        let totalFiles = catStats.reduce(0) { $0 + $1.count }
        let maxCount = catStats.map(\.count).max() ?? 1
        let maxSize = catStats.map(\.totalSize).max() ?? 1

        Group {
            if showHelp {
                helpOverlay(theme: theme, onClose: { showHelp = false })
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    pageTitle("\(TUIIcon.stats) Statistics", theme: theme)

                    Divider()
                        .foregroundColor(theme.border)

                    sectionTitle("Overview", theme: theme)

                    HStack(spacing: 4) {
                        statBox("\(totalFiles)", "Files", color: theme.highlight, theme: theme)
                        statBox("\(catStats.count)", "Folders", color: theme.accent, theme: theme)
                        statBox("\(store.movedToday)", "Today", color: theme.success, theme: theme)
                        statBox(formatByte(totalSize), "Total Size", color: theme.primary, theme: theme)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 1)

                    Divider()
                        .foregroundColor(theme.border)

                    sectionTitle("Per Folder", theme: theme)

                    if catStats.isEmpty {
                        emptyState("No data yet.", theme: theme)
                    } else {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 0) {
                                ForEach(Array(catStats.enumerated()), id: \.offset) { _, cs in
                                    folderRow(cs: cs, maxCount: maxCount, maxSize: maxSize, theme: theme)
                                    Divider()
                                        .foregroundColor(theme.border)
                                }
                                HStack(spacing: 1) {
                                    Text("  Total")
                                        .foregroundColor(theme.textDim)
                                        .bold()
                                    Spacer()
                                    if totalSize > 0 {
                                        Text(formatByte(totalSize))
                                            .foregroundColor(theme.primary)
                                            .bold()
                                    }
                                    Text("\(totalFiles)")
                                        .foregroundColor(theme.highlight)
                                        .bold()
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 1)
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
        .onAppear { Task { await loadStats() } }
    }

    private func loadStats() async {
        catStats = await store.detailedStatistics()
        totalSize = catStats.reduce(0) { $0 + $1.totalSize }
    }

    private func statBox(_ value: String, _ label: String, color: Color, theme: ThemeColors) -> some View {
        VStack(alignment: .center, spacing: 0) {
            Text(value)
                .foregroundColor(color)
                .bold()
            Text(label)
                .foregroundColor(theme.textDim)
        }
        .frame(minWidth: 10)
        .padding(.horizontal, 3)
        .padding(.vertical, 1)
        .border(theme.border)
    }

    private func folderRow(cs: TUIStore.CatStat, maxCount: Int, maxSize: Int64, theme: ThemeColors) -> some View {
        let pct = totalSize > 0 ? 100 * cs.totalSize / totalSize : 0
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
