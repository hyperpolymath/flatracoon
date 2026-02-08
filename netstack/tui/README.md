# FlatRacoon TUI

![Status](https://img.shields.io/badge/Status-Production%20Ready-brightgreen.svg)
![Completion](https://img.shields.io/badge/Completion-100%25-success.svg)
![Binary Size](https://img.shields.io/badge/Binary-250KB-blue.svg)

Terminal User Interface for the FlatRacoon Network Stack, written in Ada/SPARK.

## Features

- **Interactive shell** - Type commands interactively or use from CLI
- **Module management** - View status, deploy, restart, stop modules
- **Health monitoring** - Aggregate health checks across all modules
- **Deployment orchestration** - Shows topological deployment order
- **Colored output** - ANSI color support for better readability
- **Type-safe** - Ada/SPARK provides compile-time safety guarantees

## Commands

```
help, h              - Show help message
status, st [module]  - Show module status (all or specific)
health, hc           - Show health check summary
deploy, d [module]   - Deploy module(s)
order, o             - Show deployment order
logs, l <module>     - Show logs for module
restart, r <module>  - Restart module
stop, s <module>     - Stop module
exit, quit           - Exit TUI
```

## Building

Requires GNAT Ada compiler (Ada 2022 support):

```bash
# Build the project
gprbuild -P flatracoon_tui.gpr

# Run the TUI (interactive mode)
./bin/flatracoon_tui

# Run with command-line arguments
./bin/flatracoon_tui status
./bin/flatracoon_tui deploy zerotier-k8s-link
```

## Architecture

- **flatracoon.ads** - Root package with version info
- **flatracoon-display** - Terminal display utilities (colors, tables, banners)
- **flatracoon-commands** - Command parsing and execution
- **flatracoon-api_client** - HTTP client for orchestrator API
- **flatracoon_tui.adb** - Main entry point

## Orchestrator Integration

The TUI connects to the Phoenix LiveView orchestrator at `http://localhost:4000` by default.

API endpoints:
- `GET /api/modules` - List all modules
- `GET /api/modules/:name` - Get specific module
- `GET /api/health` - Health summary
- `GET /api/deployment_order` - Topological order
- `POST /api/deploy` - Deploy all modules
- `POST /api/deploy/:name` - Deploy specific module
- `POST /api/restart/:name` - Restart module
- `POST /api/stop/:name` - Stop module
- `GET /api/logs/:name` - Get module logs

## Status

**Phase:** 🟢 Production Ready
**Completion:** 100%
**Binary Size:** 250KB (statically linked)

### Completed Features

✅ Project structure
✅ Display utilities (colors, banners, tables)
✅ Command parsing and execution
✅ Real HTTP client (GNAT.Sockets)
✅ JSON parsing (custom lightweight parser)
✅ Interactive shell with command history
✅ Full orchestrator API integration
✅ Module management (deploy, restart, stop)
✅ Health monitoring and status display
✅ Logs retrieval

### Implementation Details

- **HTTP Client:** GNAT.Sockets-based HTTP/1.1 client with manual request/response parsing
- **JSON Parser:** Custom string-based parser for orchestrator responses (modules, health, deployment order)
- **Binary Size:** 250KB statically compiled Ada binary
- **Network:** Full REST API integration with orchestrator at `http://localhost:4000`
- **Safety:** Ada/SPARK provides compile-time type safety and memory safety guarantees

## Known Seams (Improvement Opportunities)

See [SEAM_ANALYSIS.adoc](../SEAM_ANALYSIS.adoc) for comprehensive analysis. Key improvements identified:

🟡 **Important:**
- HTTP status code parsing (currently doesn't distinguish 404, 500, 503)
- More robust JSON parsing (consider full json-ada or gnatcoll-json library)

🟢 **Nice-to-have:**
- ANSI color validation (check terminal capability)
- Connection pooling (reuse sockets with keep-alive)
- Progress indicators for long operations
- Command autocompletion (bash/zsh)

## License

MPL-2.0-or-later (Ada/SPARK code)
See [palimpsest-license](https://github.com/hyperpolymath/palimpsest-license) for philosophy.
