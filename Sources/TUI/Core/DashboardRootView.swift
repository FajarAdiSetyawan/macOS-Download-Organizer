@preconcurrency import SwiftTUI
import Foundation

public struct DashboardRootView: View {
    @State private var activePage: AppPage?

    public init() {}

    public var body: some View {
        Group {
            if let page = activePage {
                pageView(page)
            } else {
                MainMenuPage(onSelect: { page in activePage = page })
            }
        }
        .background(Color.trueColor(red: 32, green: 38, blue: 50))
        .onAppear {
            Task { @MainActor in
                await TUIStore.shared.bootstrap()
                await TUIStore.shared.refresh()
                TUIStore.shared.startAutoRefresh()
            }
        }
    }

    private func pageView(_ page: AppPage) -> some View {
        Group {
            switch page {
            case .dashboard: DashboardPageView(onHome: { activePage = nil })
            case .history: HistoryPageView(onHome: { activePage = nil })
            case .statistics: StatisticsPageView(onHome: { activePage = nil })
            case .configuration: ConfigurationPageView(onHome: { activePage = nil })
            case .rules: RulesPageView(onHome: { activePage = nil })
            case .simulator: SimulatorPageView(onHome: { activePage = nil })
            case .logs: LogsPageView(onHome: { activePage = nil })
            case .doctor: DoctorPageView(onHome: { activePage = nil })
            case .about: AboutPageView(onHome: { activePage = nil })
            }
        }
    }
}

public enum AppPage: CaseIterable, Hashable, Sendable {
    case dashboard
    case history
    case statistics
    case configuration
    case rules
    case simulator
    case logs
    case doctor
    case about

    public var title: String {
        switch self {
        case .dashboard: return "Dashboard"
        case .history: return "History"
        case .statistics: return "Statistics"
        case .configuration: return "Configuration"
        case .rules: return "Rules"
        case .simulator: return "Simulator"
        case .logs: return "Logs"
        case .doctor: return "Doctor"
        case .about: return "About"
        }
    }

    public var icon: String {
        switch self {
        case .dashboard: return TUIIcon.dashboard
        case .history: return TUIIcon.history
        case .statistics: return TUIIcon.stats
        case .configuration: return TUIIcon.config
        case .rules: return TUIIcon.rules
        case .simulator: return TUIIcon.search
        case .logs: return TUIIcon.logs
        case .doctor: return TUIIcon.doctor
        case .about: return TUIIcon.info
        }
    }
}
