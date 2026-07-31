# Changelog

## [1.1.2] - 2026-07-31

### Fixed
- Stray "s" character in production release — variable name collision in ForEach closures

### Added
- Save theme preference to config (persists across restarts)
- macOS notifications when files are organized
- Daily summary notification (once per day, toggleable)
- Statistics: Top 10 categories with ASCII histogram/bar chart
- Statistics: Top 10 largest files ever organized with size color-coding
- Additional watch folder support (optional secondary folder)
- Theme selector in Configuration page
- Daily Summary toggle in Configuration page

### Changed
- Statistics page redesigned with 3 sections: Top Categories, Top Files, Per Folder
- Configuration page now shows all settings including Theme and Daily Summary
- Folder browser handles both Watch Folder and Additional Folder

## [1.1.1] - 2026-07-30

### Fixed
- SwiftTUI crash when transitioning between view types (always render ScrollView wrapper)
- Statistics page only showing 1 folder — now queries database directly without 200-record limit
- Crash on Clear History due to premature state mutation
- Ghost characters on page transitions

### Added
- Clear History feature (delete all records from database)
- Statistics: per-folder file sizes, color-coded bars, all categories shown (including zero-count)
- Statistics: scrollable per-folder list

### Changed
- Statistics: removed Overview section (streamlined to Per Folder only)

### Infrastructure
- Homebrew formula updated for v1.1.1
- README rewritten with full TUI documentation
- Build script version synced

## [1.1.0] - 2026-07-25

### Added
- Terminal UI (SwiftTUI) with interactive dashboard
- Dashboard page: real-time status, organized files, recent moves, undo button
- Statistics page: visual overview with stat boxes and per-folder breakdown
- History page: scrollable record list with search
- Configuration page: edit settings in-app
- Rules page: view/reset custom rules
- Main menu with keyboard navigation
- Auto-refresh every 5 seconds
- Undo last move(s)
- Organize now (manual trigger)
- Theme toggle (light/dark)
- Backup and restore configuration

### Changed
- Complete migration from CLI-only to TUI-first interface
- `download-organizer dashboard` launches the interactive TUI
- All CLI flags preserved for backward compatibility

## [1.0.0] - 2026-07-01

### Added
- Initial release
- Real-time folder monitoring via LaunchAgent
- Automatic file organization by category
- Custom rules support
- CLI commands: --stats, --undo-last, --help
- Install/uninstall scripts
- Homebrew formula
