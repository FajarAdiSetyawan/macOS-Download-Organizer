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

        if showHelp {
            helpOverlay(theme: theme, onClose: { showHelp = false })
        } else {
            VStack(alignment: .leading, spacing: 0) {
            pageTitle("\(TUIIcon.stats) Statistics", theme: theme)

            Divider()
                .foregroundColor(theme.border)

            VStack(alignment: .leading, spacing: 0) {
                sectionTitle("Overview", theme: theme)

                HStack(spacing: 4) {
                    metricCard(
                        "Total Files",
                        "\(totalCount)",
                        theme: theme
                    )
                    metricCard(
                        "Categories",
                        "\(sorted.count)",
                        theme: theme
                    )
                    metricCard(
                        "Today",
                        "\(store.movedToday)",
                        theme: theme
                    )
                }
                .padding(.horizontal)

                Divider()
                    .foregroundColor(theme.border)

                sectionTitle("By Category", theme: theme)

                if sorted.isEmpty {
                    emptyState("No statistics yet.", theme: theme)
                } else {
                    let maxCount = sorted.first?.value ?? 1
                    ScrollView {
                            VStack(alignment: .leading, spacing: 0) {
                            ForEach(sorted, id: \.0) { category, count in
                                categoryBar(
                                    category: category,
                                    count: count,
                                    maxCount: maxCount,
                                    totalCount: totalCount,
                                    theme: theme
                                )
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
                themeButton(theme: theme)
                homeButton(theme: theme, action: onHome)
            }
            .padding(.horizontal)
        }
        }
    }

    private func metricCard(_ label: String, _ value: String, theme: ThemeColors) -> some View {
        VStack(alignment: .center, spacing: 0) {
            Text(value)
                .foregroundColor(theme.highlight)
                .bold()
            Text(label)
                .foregroundColor(theme.textDim)
        }
        .padding(.horizontal, 2)
        .padding(.vertical, 1)
        .border(theme.border)
    }

    private func categoryBar(
        category: String,
        count: Int,
        maxCount: Int,
        totalCount: Int,
        theme: ThemeColors
    ) -> some View {
        let barWidth = max(
            Double(count) / Double(maxCount) * 40,
            1
        )
        let bar = String(repeating: TUIIcon.bar, count: Int(barWidth))

        return VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 1) {
                Text("  \(category)")
                    .foregroundColor(theme.textDim)
                Spacer()
                Text("\(count)")
                    .foregroundColor(theme.highlight)
                    .bold()
                if totalCount > 0 {
                    Text("(\(100 * count / totalCount)%)")
                        .foregroundColor(theme.textDim)
                }
            }
            .padding(.horizontal)

            Text("    \(bar)")
                .foregroundColor(theme.accent)
                .padding(.horizontal)
        }
        .padding(.vertical, 1)
    }
}
