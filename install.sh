#!/usr/bin/env bash
set -euo pipefail

# Colors
readonly RED="$(printf '\033[0;31m')"
readonly GREEN="$(printf '\033[0;32m')"
readonly YELLOW="$(printf '\033[1;33m')"
readonly NC="$(printf '\033[0m')" # No Color

# Configuration
readonly LABEL="com.downloadorganizer.agent"
readonly ROOT="$HOME/.download-organizer"
readonly BIN_DIR="$ROOT/bin"
readonly LOG_DIR="$ROOT/logs"
readonly LAUNCH_AGENTS="$HOME/Library/LaunchAgents"
readonly PLIST="$LAUNCH_AGENTS/$LABEL.plist"

# Functions
log_info() {
    printf '%s\n' "${GREEN}[INFO]${NC} $1"
}

log_warning() {
    printf '%s\n' "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    printf '%s\n' "${RED}[ERROR]${NC} $1"
}

check_macos() {
    if [[ "$OSTYPE" != "darwin"* ]]; then
        log_error "This script only works on macOS"
        exit 1
    fi
}

check_swift() {
    if ! command -v swift &> /dev/null; then
        log_error "Swift not found. Install Xcode or Swift toolchain."
        exit 1
    fi

    log_info "Swift version: $(swift --version | head -n1)"
}

build_binary() {
    log_info "Building Download Organizer in release mode..."

    if ! swift build -c release; then
        log_error "Build failed. Check errors above."
        exit 1
    fi

    log_info "Build completed successfully"
}

create_directories() {
    log_info "Creating directories..."

    mkdir -p "$BIN_DIR"
    mkdir -p "$LOG_DIR"
    mkdir -p "$LAUNCH_AGENTS"
    mkdir -p "$HOME/Downloads"

    log_info "Directories created"
}

install_binary() {
    log_info "Installing binary to $BIN_DIR..."

    local binary_path=".build/release/download-organizer"

    if [[ ! -f "$binary_path" ]]; then
        log_error "Binary not found at $binary_path"
        exit 1
    fi

    cp "$binary_path" "$BIN_DIR/download-organizer"
    chmod +x "$BIN_DIR/download-organizer"

    log_info "Binary installed successfully"
}

create_config() {
    if [[ -f "$ROOT/config.json" ]]; then
        log_warning "config.json already exists, skipping"
        return
    fi

    log_info "Creating default config.json..."

cat > "$ROOT/config.json" <<'JSON'
{
  "autoCreateFolders" : true,
  "delay" : 3,
  "duplicateStrategy" : "rename",
  "enabled" : true,
  "history" : true,
  "notifications" : true,
  "watchFolder" : "~/Downloads"
}
JSON

    log_info "config.json created"
}

create_rules() {
    if [[ -f "$ROOT/rules.json" ]]; then
        log_warning "rules.json already exists, skipping"
        return
    fi

    log_info "Creating default rules.json..."

cat > "$ROOT/rules.json" <<'JSON'
{

}
JSON

    log_info "rules.json created"
}

create_folders() {
    log_info "Creating category folders in ~/Downloads..."

    local folders=(
        "Images"
        "Videos"
        "Audio"
        "Documents"
        "PDF"
        "Archives"
        "Applications"
        "Books"
        "Fonts"
        "Code"
        "Design"
        "Others"
    )

    for folder in "${folders[@]}"; do
        mkdir -p "$HOME/Downloads/$folder"
    done

    log_info "Category folders created"
}

install_plist() {
    log_info "Installing LaunchAgent plist..."

    if [[ ! -f "scripts/$LABEL.plist" ]]; then
        log_error "LaunchAgent template not found at scripts/$LABEL.plist"
        exit 1
    fi

    sed \
        -e "s#__BINARY_PATH__#$BIN_DIR/download-organizer#g" \
        -e "s#__LOG_DIR__#$LOG_DIR#g" \
        -e "s#__INSTALL_DIR__#$ROOT#g" \
        "scripts/$LABEL.plist" > "$PLIST"

    log_info "LaunchAgent plist installed at $PLIST"
}

stop_service() {
    log_info "Stopping existing service (if running)..."
    launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
}

start_service() {
    log_info "Starting Download Organizer service..."

    if ! launchctl bootstrap "gui/$(id -u)" "$PLIST"; then
        log_error "Failed to bootstrap LaunchAgent"
        exit 1
    fi

    if ! launchctl kickstart -k "gui/$(id -u)/$LABEL"; then
        log_error "Failed to kickstart LaunchAgent"
        exit 1
    fi

    log_info "Service started"
}

verify_service() {
    log_info "Verifying service is running..."
    sleep 2

    if launchctl print "gui/$(id -u)/$LABEL" >/dev/null 2>&1; then
        log_info "Download Organizer is running successfully"
        return 0
    else
        log_error "Service verification failed"
        log_error "Check logs at: $LOG_DIR/stderr.log"
        return 1
    fi
}

print_summary() {
    echo
    echo "========================================"
    echo "  Download Organizer Installed"
    echo "========================================"
    echo
    echo "Service:       $LABEL"
    echo "Binary:        $BIN_DIR/download-organizer"
    echo "Config:        $ROOT/config.json"
    echo "Rules:         $ROOT/rules.json"
    echo "Database:      $ROOT/history.db"
    echo "Logs:          $LOG_DIR/"
    echo
    echo "Commands:"
    echo "  Restart:     ./restart.sh"
    echo "  Uninstall:   ./uninstall.sh"
    echo "  Undo last:   $BIN_DIR/download-organizer --undo-last"
    echo "  Statistics:  $BIN_DIR/download-organizer --stats"
    echo
    echo "Check status:"
    echo "  launchctl print gui/\$(id -u)/$LABEL"
    echo
    echo "View logs:"
    echo "  tail -f $LOG_DIR/download-organizer.log"
    echo
}

# Main
main() {
    log_info "Starting Download Organizer installation..."
    echo

    check_macos
    check_swift
    build_binary
    create_directories
    install_binary
    create_config
    create_rules
    create_folders
    install_plist
    stop_service
    start_service

    if verify_service; then
        print_summary
        exit 0
    else
        exit 1
    fi
}

main "$@"