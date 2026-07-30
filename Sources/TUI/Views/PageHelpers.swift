@preconcurrency import SwiftTUI
import Foundation

func pageTitle(_ text: String, theme: ThemeColors) -> some View {
    HStack(spacing: 2) {
        Text(text)
            .foregroundColor(theme.primary)
            .bold()
        Spacer()
    }
    .padding(.horizontal)
    .padding(.vertical, 1)
}

func sectionTitle(_ text: String, theme: ThemeColors) -> some View {
    Text("\(TUIIcon.chevronRight) \(text)")
        .foregroundColor(theme.primary)
        .bold()
        .padding(.horizontal, 2)
        .padding(.vertical, 1)
}

func keyHint(_ key: String, _ desc: String, theme: ThemeColors) -> some View {
    HStack(spacing: 0) {
        Text(key)
            .foregroundColor(theme.primary)
            .bold()
        Text(" \(desc)")
            .foregroundColor(theme.textDim)
    }
}

func homeButton(theme: ThemeColors, action: @escaping () -> Void) -> some View {
    Button(action: action) {
        HStack(spacing: 1) {
            Text(TUIIcon.arrow)
                .foregroundColor(theme.accent)
            Text("Back to Menu")
                .foregroundColor(theme.accent)
                .bold()
        }
    }
}

func infoRow(_ label: String, _ value: String, theme: ThemeColors) -> some View {
    HStack(spacing: 2) {
        Text("  ")
        Text(label)
            .foregroundColor(theme.textDim)
        Text(value)
            .foregroundColor(theme.accent)
    }
    .padding(.horizontal)
    .padding(.vertical, 1)
}

func detailRow(_ label: String, _ value: String, theme: ThemeColors) -> some View {
    HStack(spacing: 1) {
        Text("  \(label):")
            .foregroundColor(theme.textDim)
        Text(value)
            .foregroundColor(theme.highlight)
    }
}

func emptyState(_ message: String, theme: ThemeColors) -> some View {
    VStack {
        Spacer()
        Text(message)
            .foregroundColor(theme.textDim)
        Spacer()
    }
}

func asciiLines(_ art: String) -> [String] {
    art.components(separatedBy: "\n")
}

func logoView(_ art: String, theme: ThemeColors) -> some View {
    VStack(spacing: 0) {
        ForEach(asciiLines(art), id: \.self) { line in
            Text(line)
                .foregroundColor(theme.primary)
                .bold()
        }
    }
}

let themeNames: [String] = ["dark", "light", "nord", "gruvbox", "dracula"]

var currentThemeName: String {
    let current = ThemeManager.current
    if current == ThemeManager.dark { return "dark" }
    if current == ThemeManager.light { return "light" }
    if current == ThemeManager.nord { return "nord" }
    if current == ThemeManager.gruvbox { return "gruvbox" }
    if current == ThemeManager.dracula { return "dracula" }
    return "dark"
}

func cycleTheme() {
    let names = themeNames
    let current = currentThemeName
    let idx = names.firstIndex(of: current) ?? 0
    let next = names[(idx + 1) % names.count]
    ThemeManager.activate(next)
}

func themeButton(theme: ThemeColors) -> some View {
    Button(action: cycleTheme) {
        Text(currentThemeName)
            .foregroundColor(theme.primary)
            .bold()
    }
}

func helpButton(theme: ThemeColors, action: @escaping () -> Void) -> some View {
    Button(action: action) {
        Text("?")
            .foregroundColor(theme.primary)
            .bold()
    }
}

func helpOverlay(theme: ThemeColors, onClose: @escaping () -> Void) -> some View {
    VStack(spacing: 0) {
        HStack(spacing: 2) {
            Text("Keyboard Shortcuts")
                .foregroundColor(theme.primary)
                .bold()
            Spacer()
            Button(action: onClose) {
                Text(TUIIcon.crossmark)
                    .foregroundColor(theme.error)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 1)

        Divider().foregroundColor(theme.border)

        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                shortcutRow("↑↓", "Navigate", theme: theme)
                shortcutRow("Enter", "Select / Edit", theme: theme)
                shortcutRow("R", "Refresh", theme: theme)
                shortcutRow("Q", "Quit", theme: theme)
                shortcutRow("T", "Cycle Theme", theme: theme)
                shortcutRow("/", "Search (History)", theme: theme)
                shortcutRow("?", "This help", theme: theme)
                shortcutRow("B", "Browse (Config)", theme: theme)
            }
        }

        Divider().foregroundColor(theme.border)

        Button(action: onClose) {
            Text("  Close  ")
                .foregroundColor(theme.accent)
                .bold()
        }
        .padding(.vertical, 1)
    }
}

private func shortcutRow(_ key: String, _ desc: String, theme: ThemeColors) -> some View {
    HStack(spacing: 2) {
        Text("  ")
        Text(key)
            .foregroundColor(theme.primary)
            .bold()
        Text(desc)
            .foregroundColor(theme.textDim)
        Spacer()
    }
    .padding(.horizontal)
    .padding(.vertical, 1)
}
