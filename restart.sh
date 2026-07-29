#!/usr/bin/env bash
set -euo pipefail

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m' # No Color

# Configuration
readonly LABEL="com.downloadorganizer.agent"
readonly PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"

# Functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_plist() {
    if [[ ! -f "$PLIST" ]]; then
        log_error "LaunchAgent plist not found at:"
        log_error "  $PLIST"
        echo
        log_error "Run ./install.sh first"
        exit 1
    fi
}

stop_service() {
    log_info "Stopping Download Organizer service..."

    if launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null; then
        log_info "Service stopped"
    else
        log_warning "Service was not running"
    fi
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
        log_error "Check logs at: $HOME/.download-organizer/logs/stderr.log"
        return 1
    fi
}

# Main
main() {
    log_info "Restarting Download Organizer..."
    echo

    check_plist
    stop_service
    start_service

    if verify_service; then
        echo
        log_info "Restart completed successfully"
        exit 0
    else
        exit 1
    fi
}

main "$@"