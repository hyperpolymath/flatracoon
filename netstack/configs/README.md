# FlatRacoon Configuration

Standardized configuration locations following XDG Base Directory specification.

## Configuration Hierarchy

FlatRacoon loads configuration in the following order (later sources override earlier):

1. **System defaults** (built-in)
2. **System config**: `/etc/flatracoon/flatracoon.ncl`
3. **User config**: `~/.config/flatracoon/flatracoon.ncl` (or `$XDG_CONFIG_HOME/flatracoon/flatracoon.ncl`)

## Installation

### System Configuration (requires root)

```bash
# Create system config directory
sudo mkdir -p /etc/flatracoon/modules.d
sudo mkdir -p /etc/flatracoon/manifests

# Install system config
sudo cp configs/system/flatracoon.ncl /etc/flatracoon/

# Set permissions
sudo chmod 644 /etc/flatracoon/flatracoon.ncl
```

### User Configuration (optional)

```bash
# Create user config directory (XDG Base Directory spec)
mkdir -p ~/.config/flatracoon

# Copy template and customize
cp configs/user-template/flatracoon.ncl ~/.config/flatracoon/

# Edit with your preferences
$EDITOR ~/.config/flatracoon/flatracoon.ncl
```

## Configuration Sections

### orchestrator

Orchestrator API server and module registry settings.

**Key settings:**
- `orchestrator.url`: API endpoint URL
- `orchestrator.modules_dir`: Module manifest directory
- `orchestrator.health_check_interval`: Health check frequency (seconds)

### tui

Terminal UI client settings.

**Key settings:**
- `tui.orchestrator_url`: Orchestrator API endpoint
- `tui.colors_enabled`: Enable ANSI color output
- `tui.output_format`: Display format (table, json, plain)
- `tui.history_file`: Command history location

### interface

ReScript SDK client settings.

**Key settings:**
- `interface.base_url`: API base URL
- `interface.timeout`: Request timeout (milliseconds)
- `interface.max_retries`: Retry attempts on failure

### kubernetes

Kubernetes deployment settings.

**Key settings:**
- `kubernetes.default_namespace`: Module deployment namespace
- `kubernetes.helm_timeout`: Helm operation timeout
- `kubernetes.default_mode`: Deployment method (helm, kubectl)

### logging

Logging configuration for all components.

**Key settings:**
- `logging.level`: Log level (debug, info, warn, error)
- `logging.format`: Log format (json, plain)
- `logging.output`: Output destination (stdout, file)

### discovery

Module auto-discovery settings.

**Key settings:**
- `discovery.enabled`: Enable automatic module discovery
- `discovery.scan_interval`: Directory scan frequency (seconds)
- `discovery.manifest_pattern`: Glob pattern for manifests

## Environment Variables

All config values can be overridden with environment variables using the `FLATRACOON_` prefix:

```bash
export FLATRACOON_ORCHESTRATOR_URL="https://remote.example.com:4000"
export FLATRACOON_TUI_COLORS_ENABLED=false
export FLATRACOON_LOGGING_LEVEL=debug
```

**Naming convention:**
- Prefix: `FLATRACOON_`
- Sections separated by `_`
- Uppercase snake_case

**Examples:**
- `orchestrator.url` → `FLATRACOON_ORCHESTRATOR_URL`
- `tui.colors_enabled` → `FLATRACOON_TUI_COLORS_ENABLED`
- `kubernetes.default_namespace` → `FLATRACOON_KUBERNETES_DEFAULT_NAMESPACE`

## XDG Base Directory Spec Compliance

FlatRacoon follows the [XDG Base Directory Specification](https://specifications.freedesktop.org/basedir-spec/latest/):

- **Config**: `$XDG_CONFIG_HOME/flatracoon/` (default: `~/.config/flatracoon/`)
- **Data**: `$XDG_DATA_HOME/flatracoon/` (default: `~/.local/share/flatracoon/`)
- **Cache**: `$XDG_CACHE_HOME/flatracoon/` (default: `~/.cache/flatracoon/`)
- **State**: `$XDG_STATE_HOME/flatracoon/` (default: `~/.local/state/flatracoon/`)

### Directory Usage

```
~/.config/flatracoon/     # User configuration
~/.local/share/flatracoon/ # Command history, module cache
~/.cache/flatracoon/      # HTTP cache, temporary data
~/.local/state/flatracoon/ # Session state, logs
```

## Configuration Format

FlatRacoon uses [Nickel](https://nickel-lang.org/) for configuration:

- Type-safe configuration language
- Supports composition and merging
- JSON-compatible output
- Schema validation built-in

**Example:**

```nickel
{
  orchestrator = {
    url = "http://localhost:4000",
    port = 4000,
  },

  tui = {
    colors_enabled = true,
    output_format = "table",
  },
}
```

## Migration from Old Config Locations

**Orchestrator:**
- Old: `config/modules.exs`
- New: `/etc/flatracoon/flatracoon.ncl`

**TUI:**
- Old: `~/.flatracoon/config` (if existed)
- New: `~/.config/flatracoon/flatracoon.ncl`

**Interface:**
- Old: No config file support
- New: `~/.config/flatracoon/flatracoon.ncl`

## Troubleshooting

### Check which config file is loaded

```bash
# TUI: Will show loaded config in verbose mode
flatracoon_tui --verbose status

# Orchestrator: Check logs on startup
journalctl -u flatracoon-orchestrator | grep "Config loaded"
```

### Validate config syntax

```bash
# Validate Nickel syntax
nickel export < /etc/flatracoon/flatracoon.ncl
```

### Config not taking effect

1. Check file permissions (must be readable)
2. Verify XDG environment variables
3. Check for syntax errors in Nickel file
4. Ensure environment variables aren't overriding

## Security Considerations

- System config (`/etc/flatracoon/`) should be readable by all users
- User config (`~/.config/flatracoon/`) should be readable only by owner
- Never store secrets in config files (use environment variables or secret management)
- API tokens should use `$FLATRACOON_API_TOKEN` environment variable

## See Also

- [Nickel Language Documentation](https://nickel-lang.org/)
- [XDG Base Directory Specification](https://specifications.freedesktop.org/basedir-spec/latest/)
- [FlatRacoon Architecture](../docs/ARCHITECTURE.adoc)
