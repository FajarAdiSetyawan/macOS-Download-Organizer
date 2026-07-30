@preconcurrency import SwiftTUI

public struct ThemeColors: Equatable, Sendable {
    public var primary: Color
    public var accent: Color
    public var success: Color
    public var warning: Color
    public var error: Color
    public var muted: Color
    public var highlight: Color
    public var surface: Color
    public var border: Color
    public var text: Color
    public var textDim: Color
    public var selectionBackground: Color
    public var background: Color
}

public enum ThemeManager {
    nonisolated(unsafe) public static var current: ThemeColors = dark

    public static let dark = ThemeColors(
        primary: Color.cyan,
        accent: Color.green,
        success: Color.green,
        warning: Color.yellow,
        error: Color.red,
        muted: Color.gray,
        highlight: Color.white,
        surface: Color.brightBlack,
        border: Color.brightBlack,
        text: Color.white,
        textDim: Color.gray,
        selectionBackground: Color.blue,
        background: Color.default
    )

    public static let light = ThemeColors(
        primary: Color.blue,
        accent: Color.green,
        success: Color.green,
        warning: Color.yellow,
        error: Color.red,
        muted: Color.gray,
        highlight: Color.black,
        surface: Color.brightWhite,
        border: Color.gray,
        text: Color.black,
        textDim: Color.gray,
        selectionBackground: Color.brightCyan,
        background: Color.default
    )

    public static let nord = ThemeColors(
        primary: Color.xterm(red: 5, green: 4, blue: 4),
        accent: Color.xterm(red: 3, green: 4, blue: 3),
        success: Color.xterm(red: 3, green: 4, blue: 3),
        warning: Color.xterm(red: 5, green: 4, blue: 2),
        error: Color.xterm(red: 5, green: 2, blue: 2),
        muted: Color.xterm(white: 10),
        highlight: Color.xterm(red: 4, green: 4, blue: 4),
        surface: Color.xterm(white: 8),
        border: Color.xterm(white: 9),
        text: Color.xterm(red: 4, green: 4, blue: 4),
        textDim: Color.xterm(white: 10),
        selectionBackground: Color.xterm(red: 3, green: 3, blue: 4),
        background: Color.xterm(red: 2, green: 2, blue: 2)
    )

    public static let gruvbox = ThemeColors(
        primary: Color.xterm(red: 4, green: 4, blue: 1),
        accent: Color.xterm(red: 3, green: 4, blue: 2),
        success: Color.xterm(red: 3, green: 4, blue: 2),
        warning: Color.xterm(red: 5, green: 4, blue: 1),
        error: Color.xterm(red: 4, green: 0, blue: 0),
        muted: Color.xterm(white: 8),
        highlight: Color.xterm(white: 15),
        surface: Color.xterm(red: 2, green: 2, blue: 2),
        border: Color.xterm(white: 9),
        text: Color.xterm(red: 4, green: 4, blue: 3),
        textDim: Color.xterm(white: 8),
        selectionBackground: Color.xterm(red: 3, green: 3, blue: 1),
        background: Color.xterm(red: 2, green: 1, blue: 0)
    )

    public static let dracula = ThemeColors(
        primary: Color.xterm(red: 3, green: 3, blue: 5),
        accent: Color.xterm(red: 3, green: 5, blue: 3),
        success: Color.xterm(red: 3, green: 5, blue: 3),
        warning: Color.xterm(red: 5, green: 4, blue: 2),
        error: Color.xterm(red: 5, green: 2, blue: 2),
        muted: Color.xterm(white: 10),
        highlight: Color.xterm(red: 5, green: 5, blue: 5),
        surface: Color.xterm(white: 8),
        border: Color.xterm(white: 9),
        text: Color.xterm(red: 4, green: 4, blue: 4),
        textDim: Color.xterm(white: 10),
        selectionBackground: Color.xterm(red: 4, green: 3, blue: 5),
        background: Color.xterm(red: 1, green: 1, blue: 2)
    )

    public static func activate(_ name: String) {
        switch name.lowercased() {
        case "light": current = light
        case "nord": current = nord
        case "gruvbox": current = gruvbox
        case "dracula": current = dracula
        default: current = dark
        }
    }
}

public enum TUIIcon {
    public static let running = "●"
    public static let stopped = "○"
    public static let warning = "▲"
    public static let error = "✕"
    public static let arrow = "→"
    public static let bullet = "•"
    public static let bar = "█"
    public static let halfBar = "▓"
    public static let emptyBar = "░"
    public static let search = "?"
    public static let refresh = "↻"
    public static let edit = "✎"
    public static let save = "✓"
    public static let delete = "✗"
    public static let chevronRight = "▶"
    public static let chevronDown = "▼"
    public static let circleFilled = "●"
    public static let circleEmpty = "○"
    public static let divider = "─"
    public static let verticalDivider = "│"
    public static let topLeft = "╭"
    public static let topRight = "╮"
    public static let bottomLeft = "╰"
    public static let bottomRight = "╯"
    public static let horizontalLine = "─"
    public static let verticalLine = "│"
    public static let database = "◆"
    public static let cpu = "⚙"
    public static let memory = "◈"
    public static let clock = "◐"
    public static let folder = "▸"
    public static let file = "◦"
    public static let queue = "☰"
    public static let rules = "⚖"
    public static let config = "⚙"
    public static let history = "≡"
    public static let stats = "▤"
    public static let doctor = "◎"
    public static let logs = "☰"
    public static let dashboard = "▣"
    public static let home = "⌂"
    public static let settings = "⚙"
    public static let search2 = "◎"
    public static let filter = "◎"
    public static let info = "ℹ"
    public static let select = "▶"
    public static let checkmark = "✓"
    public static let crossmark = "✗"
}
