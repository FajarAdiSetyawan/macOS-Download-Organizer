@preconcurrency import SwiftTUI
import Foundation

public enum SortBy: String, Sendable, CaseIterable {
    case date = "Date"
    case name = "Name"
    case size = "Size"
}

public struct HistoryPageView: View {
    let onHome: () -> Void
    @ObservedObject var store: TUIStore = .shared
    @State private var searchQuery: String = ""
    @State private var selectedIndex: Int = 0
    @State private var statusFilter: String? = nil
    @State private var sortBy: SortBy = .date
    @State private var showHelp: Bool = false
    @State private var bulkUndoCount: Int = 1

    public init(onHome: @escaping () -> Void) {
        self.onHome = onHome
    }

    public var body: some View {
        let theme = ThemeManager.current
        let allRecords = store.allRecords

        let filtered = allRecords
            .filter { record in
                if let f = statusFilter, record.status.lowercased() != f { return false }
                guard !searchQuery.isEmpty else { return true }
                return record.filename.lowercased().contains(searchQuery.lowercased())
                    || record.category.lowercased().contains(searchQuery.lowercased())
                    || record.fileExtension.lowercased().contains(searchQuery.lowercased())
            }
            .sorted { a, b in
                switch sortBy {
                case .date: return a.movedAt > b.movedAt
                case .name: return a.filename.lowercased() < b.filename.lowercased()
                case .size: return a.fileSize > b.fileSize
                }
            }

        Group {
            if showHelp {
                helpOverlay(theme: theme, onClose: { showHelp = false })
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    pageTitle("\(TUIIcon.history) History", theme: theme)

                    HStack(spacing: 2) {
                        Text("\(filtered.count) records")
                            .foregroundColor(theme.textDim)
                        Spacer()
                        if !searchQuery.isEmpty {
                            Text("\"\(searchQuery)\"")
                                .foregroundColor(theme.accent)
                        }
                    }
                    .padding(.horizontal)

                    Divider().foregroundColor(theme.border)

                    HStack(spacing: 1) {
                        ForEach(["all", "moved", "restored", "failed"], id: \.self) { s in
                            Button(action: {
                                statusFilter = s == "all" ? nil : s
                                selectedIndex = 0
                            }) {
                                Text(s == "all" ? "All" : s)
                                    .foregroundColor(statusFilter == (s == "all" ? nil : s) ? theme.highlight : theme.textDim)
                                    .bold(statusFilter == (s == "all" ? nil : s))
                            }
                            if s != "failed" { Text("|").foregroundColor(theme.textDim) }
                        }
                        Spacer()
                        ForEach(SortBy.allCases, id: \.self) { s in
                            Button(action: { sortBy = s; selectedIndex = 0 }) {
                                Text(sortBy == s ? "\(TUIIcon.chevronDown) \(s.rawValue)" : s.rawValue)
                                    .foregroundColor(sortBy == s ? theme.accent : theme.textDim)
                                    .bold(sortBy == s)
                            }
                        }
                    }
                    .padding(.horizontal)

                    Divider().foregroundColor(theme.border)

                    if filtered.isEmpty {
                        VStack {
                            Spacer()
                            Text("No records found.")
                                .foregroundColor(theme.textDim)
                            Spacer()
                        }
                    } else {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 0) {
                                let f = dateFormatter()
                                ForEach(
                                    Array(filtered.enumerated()),
                                    id: \.element.id
                                ) { index, record in
                                    recordRow(
                                        record: record,
                                        isSelected: index == selectedIndex,
                                        formatter: f,
                                        theme: theme
                                    )
                                    Divider().foregroundColor(theme.border)
                                }
                            }
                        }
                    }

                    Divider().foregroundColor(theme.border)

                    HStack(spacing: 2) {
                        keyHint("↑↓", "Scroll", theme: theme)
                        keyHint("/", "Search", theme: theme)
                        keyHint("R", "Refresh", theme: theme)
                        Group {
                            Button(action: { Task { await store.undoLastMove() } }) {
                                Text("Undo").foregroundColor(theme.warning).bold()
                            }
                            Button(action: {
                                if bulkUndoCount > 1 { bulkUndoCount -= 1 }
                            }) {
                                Text("-").foregroundColor(theme.textDim).bold()
                            }
                            Text("\(bulkUndoCount)")
                                .foregroundColor(theme.highlight)
                                .bold()
                            Button(action: { bulkUndoCount += 1 }) {
                                Text("+").foregroundColor(theme.textDim).bold()
                            }
                            Button(action: { Task { await store.undoLastMoves(count: bulkUndoCount) } }) {
                                Text("Undo \(bulkUndoCount)")
                                    .foregroundColor(theme.warning)
                                    .bold()
                            }
                        }
                        Spacer()
                        Group {
                            helpButton(theme: theme, action: { showHelp = true })
                            themeButton(theme: theme)
                            homeButton(theme: theme, action: onHome)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }

    private func recordRow(
        record: MoveRecord,
        isSelected: Bool,
        formatter: DateFormatter,
        theme: ThemeColors
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 1) {
                Text(isSelected ? TUIIcon.chevronRight : " ")
                    .foregroundColor(theme.accent)
                Text(record.filename)
                    .foregroundColor(isSelected ? theme.highlight : theme.textDim)
                    .bold(isSelected)
                Spacer()
                Text(formatter.string(from: record.movedAt))
                    .foregroundColor(theme.textDim)
            }
            .padding(.horizontal)

            HStack(spacing: 1) {
                Text("   \(TUIIcon.arrow)")
                    .foregroundColor(theme.accent)
                Text(record.category)
                    .foregroundColor(theme.success)
                Text("  .\(record.fileExtension)")
                    .foregroundColor(theme.textDim)
                Spacer()
                Text(record.status)
                    .foregroundColor(statusColor(record.status, theme: theme))
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 1)
    }

    private func statusColor(_ status: String, theme: ThemeColors) -> Color {
        switch status.lowercased() {
        case "moved": return theme.success
        case "restored": return theme.warning
        case "failed": return theme.error
        default: return theme.textDim
        }
    }

    private func dateFormatter() -> DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm"
        return f
    }
}
