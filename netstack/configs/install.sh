#!/usr/bin/env bash
# SPDX-License-Identifier: PMPL-1.0-or-later
# FlatRacoon Configuration Installer
#
# Usage:
#   ./install.sh --system   # Install system config (requires root)
#   ./install.sh --user     # Install user config
#   ./install.sh --all      # Install both (will prompt for sudo)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SYSTEM_CONFIG_DIR="/etc/flatracoon"
USER_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/flatracoon"
USER_DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/flatracoon"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

install_system_config() {
    print_info "Installing system configuration to $SYSTEM_CONFIG_DIR..."

    if [ "$EUID" -ne 0 ]; then
        print_warn "System config installation requires root privileges"
        print_info "Requesting sudo access..."
        sudo -v
        SUDO="sudo"
    else
        SUDO=""
    fi

    # Create system directories
    $SUDO mkdir -p "$SYSTEM_CONFIG_DIR/modules.d"
    $SUDO mkdir -p "$SYSTEM_CONFIG_DIR/manifests"

    # Install system config
    $SUDO cp "$SCRIPT_DIR/system/flatracoon.ncl" "$SYSTEM_CONFIG_DIR/"

    # Set permissions
    $SUDO chmod 755 "$SYSTEM_CONFIG_DIR"
    $SUDO chmod 755 "$SYSTEM_CONFIG_DIR/modules.d"
    $SUDO chmod 755 "$SYSTEM_CONFIG_DIR/manifests"
    $SUDO chmod 644 "$SYSTEM_CONFIG_DIR/flatracoon.ncl"

    print_info "✓ System config installed at $SYSTEM_CONFIG_DIR/flatracoon.ncl"
    print_info "✓ Modules directory: $SYSTEM_CONFIG_DIR/modules.d"
    print_info "✓ Manifests directory: $SYSTEM_CONFIG_DIR/manifests"
}

install_user_config() {
    print_info "Installing user configuration to $USER_CONFIG_DIR..."

    # Create user directories (following XDG spec)
    mkdir -p "$USER_CONFIG_DIR"
    mkdir -p "$USER_DATA_DIR"
    mkdir -p "${XDG_CACHE_HOME:-$HOME/.cache}/flatracoon"
    mkdir -p "${XDG_STATE_HOME:-$HOME/.local/state}/flatracoon"

    # Install user config (don't overwrite if exists)
    if [ -f "$USER_CONFIG_DIR/flatracoon.ncl" ]; then
        print_warn "User config already exists at $USER_CONFIG_DIR/flatracoon.ncl"
        print_warn "Backing up to flatracoon.ncl.bak"
        cp "$USER_CONFIG_DIR/flatracoon.ncl" "$USER_CONFIG_DIR/flatracoon.ncl.bak"
    fi

    cp "$SCRIPT_DIR/user-template/flatracoon.ncl" "$USER_CONFIG_DIR/"

    # Set permissions
    chmod 700 "$USER_CONFIG_DIR"
    chmod 600 "$USER_CONFIG_DIR/flatracoon.ncl"
    chmod 700 "$USER_DATA_DIR"

    print_info "✓ User config installed at $USER_CONFIG_DIR/flatracoon.ncl"
    print_info "✓ Data directory: $USER_DATA_DIR"
    print_info "✓ Cache directory: ${XDG_CACHE_HOME:-$HOME/.cache}/flatracoon"
    print_info "✓ State directory: ${XDG_STATE_HOME:-$HOME/.local/state}/flatracoon"
    print_info ""
    print_info "Edit your config with:"
    print_info "  \$EDITOR $USER_CONFIG_DIR/flatracoon.ncl"
}

show_usage() {
    cat <<EOF
FlatRacoon Configuration Installer

Usage:
  $0 [OPTIONS]

Options:
  --system      Install system configuration (requires root)
  --user        Install user configuration
  --all         Install both system and user configuration
  --help        Show this help message

Examples:
  # Install system config only (requires sudo)
  $0 --system

  # Install user config only
  $0 --user

  # Install both
  $0 --all

Configuration Locations:
  System:  $SYSTEM_CONFIG_DIR/flatracoon.ncl
  User:    $USER_CONFIG_DIR/flatracoon.ncl
  Data:    $USER_DATA_DIR
  Cache:   ${XDG_CACHE_HOME:-$HOME/.cache}/flatracoon
  State:   ${XDG_STATE_HOME:-$HOME/.local/state}/flatracoon

For more information, see configs/README.md
EOF
}

main() {
    if [ $# -eq 0 ]; then
        show_usage
        exit 1
    fi

    case "$1" in
        --system)
            install_system_config
            ;;
        --user)
            install_user_config
            ;;
        --all)
            install_system_config
            echo ""
            install_user_config
            ;;
        --help|-h)
            show_usage
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            echo ""
            show_usage
            exit 1
            ;;
    esac

    echo ""
    print_info "Installation complete!"
    print_info "See configs/README.md for configuration options"
}

main "$@"
