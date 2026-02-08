# SPDX-License-Identifier: PMPL-1.0-or-later
# FlatRacoon System Configuration
# Location: /etc/flatracoon/flatracoon.ncl
#
# This is the main system configuration file that overrides defaults from
# the repository's base.ncl. It follows XDG Base Directory specification.

# Import base configuration types (if available)
# let base = import "../base.ncl" in

{
  # System metadata
  config_version = "1.0.0",
  config_path = "/etc/flatracoon/flatracoon.ncl",

  # Orchestrator configuration
  orchestrator = {
    # API server settings
    host = "localhost",
    port = 4000,
    url = "http://localhost:4000",

    # Module registry settings
    modules_dir = "/etc/flatracoon/modules.d",
    manifests_dir = "/etc/flatracoon/manifests",

    # Health check settings (overrides base.ncl defaults)
    health_check_interval = 30,  # seconds
    health_timeout = 5,  # seconds

    # Database (if using persistent storage)
    database_url = "ecto://localhost/flatracoon",
  },

  # TUI configuration
  tui = {
    # Connection settings
    orchestrator_url = "http://localhost:4000",

    # Display settings
    colors_enabled = true,
    output_format = "table",  # table | json | plain

    # Pager settings
    use_pager = true,
    pager_cmd = "less -R",

    # History settings (XDG_DATA_HOME)
    history_file = "$HOME/.local/share/flatracoon/history",
    history_size = 1000,
  },

  # Interface SDK configuration
  interface = {
    # API client settings
    base_url = "http://localhost:4000",
    timeout = 30000,  # milliseconds

    # Retry settings
    max_retries = 3,
    retry_delay = 1000,  # milliseconds
    retry_backoff = true,  # exponential backoff
  },

  # Kubernetes deployment settings
  kubernetes = {
    # Default namespace for modules
    default_namespace = "flatracoon-system",

    # Kubeconfig location
    kubeconfig = "$HOME/.kube/config",
    context = "default",  # use current context if not specified

    # Deployment timeouts
    helm_timeout = "5m",
    rollout_timeout = "30s",
    kubectl_timeout = "2m",

    # Deployment modes
    default_mode = "helm",  # helm | kubectl | daemonset | statefulset

    # Service account
    service_account = "flatracoon-orchestrator",
  },

  # Logging configuration
  logging = {
    level = "info",  # debug | info | warn | error
    format = "json",  # json | plain
    output = "stdout",  # stdout | file | syslog
    file_path = "/var/log/flatracoon/orchestrator.log",

    # Syslog settings (if output = syslog)
    syslog_facility = "local0",
    syslog_tag = "flatracoon",
  },

  # Module auto-discovery
  discovery = {
    enabled = true,
    scan_interval = 60,  # seconds
    manifest_pattern = "*.manifest.ncl",

    # Module validation
    validate_manifests = true,
    require_signatures = false,  # set true for production
  },

  # Network configuration (IPv6-first stack)
  network = {
    ipv6_only = true,
    nat64_enabled = true,
    dns64_enabled = true,
    ipv6_prefix = "fd00::/48",  # ULA prefix for local network
  },

  # Security settings
  security = {
    # API authentication
    api_key_required = false,  # set true for production
    api_key_header = "X-FlatRacoon-API-Key",

    # TLS settings
    tls_enabled = false,  # set true for production
    tls_cert_path = "/etc/flatracoon/certs/server.crt",
    tls_key_path = "/etc/flatracoon/certs/server.key",

    # RBAC
    rbac_enabled = false,
  },
}
