# SPDX-License-Identifier: AGPL-3.0-or-later
# SPDX-FileCopyrightText: 2025 Hyperpolymath <hyperpolymath@proton.me>
#
# FlatRacoon Network Stack - Base Configuration
# Core type definitions and shared configuration

# Type contracts
let Environment = [| 'development, 'staging, 'production |]
in

let Layer = [|
  'access,
  'overlay,
  'storage,
  'network,
  'naming,
  'platform,
  'observability,
  'orchestration
|]
in

let ModuleStatus = [| 'pending, 'deploying, 'running, 'degraded, 'failed |]
in

let HealthStatus = [| 'healthy, 'degraded, 'unhealthy, 'unknown |]
in

# Module manifest contract
let ModuleManifest = {
  name | String,
  version | String,
  layer | Layer,
  description | String | optional,
  requires | Array String | default = [],
  provides | Array String | default = [],
  config_schema | String | optional,
  health_endpoint | String | optional,
  metrics_endpoint | String | optional,
}
in

# Health check configuration contract
let HealthCheckConfig = {
  timeout_seconds | Number | default = 30,
  retry_count | Number | default = 3,
  retry_delay_seconds | Number | default = 5,
  unhealthy_threshold | Number | default = 3,
  healthy_threshold | Number | default = 1,
}
in

# Kubernetes configuration contract
let KubernetesConfig = {
  context | String,
  namespace | String | default = "flatracoon",
  service_account | String | default = "flatracoon-orchestrator",
}
in

# Network configuration contract
let NetworkConfig = {
  ipv6_prefix | String,
  ipv6_only | Bool | default = true,
  nat64_enabled | Bool | default = true,
  dns64_enabled | Bool | default = true,
}
in

# Base configuration
{
  version = "1.0.0",
  name = "flatracoon-netstack",

  # Default health check settings
  health_checks = {
    timeout_seconds = 30,
    retry_count = 3,
    retry_delay_seconds = 5,
    unhealthy_threshold = 3,
    healthy_threshold = 1,
  } | HealthCheckConfig,

  # Deployment order (by layer)
  deployment_order = [
    "twingate-helm-deploy",
    "zerotier-k8s-link",
    "ipfs-overlay",
    "ipv6-site-enforcer",
    "hesiod-dns-map",
    "network-dashboard",
  ],

  # Module registry (populated by modules.ncl)
  modules = {},

  # Type exports for other configs
  types = {
    Environment = Environment,
    Layer = Layer,
    ModuleStatus = ModuleStatus,
    HealthStatus = HealthStatus,
    ModuleManifest = ModuleManifest,
    HealthCheckConfig = HealthCheckConfig,
    KubernetesConfig = KubernetesConfig,
    NetworkConfig = NetworkConfig,
  },
}
