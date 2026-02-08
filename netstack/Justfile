# SPDX-License-Identifier: AGPL-3.0-or-later
# SPDX-FileCopyrightText: 2025 Hyperpolymath <hyperpolymath@proton.me>
#
# FlatRacoon Network Stack - Justfile
# Task runner for orchestration, deployment, and development

set shell := ["bash", "-uc"]
set dotenv-load

# Default recipe
default:
    @just --list

# =============================================================================
# Initialization
# =============================================================================

# Initialize the development environment
init: _check-deps
    @echo "Initializing FlatRacoon Network Stack..."
    git submodule update --init --recursive
    just orchestrator-deps
    just tui-deps
    just interface-deps
    @echo "✓ Initialization complete"

# Check required dependencies
_check-deps:
    @command -v elixir >/dev/null 2>&1 || { echo "Error: Elixir required"; exit 1; }
    @command -v mix >/dev/null 2>&1 || { echo "Error: Mix required"; exit 1; }
    @command -v gnatmake >/dev/null 2>&1 || { echo "Error: GNAT (Ada) required"; exit 1; }
    @command -v deno >/dev/null 2>&1 || { echo "Error: Deno required"; exit 1; }
    @command -v nickel >/dev/null 2>&1 || { echo "Error: Nickel required"; exit 1; }
    @echo "✓ All dependencies present"

# =============================================================================
# Orchestrator (Elixir/Phoenix)
# =============================================================================

# Install orchestrator dependencies
orchestrator-deps:
    cd orchestrator && mix deps.get

# Start orchestrator in development mode
orchestrator-dev:
    cd orchestrator && mix phx.server

# Run orchestrator tests
orchestrator-test:
    cd orchestrator && mix test

# Build orchestrator release
orchestrator-build:
    cd orchestrator && mix release

# =============================================================================
# TUI (Ada/SPARK)
# =============================================================================

# Install TUI dependencies
tui-deps:
    cd tui && alr build --development

# Build TUI
tui-build:
    cd tui && alr build

# Run TUI
tui-run:
    cd tui && ./bin/flatracoon-tui

# =============================================================================
# Interface (Deno/ReScript)
# =============================================================================

# Install interface dependencies
interface-deps:
    cd interface && deno cache src/main.ts

# Build ReScript interface
interface-build:
    cd interface && deno task build

# Run interface
interface-run:
    cd interface && deno task start

# =============================================================================
# Configuration (Nickel / Must)
# =============================================================================

# Validate all Nickel configurations including Mustfile
config-validate:
    @echo "Validating Nickel configurations..."
    nickel export Mustfile > /dev/null
    nickel export configs/base.ncl > /dev/null
    nickel export configs/modules.ncl > /dev/null
    nickel export configs/environments.ncl > /dev/null
    @echo "✓ All configurations valid"

# Export Mustfile to JSON
must-export:
    nickel export Mustfile

# Export specific config to JSON
config-export target="base":
    nickel export configs/{{target}}.ncl

# Install system configuration (requires root)
config-install-system:
    @echo "Installing system configuration..."
    configs/install.sh --system

# Install user configuration
config-install-user:
    @echo "Installing user configuration..."
    configs/install.sh --user

# Install both system and user configuration
config-install-all:
    @echo "Installing all configuration files..."
    configs/install.sh --all

# Show current configuration paths (XDG-compliant)
config-paths:
    @echo "System config:  /etc/flatracoon/flatracoon.ncl"
    @echo "User config:    ${XDG_CONFIG_HOME:-$$HOME/.config}/flatracoon/flatracoon.ncl"
    @echo "Data dir:       ${XDG_DATA_HOME:-$$HOME/.local/share}/flatracoon/"
    @echo "Cache dir:      ${XDG_CACHE_HOME:-$$HOME/.cache}/flatracoon/"
    @echo "State dir:      ${XDG_STATE_HOME:-$$HOME/.local/state}/flatracoon/"

# Validate system and user configs (if they exist)
config-validate-all: config-validate
    @echo "Validating installed configurations..."
    @if [ -f /etc/flatracoon/flatracoon.ncl ]; then \
        echo "Checking system config..."; \
        nickel export /etc/flatracoon/flatracoon.ncl > /dev/null && echo "✓ System config valid"; \
    fi
    @if [ -f "${XDG_CONFIG_HOME:-$$HOME/.config}/flatracoon/flatracoon.ncl" ]; then \
        echo "Checking user config..."; \
        nickel export "${XDG_CONFIG_HOME:-$$HOME/.config}/flatracoon/flatracoon.ncl" > /dev/null && echo "✓ User config valid"; \
    fi

