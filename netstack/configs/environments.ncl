# SPDX-License-Identifier: AGPL-3.0-or-later
# SPDX-FileCopyrightText: 2025 Hyperpolymath <hyperpolymath@proton.me>
#
# FlatRacoon Network Stack - Environment Configurations
# Per-environment settings and overrides

let base = import "base.ncl"
in

{
  environments = {
    development = {
      name = "development",
      kubernetes = {
        context = "minikube",
        namespace = "flatracoon-dev",
        service_account = "flatracoon-dev",
      },
      network = {
        ipv6_prefix = "fd00:flatracoon:dev::/48",
        ipv6_only = false,  # Allow IPv4 in dev for convenience
        nat64_enabled = false,
        dns64_enabled = false,
      },
      twingate = {
        network = "dev-network",
        log_level = "debug",
      },
      zerotier = {
        network_id = "0000000000000001",  # Placeholder
        allow_managed = true,
        allow_global = false,
      },
      ipfs = {
        bootstrap = [],  # Empty for local development
        swarm_key = "dev-swarm-key",  # Generated locally
        gateway_enabled = true,
      },
      dashboard = {
        host = "localhost",
        port = 4000,
        live_reload = true,
      },
    },

    staging = {
      name = "staging",
      kubernetes = {
        context = "staging-cluster",
        namespace = "flatracoon-staging",
        service_account = "flatracoon-staging",
      },
      network = {
        ipv6_prefix = "fd00:flatracoon:staging::/48",
        ipv6_only = true,
        nat64_enabled = true,
        dns64_enabled = true,
      },
      twingate = {
        network = "staging-network",
        log_level = "info",
      },
      zerotier = {
        network_id = "0000000000000002",  # Placeholder
        allow_managed = true,
        allow_global = false,
      },
      ipfs = {
        bootstrap = ["ipfs-bootstrap-staging.internal:4001"],
        swarm_key_secret = "ipfs-swarm-key",  # From Vault
        gateway_enabled = true,
      },
      dashboard = {
        host = "0.0.0.0",
        port = 4000,
        live_reload = false,
      },
    },

    production = {
      name = "production",
      kubernetes = {
        context = "production-cluster",
        namespace = "flatracoon",
        service_account = "flatracoon-orchestrator",
      },
      network = {
        ipv6_prefix = "2001:db8:flatracoon::/48",  # Replace with real allocation
        ipv6_only = true,
        nat64_enabled = true,
        dns64_enabled = true,
      },
      twingate = {
        network = "prod-network",
        log_level = "warn",
      },
      zerotier = {
        network_id = "0000000000000003",  # Placeholder - use real ID
        allow_managed = true,
        allow_global = false,
      },
      ipfs = {
        bootstrap = [
          "ipfs-bootstrap-1.flatracoon.net:4001",
          "ipfs-bootstrap-2.flatracoon.net:4001",
          "ipfs-bootstrap-3.flatracoon.net:4001",
        ],
        swarm_key_secret = "ipfs-swarm-key",  # From Vault
        gateway_enabled = false,  # No public gateway in prod
      },
      dashboard = {
        host = "0.0.0.0",
        port = 4000,
        live_reload = false,
      },
    },
  },

  # Default environment
  default_environment = "development",

  # Helper to get environment config
  get_env = fun env_name =>
    if std.record.has_field env_name environments then
      environments."%{env_name}"
    else
      std.fail_with "Unknown environment: %{env_name}",
}
