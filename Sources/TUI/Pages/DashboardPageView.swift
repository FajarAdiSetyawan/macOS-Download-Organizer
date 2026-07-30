@preconcurrency import SwiftTUI
import Foundation

public struct DashboardPageView: View {
    let onHome: () -> Void
    @ObservedObject var store: TUIStore = .shared

    public init(onHome: @escaping () -> Void) {
        self.onHome = onHome
    }

    public var body: some View {
        let theme = ThemeManager.current

        VStack(alignment: .leading, spacing: 0) {
            pageTitle("\(TUIIcon.dashboard) Dashboard", theme: theme)

            Divider()
                .foregroundColor(theme.border)

            HStack(alignment: .top, spacing: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    sectionTitle("Status", theme: theme)

                    Group {
                        statusRow(store.serviceRunning, text: store.serviceRunning ? "Running" : "Stopped", theme: theme)
                        infoRow("Watching", store.watchFolder, theme: theme)
                    }

                    Divider()
                        .foregroundColor(theme.border)

                    sectionTitle("Today", theme: theme)

                    let stats = store.statistics
                    if stats.isEmpty {
                        Text("  No files moved yet")
                            .foregroundColor(theme.textDim)
                            .padding(.horizontal)
                    } else {
                        let sorted = stats.sorted { $0.value > $1.value }.prefix(8)
                        ForEach(sorted.map { ($0.key, $0.value) }, id: \.0) { pair in
                            let (cat, count) = pair
                            HStack(spacing: 1) {
                                Text("  ")
                                Text(cat)
                                    .foregroundColor(theme.textDim)
                                Spacer()
                                Text("\(count)")
                                    .foregroundColor(theme.highlight)
                                    .bold()
                            }
                            .padding(.horizontal)
                        }
                    }

                    Spacer()
                }

                Divider()
                    .foregroundColor(theme.border)

                VStack(alignment: .leading, spacing: 0) {
                    sectionTitle("Recent Activity", theme: theme)

                    let records = store.recentRecords
                    if records.isEmpty {
                        Text("  No recent activity")
                            .foregroundColor(theme.textDim)
                            .padding(.horizontal)
                    } else {
                        let f = timeFormatter()
                        ForEach(records.prefix(8), id: \.id) { record in
                            VStack(alignment: .leading, spacing: 0) {
                                HStack(spacing: 1) {
                                    Text("  ")
                                    Text(f.string(from: record.movedAt))
                                        .foregroundColor(theme.textDim)
                                    Text(record.filename)
                                        .foregroundColor(theme.highlight)
                                    Spacer()
                                }
                                HStack(spacing: 1) {
                                    Text("    \(TUIIcon.arrow)")
                                        .foregroundColor(theme.accent)
                                    Text(record.category)
                                        .foregroundColor(theme.success)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }

                    Divider()
                        .foregroundColor(theme.border)

                    sectionTitle("Metrics", theme: theme)

                    HStack(spacing: 0) {
                        metricsColumn([
                            ("Memory", store.memoryUsage),
                            ("CPU", store.cpuUsage),
                            ("Queue", "\(store.queueCount)"),
                            ("Rules", "\(store.rulesCount)"),
                        ], theme: theme)
                        metricsColumn([
                            ("Database", store.databaseHealthy ? "Healthy" : "Unavailable"),
                            ("Uptime", store.uptime),
                            ("Today", "\(store.movedToday) files"),
                        ], theme: theme)
                    }

                    Spacer()
                }
            }

            Divider()
                .foregroundColor(theme.border)

            HStack(spacing: 2) {
                keyHint("R", "Refresh", theme: theme)
                Button(action: { Task { await store.undoLastMove() } }) {
                    Text("Undo").foregroundColor(theme.warning).bold()
                }
                Button(action: { Task { _ = await store.organizeNow() } }) {
                    Text("Organize").foregroundColor(theme.success).bold()
                }
                Spacer()
                Button(action: { store.toggleAutoRefresh() }) {
                    Text(store.autoRefresh ? "⏺" : "⏹")
                        .foregroundColor(store.autoRefresh ? theme.success : theme.error)
                }
                themeButton(theme: theme)
                homeButton(theme: theme, action: onHome)
            }
            .padding(.horizontal)
        }
    }

    private func statusRow(_ flag: Bool, text: String, theme: ThemeColors) -> some View {
        HStack(spacing: 2) {
            Text("  ")
            Text(flag ? TUIIcon.running : TUIIcon.stopped)
                .foregroundColor(flag ? theme.success : theme.error)
            Text(text)
                .foregroundColor(flag ? theme.success : theme.error)
                .bold()
        }
        .padding(.horizontal)
    }

    private func infoRow(_ label: String, _ value: String, theme: ThemeColors) -> some View {
        HStack(spacing: 2) {
            Text("  ")
            Text(label)
                .foregroundColor(theme.textDim)
            Text(value)
                .foregroundColor(theme.accent)
        }
        .padding(.horizontal)
    }

    private func metricsColumn(_ metrics: [(String, String)], theme: ThemeColors) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            ForEach(metrics, id: \.0) { label, value in
                HStack(spacing: 1) {
                    Text("  ")
                    Text(label)
                        .foregroundColor(theme.textDim)
                    Spacer()
                    Text(value)
                        .foregroundColor(theme.highlight)
                }
            }
        }
    }

    private func sectionTitle(_ text: String, theme: ThemeColors) -> some View {
        Text("\(TUIIcon.chevronRight) \(text)")
            .foregroundColor(theme.primary)
            .bold()
            .padding(.horizontal)
            .padding(.vertical, 1)
    }

    private func keyHint(_ key: String, _ desc: String, theme: ThemeColors) -> some View {
        HStack(spacing: 0) {
            Text(key)
                .foregroundColor(theme.primary)
                .bold()
            Text(" \(desc)")
                .foregroundColor(theme.textDim)
        }
    }

    private func timeFormatter() -> DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }
}
