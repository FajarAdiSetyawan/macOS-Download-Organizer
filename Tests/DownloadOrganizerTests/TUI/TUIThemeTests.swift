@preconcurrency import SwiftTUI
import Testing

@testable import DownloadOrganizer

@Suite("TUITheme Tests")
struct TUIThemeTests {
    @Test("TUIIcon all icons are non-empty")
    func allIconsNonEmpty() {
        #expect(!TUIIcon.running.isEmpty)
        #expect(!TUIIcon.stopped.isEmpty)
        #expect(!TUIIcon.arrow.isEmpty)
        #expect(!TUIIcon.bar.isEmpty)
        #expect(!TUIIcon.emptyBar.isEmpty)
        #expect(!TUIIcon.halfBar.isEmpty)
        #expect(!TUIIcon.warning.isEmpty)
        #expect(!TUIIcon.error.isEmpty)
        #expect(!TUIIcon.search.isEmpty)
        #expect(!TUIIcon.refresh.isEmpty)
        #expect(!TUIIcon.edit.isEmpty)
        #expect(!TUIIcon.save.isEmpty)
        #expect(!TUIIcon.delete.isEmpty)
        #expect(!TUIIcon.chevronRight.isEmpty)
        #expect(!TUIIcon.chevronDown.isEmpty)
        #expect(!TUIIcon.checkmark.isEmpty)
        #expect(!TUIIcon.crossmark.isEmpty)
        #expect(!TUIIcon.dashboard.isEmpty)
        #expect(!TUIIcon.history.isEmpty)
        #expect(!TUIIcon.stats.isEmpty)
        #expect(!TUIIcon.config.isEmpty)
        #expect(!TUIIcon.rules.isEmpty)
        #expect(!TUIIcon.logs.isEmpty)
        #expect(!TUIIcon.doctor.isEmpty)
    }

    @Test("ThemeManager dark theme has all colors")
    func darkThemeHasAllColors() {
        let theme = ThemeManager.dark
        #expect(theme.primary != Color.default)
        #expect(theme.accent != Color.default)
        #expect(theme.success != Color.default)
        #expect(theme.warning != Color.default)
        #expect(theme.error != Color.default)
        #expect(theme.highlight != Color.default)
    }

    @Test("ThemeManager activate switches theme")
    func activateSwitchesTheme() {
        ThemeManager.activate("light")
        #expect(ThemeManager.current.primary == ThemeManager.light.primary)
        ThemeManager.activate("nord")
        #expect(ThemeManager.current.primary == ThemeManager.nord.primary)
        ThemeManager.activate("gruvbox")
        #expect(ThemeManager.current.primary == ThemeManager.gruvbox.primary)
        ThemeManager.activate("dracula")
        #expect(ThemeManager.current.primary == ThemeManager.dracula.primary)
        ThemeManager.activate("dark")
        #expect(ThemeManager.current.primary == ThemeManager.dark.primary)
    }

    @Test("ThemeManager unknown theme defaults to dark")
    func unknownThemeDefaultsToDark() {
        ThemeManager.activate("unknown")
        #expect(ThemeManager.current.primary == ThemeManager.dark.primary)
        ThemeManager.activate("dark")
    }

    @Test("All theme colors are properly initialized")
    func allThemesInitialized() {
        for theme in [ThemeManager.dark, ThemeManager.light, ThemeManager.nord, ThemeManager.gruvbox, ThemeManager.dracula] {
            #expect(theme.primary != Color.default)
            #expect(theme.accent != Color.default)
            #expect(theme.success != Color.default)
            #expect(theme.warning != Color.default)
            #expect(theme.error != Color.default)
            #expect(theme.muted != Color.default)
            #expect(theme.highlight != Color.default)
            #expect(theme.text != Color.default)
            #expect(theme.textDim != Color.default)
        }
    }
}