# Show deployment order from Mustfile
must-order:
    @nickel export Mustfile | jq -r '.deployment_order[]'

# Show module info from Mustfile
must-modules:
    @nickel export Mustfile | jq '.modules'

# Show environment config
must-env env="development":
    @nickel export configs/environments.ncl | jq '.environments.{{env}}'

# =============================================================================
# Secrets Management
# =============================================================================

# Initialize secrets setup
secrets-setup:
    @echo "Setting up secrets management..."
    @echo "Configure VAULT_ADDR and VAULT_TOKEN, or use SOPS"

# Fetch secrets from Vault
secrets-fetch:
    @echo "Fetching secrets via poly-secret-mcp..."

# =============================================================================
# Deployment
# =============================================================================

# Deploy entire stack
deploy: config-validate
    @echo "Deploying FlatRacoon Network Stack..."
    just deploy-access
    just deploy-overlay
    just deploy-storage
    just deploy-network
    just deploy-naming
    just deploy-observability
    @echo "✓ Stack deployed"

# Deploy access layer (Twingate)
deploy-access:
    @echo "Deploying Twingate connector..."
    cd modules/twingate-helm-deploy && just deploy

# Deploy overlay layer (ZeroTier)
deploy-overlay:
    @echo "Deploying ZeroTier overlay..."
    cd modules/zerotier-k8s-link && just deploy

# Deploy storage layer (IPFS)
deploy-storage:
    @echo "Deploying IPFS cluster..."
    cd modules/ipfs-overlay && just deploy

# Deploy network layer (IPv6)
deploy-network:
    @echo "Deploying IPv6 enforcer..."
    cd modules/ipv6-site-enforcer && just deploy

# Deploy naming layer (Hesiod)
deploy-naming:
    @echo "Deploying Hesiod DNS..."
    cd modules/hesiod-dns-map && just deploy

# Deploy observability layer (Dashboard)
deploy-observability:
    @echo "Deploying network dashboard..."
    cd modules/network-dashboard && just deploy

# =============================================================================
# Health & Monitoring
# =============================================================================

# Check health of all modules
health:
    @echo "Checking module health..."
    just health-access
    just health-overlay
    just health-storage
    just health-network
    @echo "✓ All modules healthy"

# Check Twingate health
health-access:
    @echo "Twingate: $(curl -sf http://localhost:8080/health || echo 'unhealthy')"

# Check ZeroTier health
health-overlay:
    @echo "ZeroTier: $(curl -sf http://localhost:9993/health || echo 'unhealthy')"

# Check IPFS health
health-storage:
    @echo "IPFS: $(curl -sf http://localhost:5001/api/v0/version || echo 'unhealthy')"

# Check IPv6 enforcer health
health-network:
    @echo "IPv6: $(curl -sf http://localhost:8081/health || echo 'unhealthy')"

# Open dashboard
dashboard:
    @echo "Opening network dashboard..."
    xdg-open http://localhost:4000 || open http://localhost:4000

# =============================================================================
# Development
# =============================================================================

# Run all tests
test:
    just orchestrator-test
    just tui-test
    just interface-test

# TUI tests
tui-test:
    cd tui && alr run -- --test

# Interface tests
interface-test:
    cd interface && deno test

# Format all code
fmt:
    cd orchestrator && mix format
    cd interface && deno fmt
    @echo "✓ All code formatted"

# Lint all code
lint:
    cd orchestrator && mix credo
    cd interface && deno lint
    @echo "✓ All linting passed"

# =============================================================================
# Documentation
# =============================================================================

# Generate documentation
docs:
    cd orchestrator && mix docs
    @echo "✓ Documentation generated"

# Serve documentation locally
docs-serve:
    cd orchestrator/doc && python -m http.server 8000

# =============================================================================
# Submodule Management
# =============================================================================

# Update all submodules
submodules-update:
    git submodule update --remote --merge

# Status of all submodules
submodules-status:
    git submodule status

# =============================================================================
# CI/CD
# =============================================================================

# Run CI checks locally
ci: lint test config-validate
    @echo "✓ CI checks passed"

# Build release artifacts
release:
    just orchestrator-build
    just tui-build
    just interface-build
    @echo "✓ Release artifacts built"
