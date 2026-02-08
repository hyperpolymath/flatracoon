# SPDX-License-Identifier: PMPL-1.0-or-later
# FlatRacoon User Configuration
# Location: ~/.config/flatracoon/flatracoon.ncl
#
# This file overrides system defaults from /etc/flatracoon/flatracoon.ncl
# XDG Base Directory spec: https://specifications.freedesktop.org/basedir-spec/latest/

{
  # Override orchestrator URL if connecting to remote instance
  # orchestrator = {
  #   url = "https://flatracoon.example.com:4000",
  # },

  # TUI preferences
  tui = {
    # Customize display
    colors_enabled = true,
    output_format = "table",  # table | json | plain

    # Custom history location (defaults to XDG_DATA_HOME)
    # history_file = "$HOME/.local/share/flatracoon/history",
  },

  # Interface SDK overrides (for development)
  # interface = {
  #   base_url = "http://localhost:4000",
  #   timeout = 60000,  # Longer timeout for debugging
  # },

  # Personal logging preferences
  # logging = {
  #   level = "debug",  # More verbose for troubleshooting
  # },
}
