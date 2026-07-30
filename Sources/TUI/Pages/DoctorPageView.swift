@preconcurrency import SwiftTUI
import Foundation

public struct DoctorPageView: View {
    let onHome: () -> Void
    @ObservedObject var store: TUIStore = .shared
    @State private var showHelp = false

    public init(onHome: @escaping () -> Void) {
        self.onHome = onHome
    }

    public var body: some View {
        let theme = ThemeManager.current
        let checks = store.doctorChecks
        let okCount = checks.filter { $0.severity == .ok }.count
        let warnCount = checks.filter { $0.severity == .warning }.count
        let failCount = checks.filter { $0.severity == .fatal }.count

        if showHelp {
            helpOverlay(theme: theme, onClose: { showHelp = false })
        } else {
            VStack(alignment: .leading, spacing: 0) {
            pageTitle("\(TUIIcon.doctor) Doctor", theme: theme)

            Divider()
                .foregroundColor(theme.border)

            HStack(spacing: 2) {
                Text("\(okCount) OK")
                    .foregroundColor(theme.success)
                Text("\(warnCount) Warning")
                    .foregroundColor(theme.warning)
                Text("\(failCount) Fatal")
                    .foregroundColor(theme.error)
                Spacer()
                Button(action: { Task { await store.runDoctorChecks() } }) {
                    Text("Run All")
                        .foregroundColor(theme.primary)
                        .bold()
                }
            }
            .padding(.horizontal)

            Divider()
                .foregroundColor(theme.border)

            if checks.isEmpty {
                emptyState("Run doctor checks to see results.", theme: theme)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(checks, id: \.title) { check in
                            checkRow(check: check, theme: theme)
                            Divider()
                                .foregroundColor(theme.border)
                        }
                    }
                }
            }

            Spacer()

            Divider()
                .foregroundColor(theme.border)

            HStack(spacing: 2) {
                keyHint("R", "Run All", theme: theme)
                keyHint("C", "Clear", theme: theme)
                Spacer()
                helpButton(theme: theme, action: { showHelp = true })
                homeButton(theme: theme, action: onHome)
            }
            .padding(.horizontal)
        }
        }
    }

    private func checkRow(check: DoctorCheck, theme: ThemeColors) -> some View {
        let icon: String
        let color: Color
        switch check.severity {
        case .ok:
            icon = TUIIcon.checkmark
            color = theme.success
        case .warning:
            icon = TUIIcon.warning
            color = theme.warning
        case .fatal:
            icon = TUIIcon.crossmark
            color = theme.error
        }

        return VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 1) {
                Text(icon)
                    .foregroundColor(color)
                Text(check.title)
                    .foregroundColor(color)
                    .bold()
                Spacer()
            }
            .padding(.horizontal)

            if let msg = check.message, !msg.isEmpty {
                Text("    \(msg)")
                    .foregroundColor(theme.textDim)
                    .padding(.horizontal)
            }
        }
        .padding(.vertical, 1)
    }
}
