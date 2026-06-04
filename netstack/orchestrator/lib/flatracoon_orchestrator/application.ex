# SPDX-License-Identifier: MPL-2.0
# Copyright (c) Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
defmodule FlatracoonOrchestrator.Application do
  @moduledoc """
  Entry point for the Flatracoon Orchestrator service.

  This module defines the primary supervision tree for the orchestration engine, 
  ensuring that critical services like the Module Registry and Health Monitor 
  are started and restarted according to the specified strategy.
  """

  use Application

  @impl true
  def start(_type, _args) do
    # SUPERVISION TREE:
    # 1. Telemetry: Gathers metrics for the orchestrator.
    # 2. DNSCluster: Handles node discovery in a distributed cluster.
    # 3. PubSub: Real-time messaging between orchestrator components.
    # 4. ModuleRegistry: Authoritative store for FlatRacoon module state (.manifest.ncl).
    # 5. HealthMonitor: Periodically checks health_endpoints of deployed modules.
    # 6. Endpoint: Starts the Phoenix web server for the dashboard/API.
    children = [
      FlatracoonOrchestratorWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:flatracoon_orchestrator, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: FlatracoonOrchestrator.PubSub},
      # FlatRacoon orchestrator services
      FlatracoonOrchestrator.ModuleRegistry,
      FlatracoonOrchestrator.HealthMonitor,
      # Web / API Interface
      FlatracoonOrchestratorWeb.Endpoint
    ]

    # STRATEGY: :one_for_one ensures that if a child process crashes, 
    # only that process is restarted.
    opts = [strategy: :one_for_one, name: FlatracoonOrchestrator.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    FlatracoonOrchestratorWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
