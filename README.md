# 📂 Download Organizer

<div align="center">

**Automatically organize your macOS Downloads folder in real-time.**

Built with **Swift 6**, powered by **SwiftTUI** and **LaunchAgent**.

![macOS](https://img.shields.io/badge/macOS-14%2B-blue?style=for-the-badge\&logo=apple)
![Swift](https://img.shields.io/badge/Swift-6.0-orange?style=for-the-badge\&logo=swift)
![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)
![Platform](https://img.shields.io/badge/Platform-macOS-lightgrey?style=for-the-badge)
![Version](https://img.shields.io/badge/Version-1.1.2-red?style=for-the-badge)

</div>

---

## ✨ Overview

**Download Organizer** is a native macOS tool that keeps your **Downloads** folder clean and organized. It features a **Terminal User Interface (TUI)** for interactive management alongside a background service.

Instead of manually sorting files, it watches your `~/Downloads` directory in real-time and automatically moves completed downloads into categorized folders.

---

# 🚀 Features

### Core
* ⚡ Real-time monitoring using **FSEvents**
* 📂 Automatically categorizes downloaded files into 15+ categories
* ⏳ Waits until downloads are fully completed before moving
* 🔄 Handles filename collisions with configurable strategy (rename/overwrite/skip)
* 🗄 Stores complete move history in **SQLite**
* 📝 Detailed file logging

### Terminal UI (TUI)
* 🖥️ Interactive dashboard with real-time status
* 📊 History viewer with filter (All/Moved/Restored/Failed) and sort (Date/Name/Size)
* 📈 Statistics page with per-category breakdown
* ⚙ Configuration editor with inline editing and duplicate strategy selector
* 📋 Rules manager with add/remove/reset and confirmation dialogs
* 🔮 Rule simulator - test any filename against current rules
* 📜 Log viewer
* 🩺 Doctor page for system diagnostics
* ♻ Undo last move or **bulk undo** multiple moves at once
* 🏃 Organize Now - immediately scan and organize
* 🔄 Auto-refresh toggle
* 🎨 5 built-in themes (dark, light, nord, gruvbox, dracula)
* ❓ Help overlay with keyboard shortcuts on every page
* 💾 Export/import configuration
* 📦 Backup/restore all data (config + rules)

### Service
* 🚀 Lightweight background LaunchAgent
* 🔥 Hot-reloads custom rules without restarting
* 🍺 Easy installation via Homebrew
* 🔒 No internet connection required
* ❤️ Built with native Swift

---

# 📋 Requirements

| Requirement              | Version            |
| ------------------------ | ------------------ |
| macOS                    | 14 Sonoma or newer |
| Swift                    | 6.0+               |
| Xcode Command Line Tools | Latest             |
| Swift Package Manager    | Included           |

---

# 🍺 Installation (Recommended)

## Install using Homebrew

```bash
brew tap fajaradisetyawan/tap
brew trust fajaradisetyawan/tap
brew install download-organizer
```

---

# 🖥️ Terminal UI (TUI)

Download Organizer includes a full interactive **Terminal User Interface** built with SwiftTUI.

## Launch

```bash
download-organizer dashboard
```

Or using the flag form:

```bash
download-organizer --dashboard
```

## Main Menu

The main menu lists all available pages. Use **arrow keys** to navigate and **Enter** to select.

Pages:
| Menu          | Description                                        |
|---------------|----------------------------------------------------|
| Dashboard     | Real-time status, recent activity, quick actions   |
| History       | Browse all moves, filter & sort, undo              |
| Statistics    | Per-category file counts and breakdown             |
| Configuration | Edit settings inline (watch folder, delay, etc.)   |
| Rules         | View/add/edit/remove categorization rules          |
| Simulator     | Test any filename against current rules            |
| Logs          | View application logs                              |
| Doctor        | Run system diagnostics checks                      |
| About         | Version info and credits                           |

## Navigation

| Key                  | Action                     |
|----------------------|----------------------------|
| `↑` `↓`             | Move selection             |
| `Enter`              | Select / confirm           |
| `Esc`                | Cancel / go back           |
| `R`                  | Refresh current page       |
| `?`                  | Show help overlay          |
| `T` (or theme btn)   | Cycle theme                |
| `Q`                  | Quit                       |

## Dashboard

- **Status**: service running/stopped, watch folder, queue count
- **Recent Activity**: last 10 moved files
- **Quick Actions**: Undo last move, Organize Now, toggle auto-refresh
- **Bottom bar**: theme button, help, home

## History

- **Filter**: All / Moved / Restored / Failed
- **Sort**: Date / Name / Size
- **Search**: type `/` to search filename, category, or extension
- **Undo**: single undo, or use `-` / `+` to set bulk count then `Undo N`

## Configuration

- **Inline editing**: click any row to edit
- **Watch Folder**: browse filesystem with FolderBrowserView
- **Duplicate Strategy**: dropdown with rename / overwrite / skip
- **Export / Import**: save config to Desktop, or restore from file
- **Backup / Restore**: backup both config.json + rules.json to timestamped folder

## Rules

- **Add rule**: fill category name + extensions
- **Edit**: click any category to modify extensions inline
- **Remove**: confirm dialog before deleting
- **Reset to defaults**: confirm dialog before clearing all custom rules

## Simulator

Type a filename (e.g. `photo.jpg` or `archive.zip`) and press **Enter** to see which category it would be classified under. Maintains a history of the last 20 tests.

---

# 📖 CLI Usage

## Run as background service

```bash
download-organizer
```

## Install LaunchAgent

```bash
download-organizer-install
```

## Restart Service

```bash
download-organizer-restart
```

## Remove Service

```bash
download-organizer-uninstall
```

## View Statistics

```bash
download-organizer --stats
```

## Undo Last Move

```bash
download-organizer --undo-last
```

## Doctor Checks

```bash
download-organizer doctor
download-organizer --doctor
```

## View History

```bash
download-organizer history --limit 20
download-organizer history --today
download-organizer history --category PDF
download-organizer history --extension pdf
```

## View Logs

```bash
tail -f ~/.download-organizer/logs/download-organizer.log
```

## Check Service Status

```bash
launchctl print gui/$(id -u)/com.downloadorganizer.agent
```

---

# 🛠 Manual Installation

Clone the repository:

```bash
git clone https://github.com/FajarAdiSetyawan/macOS-Download-Organizer.git
cd macOS-Download-Organizer
```

Run the installer:

```bash
chmod +x install.sh
./install.sh
```

---

# 📁 Default Folder Categories

| Category       | Extensions (selected)                                                            |
| -------------- | -------------------------------------------------------------------------------- |
| 📷 Images      | jpg, jpeg, png, gif, webp, svg, heic, bmp, tif, raw, jxl, xcf                   |
| 🎥 Videos      | mp4, mov, mkv, avi, webm, m4v, mpg, mpeg, 3gp, ogv, vob, ts                     |
| 🎵 Audio       | mp3, wav, m4a, aac, flac, ogg, wma, opus, alac, aiff, mid                       |
| 📄 Documents   | doc, docx, xls, xlsx, ppt, pptx, txt, csv, rtf, odt, md, log, msg, eml          |
| 📕 PDF         | pdf                                                                              |
| 📦 Archives    | zip, rar, 7z, tar, gz, xz, bz2, dmg, iso, jar, war, zst, lz4                   |
| 💻 Code        | swift, dart, js, ts, py, java, kt, go, rs, c, cpp, h, zig, hs, ex, lua, sh, rb |
| 🎨 Design      | fig, xd, psd, ai, sketch, eps, ps, storyboard, xib, blend, c4d, max             |
| 📱 Apps        | app, pkg, exe, msi, apk, ipa, deb, rpm, appimage                                |
| 📚 eBooks      | epub, mobi, azw, azw3, fb2, lit, lrf, cbr, cbz                                  |
| 🔤 Fonts       | ttf, otf, woff, woff2, eot, dfont, fon, ttc                                     |
| 🗄 Database    | sqlite, sqlite3, db, db3, sql, frm, myd, myi                                    |
| ⚙ Config      | plist, strings, xcconfig, entitlements, mobileprovision, pbxproj                |
| 🔐 Certificates | cer, crt, pem, key, p12, pfx, der, csr                                        |
| ❓ Others       | Any unsupported extension                                                        |



# 🧩 Project Structure

```
macOS-Download-Organizer
├── Sources/
│   ├── App/                  # Entry point
│   ├── TUI/                  # Terminal UI (SwiftTUI)
│   │   ├── Core/             # Navigation, store, themes
│   │   ├── Pages/            # All page views
│   │   └── Views/            # Reusable components
│   ├── Services/             # Business logic
│   │   ├── RuleEngine/       # File categorization
│   │   ├── FileMover/        # File operations
│   │   ├── FileWatcher/      # FSEvents monitoring
│   │   └── HistoryService/   # SQLite history
│   ├── Database/             # SQLite layer
│   ├── Models/               # Data models
│   └── Core/                 # Configuration, logging, paths
├── Formula/                  # Homebrew formula
├── install.sh
├── uninstall.sh
├── restart.sh
├── Package.swift
└── README.md
```

---

# ⚙ How It Works

```text
Downloads Folder
        │
        ▼
 FSEvents detects changes
        │
        ▼
 Wait until file is stable
        │
        ▼
 Detect file extension
        │
        ▼
 Load custom rules (rules.json)
        │
        ▼
 Determine destination folder
        │
        ▼
 Handle duplicates (rename/overwrite/skip)
        │
        ▼
 Move file
        │
        ▼
 Save history to SQLite
        │
        ▼
 Write logs
```

---

# 🔧 Troubleshooting

## "File is not stable"

Some browsers write files in multiple stages. The organizer waits until the file size no longer changes before moving it. If necessary, increase `delay` in `config.json`.

## Permission Denied

Grant **Full Disk Access** to the terminal:

**System Settings → Privacy & Security → Full Disk Access**

Then restart:

```bash
download-organizer-restart
```

## Service Not Running

Check LaunchAgent:

```bash
launchctl print gui/$(id -u)/com.downloadorganizer.agent
```

Reinstall if needed:

```bash
download-organizer-install
```

---

# 🗄 Database

Move history is stored locally in **SQLite** at `~/.download-organizer/history.db`.

Each move records:
* Filename
* Source path → Destination path
* Category and file extension
* File size
* Timestamp
* Status (moved / restored / failed)

---

# 🤝 Contributing

Contributions are welcome!

1. Fork the repository.
2. Create a feature branch.
3. Commit your changes.
4. Open a Pull Request.

---

# 📄 License

This project is licensed under the **MIT License**.

---

<div align="center">

**Built with ❤️ in Swift**

⭐ If this project helps you, consider giving it a star on GitHub!

</div>
