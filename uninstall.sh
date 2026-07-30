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
readonly PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"

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

stop_service() {
    log_info "Stopping Download Organizer service..."

    if launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null; then
        log_info "Service stopped successfully"
    else
        log_warning "Service was not running or already stopped"
    fi
}

remove_plist() {
    if [[ -f "$PLIST" ]]; then
        log_info "Removing LaunchAgent plist..."
        rm -f "$PLIST"
        log_info "LaunchAgent removed"
    else
        log_warning "LaunchAgent plist not found, skipping"
    fi
}

ask_remove_data() {
    echo
    echo "Configuration, history, and logs are preserved at:"
    echo "  $ROOT"
    echo
    read -p "Do you want to remove all data? (y/N): " -n 1 -r
    echo

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if [[ -d "$ROOT" ]]; then
            log_info "Removing all data..."
            rm -rf "$ROOT"
            log_info "All data removed"
        fi
    else
        log_info "Data preserved at: $ROOT"
    fi
}

print_summary() {
    echo
    echo "========================================"
    echo "  Download Organizer Uninstalled"
    echo "========================================"
    echo
    echo "LaunchAgent removed."
    echo

    if [[ -d "$ROOT" ]]; then
        echo "To remove configuration and data manually:"
        echo "  rm -rf \"$ROOT\""
        echo
    fi
}

# Main
main() {
    log_info "Starting Download Organizer uninstallation..."
    echo

    stop_service
    remove_plist
    ask_remove_data

    print_summary
}

main "$@"