# 📂 Download Organizer

<div align="center">

**Automatically organize your macOS Downloads folder in real-time.**

Built with **Swift 6**, powered by **LaunchAgent**, and designed to work silently in the background.

![macOS](https://img.shields.io/badge/macOS-14%2B-blue?style=for-the-badge\&logo=apple)
![Swift](https://img.shields.io/badge/Swift-6.0-orange?style=for-the-badge\&logo=swift)
![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)
![Platform](https://img.shields.io/badge/Platform-macOS-lightgrey?style=for-the-badge)
![SPM](https://img.shields.io/badge/Swift_Package_Manager-Compatible-red?style=for-the-badge)

</div>

---

## ✨ Overview

**Download Organizer** is a lightweight background service for macOS that automatically keeps your **Downloads** folder clean and organized.

Instead of manually sorting downloaded files, Download Organizer watches your `~/Downloads` directory in real-time and automatically moves completed downloads into categorized folders such as:

* 📷 Images
* 🎥 Videos
* 📄 Documents
* 📕 PDF
* 🎵 Audio
* 💻 Code
* 📦 Archives
* and many more...

The application is written entirely in **Swift 6**, uses **FSEvents** for real-time monitoring, stores history in **SQLite**, and runs silently as a **LaunchAgent**.

---

# 🚀 Features

* ⚡ Real-time monitoring using **FSEvents**
* 📂 Automatically categorizes downloaded files
* ⏳ Waits until downloads are fully completed before moving
* 🔄 Prevents filename collisions with automatic renaming
* 🗄 Stores complete move history in SQLite
* ♻ Undo the most recent move
* 📊 View organizer statistics
* 🔥 Hot-reloads custom rules without restarting
* ⚙ Configurable via JSON
* 📝 Detailed logging
* 🚀 Lightweight background LaunchAgent
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

After installation:

```bash
download-organizer-install
```

Verify the service:

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

| Category       | Extensions                                                         |
| -------------- | ------------------------------------------------------------------ |
| 📷 Images      | jpg, jpeg, png, gif, webp, heic, svg, bmp, tif                     |
| 🎥 Videos      | mp4, mov, mkv, avi, m4v, webm                                      |
| 🎵 Audio       | mp3, wav, m4a, aac, flac, ogg                                      |
| 📄 Documents   | doc, docx, xls, xlsx, ppt, pptx, txt, csv                          |
| 📕 PDF         | pdf                                                                |
| 📦 Archives    | zip, rar, 7z, tar, gz                                              |
| 💻 Code        | swift, dart, js, ts, json, xml, html, css, py, java, kt, c, cpp, h |
| 💾 Disk Images | dmg, iso                                                           |
| 📱 Apps        | app, pkg                                                           |
| 📚 eBooks      | epub, mobi, azw3                                                   |
| ❓ Others       | Any unsupported extension                                          |

---

# ⚙ Configuration

All configuration files are stored inside:

```text
~/.download-organizer/
```

## config.json

Example:

```json
{
  "watchDirectory": "~/Downloads",
  "enableLogging": true,
  "waitUntilStable": true,
  "stableCheckSeconds": 3,
  "duplicateStrategy": "rename"
}
```

---

## rules.json

Create custom rules to override the default categorization.

Example:

```json
[
  {
    "extensions": [
      "psd",
      "ai"
    ],
    "folder": "Design"
  },
  {
    "extensions": [
      "fig"
    ],
    "folder": "Figma"
  }
]
```

Changes are detected automatically without restarting the service.

---

# 📖 Usage

## Install LaunchAgent

```bash
download-organizer-install
```

---

## Restart Service

```bash
download-organizer-restart
```

---

## Remove Service

```bash
download-organizer-uninstall
```

---

## View Statistics

```bash
download-organizer --stats
```

---

## Undo Last Move

```bash
download-organizer --undo-last
```

---

## View Logs

```bash
tail -f ~/.download-organizer/logs/download-organizer.log
```

---

## Check Service Status

```bash
launchctl print gui/$(id -u)/com.downloadorganizer.agent
```

---

# 🧩 Project Structure

```
macOS-Download-Organizer
├── Sources/
│   ├── CLI
│   ├── Monitor
│   ├── SQLite
│   ├── Models
│   ├── Utils
│   └── Commands
├── install.sh
├── uninstall.sh
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
 Load custom rules
        │
        ▼
 Determine destination folder
        │
        ▼
 Handle duplicates
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

Some browsers write files in multiple stages.

The organizer waits until the file size no longer changes before moving it.

If necessary, increase:

```json
stableCheckSeconds
```

inside `config.json`.

---

## Permission Denied

Grant **Full Disk Access** to the terminal (or the app running the service):

**System Settings → Privacy & Security → Full Disk Access**

Then restart:

```bash
download-organizer-restart
```

---

## Service Not Running

Check LaunchAgent:

```bash
launchctl print gui/$(id -u)/com.downloadorganizer.agent
```

Reinstall:

```bash
download-organizer-install
```

---

## View Logs

```bash
tail -f ~/.download-organizer/logs/download-organizer.log
```

---

# 🗄 Database

Move history is stored locally in SQLite.

Location:

```text
~/.download-organizer/history.db
```

Each move records:

* Original filename
* New filename
* Source path
* Destination path
* Timestamp

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

Feel free to use, modify, and distribute it in accordance with the license terms.

---

<div align="center">

**Built with ❤️ in Swift**

⭐ If this project helps you, consider giving it a star on GitHub!

</div>
