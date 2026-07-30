@preconcurrency import SwiftTUI
import Foundation

public struct StatisticsPageView: View {
    let onHome: () -> Void
    @ObservedObject var store: TUIStore = .shared
    @State private var showHelp = false

    public init(onHome: @escaping () -> Void) {
        self.onHome = onHome
    }

    public var body: some View {
        let theme = ThemeManager.current
        let stats = store.statistics
        let totalCount = stats.values.reduce(0, +)
        let sorted = stats.sorted { $0.value > $1.value }
        let maxCount = sorted.first?.value ?? 1

        if showHelp {
            helpOverlay(theme: theme, onClose: { showHelp = false })
        } else {
            VStack(alignment: .leading, spacing: 0) {
                pageTitle("\(TUIIcon.stats) Statistics", theme: theme)

                Divider()
                    .foregroundColor(theme.border)

                sectionTitle("Overview", theme: theme)

                HStack(spacing: 4) {
                    statBox("\(totalCount)", "Total Files", color: theme.highlight, theme: theme)
                    statBox("\(sorted.count)", "Categories", color: theme.accent, theme: theme)
                    statBox("\(store.movedToday)", "Today", color: theme.success, theme: theme)
                }
                .padding(.horizontal)
                .padding(.vertical, 1)

                Divider()
                    .foregroundColor(theme.border)

                sectionTitle("By Category", theme: theme)

                if sorted.isEmpty {
                    emptyState("No statistics yet.", theme: theme)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(sorted, id: \.0) { category, count in
                                categoryRow(
                                    category: category,
                                    count: count,
                                    maxCount: maxCount,
                                    totalCount: totalCount,
                                    theme: theme
                                )
                                Divider()
                                    .foregroundColor(theme.border)
                            }
                            HStack(spacing: 1) {
                                Text("  Total")
                                    .foregroundColor(theme.textDim)
                                    .bold()
                                Spacer()
                                Text("\(totalCount)")
                                    .foregroundColor(theme.highlight)
                                    .bold()
                                Text("(100%)")
                                    .foregroundColor(theme.textDim)
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

    private func categoryRow(
        category: String,
        count: Int,
        maxCount: Int,
        totalCount: Int,
        theme: ThemeColors
    ) -> some View {
        let pct = totalCount > 0 ? 100 * count / totalCount : 0
        let barLen = max(Double(count) / Double(maxCount) * 30, 1)
        let bar = String(repeating: TUIIcon.bar, count: Int(barLen))
        let barColor: Color = {
            switch pct {
            case 0..<5: return theme.textDim
            case 5..<15: return theme.primary
            case 15..<30: return theme.accent
            default: return theme.success
            }
        }()

        return VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 1) {
                Text("  \(category)")
                    .foregroundColor(theme.textDim)
                Spacer()
                if pct > 0 {
                    Text("\(pct)%")
                        .foregroundColor(barColor)
                        .bold()
                }
                Text("\(count)")
                    .foregroundColor(theme.highlight)
                    .bold()
            }
            .padding(.horizontal)

            Text("    \(bar)")
                .foregroundColor(barColor)
                .padding(.horizontal)
        }
        .padding(.vertical, 1)
    }
}
