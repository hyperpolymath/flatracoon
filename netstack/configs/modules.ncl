# SPDX-License-Identifier: AGPL-3.0-or-later
# SPDX-FileCopyrightText: 2025 Hyperpolymath <hyperpolymath@proton.me>
#
# FlatRacoon Network Stack - Module Registry
# Definitions for all stack modules

let base = import "base.ncl"
in

{
  modules = {
    twingate-helm-deploy = {
      name = "twingate-helm-deploy",
      version = "0.1.0",
      layer = 'access,
      description = "Twingate Connector deployment via Helm",
      requires = ["kubernetes"],
      provides = ["secure-access", "zero-trust-ingress"],
      config_schema = "twingate/schema.ncl",
      health_endpoint = "/health",
      metrics_endpoint = "/metrics",
      path = "modules/twingate-helm-deploy",
      deploy_command = "just deploy",
    },

    zerotier-k8s-link = {
      name = "zerotier-k8s-link",
      version = "0.1.0",
      layer = 'overlay,
      description = "ZeroTier overlay mesh for Kubernetes",
      requires = ["kubernetes"],
      provides = ["encrypted-mesh", "nat-traversal", "private-routing"],
      config_schema = "zerotier/schema.ncl",
      health_endpoint = "/zerotier/health",
      metrics_endpoint = "/zerotier/metrics",
      path = "modules/zerotier-k8s-link",
      deploy_command = "just deploy",
    },

    ipfs-overlay = {
      name = "ipfs-overlay",
      version = "0.1.0",
      layer = 'storage,
      description = "Private IPFS cluster on ZeroTier overlay",
      requires = ["kubernetes", "zerotier-k8s-link"],
      provides = ["distributed-storage", "content-addressing", "pinning"],
      config_schema = "ipfs/schema.ncl",
      health_endpoint = "/ipfs/health",
      metrics_endpoint = "/ipfs/metrics",
      path = "modules/ipfs-overlay",
      deploy_command = "just deploy",
    },

    ipv6-site-enforcer = {
      name = "ipv6-site-enforcer",
      version = "0.1.0",
      layer = 'network,
      description = "IPv6-only enforcement with NAT64/DNS64",
      requires = ["kubernetes"],
      provides = ["ipv6-only-ingress", "nat64", "dns64"],
      config_schema = "ipv6/schema.ncl",
      health_endpoint = "/ipv6/health",
      metrics_endpoint = "/ipv6/metrics",
      path = "modules/ipv6-site-enforcer",
      deploy_command = "just deploy",
    },

    hesiod-dns-map = {
      name = "hesiod-dns-map",
      version = "0.1.0",
      layer = 'naming,
      description = "Hesiod DNS service discovery",
      requires = ["kubernetes"],
      provides = ["hesiod-dns", "service-discovery", "user-lookup"],
      config_schema = "hesiod/schema.ncl",
      health_endpoint = "/dns/health",
      metrics_endpoint = "/dns/metrics",
      path = "modules/hesiod-dns-map",
      deploy_command = "just deploy",
    },

    bgp-backbone-lab = {
      name = "bgp-backbone-lab",
      version = "0.1.0",
      layer = 'network,
      description = "BGP routing simulation lab",
      requires = ["containerlab"],
      provides = ["bgp-simulation", "route-validation", "traffic-engineering"],
      config_schema = "bgp/schema.ncl",
      health_endpoint = null,
      metrics_endpoint = "/bgp/metrics",
      path = "modules/bgp-backbone-lab",
      deploy_command = "just deploy",
    },

    flatracoon-os = {
      name = "flatracoon-os",
      version = "0.1.0",
      layer = 'platform,
      description = "Minix-Flatcar hybrid microkernel OS",
      requires = [],
      provides = ["immutable-os", "microkernel", "container-runtime"],
      config_schema = "os/schema.ncl",
      health_endpoint = null,
      metrics_endpoint = null,
      path = "modules/flatracoon-os",
      deploy_command = "just build",
    },

    network-dashboard = {
      name = "network-dashboard",
      version = "0.1.0",
      layer = 'observability,
      description = "Phoenix LiveView monitoring dashboard",
      requires = ["elixir", "prometheus"],
      provides = ["dashboard", "alerting", "visualization"],
      config_schema = "dashboard/schema.ncl",
      health_endpoint = "/health",
      metrics_endpoint = "/metrics",
      path = "modules/network-dashboard",
      deploy_command = "just deploy",
    },
  },

  # MCP integrations
  mcp_integrations = {
    poly-k8s-mcp = {
      name = "poly-k8s-mcp",
      path = "modules/poly-k8s-mcp",
      provides = ["kubectl", "helm", "kustomize"],
    },

    poly-secret-mcp = {
      name = "poly-secret-mcp",
      path = "modules/poly-secret-mcp",
      provides = ["vault", "sops"],
    },

    poly-observability-mcp = {
      name = "poly-observability-mcp",
      path = "modules/poly-observability-mcp",
      provides = ["prometheus", "grafana", "loki", "jaeger"],
    },
  },

  # Computed: all module names
  module_names = std.record.fields modules,

  # Helper to get modules by layer
  modules_by_layer = fun layer =>
    std.record.filter (fun _name mod => mod.layer == layer) modules,
}
