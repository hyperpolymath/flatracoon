defmodule FlatracoonOrchestrator.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      FlatracoonOrchestratorWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:flatracoon_orchestrator, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: FlatracoonOrchestrator.PubSub},
      # FlatRacoon orchestrator services
      FlatracoonOrchestrator.ModuleRegistry,
      FlatracoonOrchestrator.HealthMonitor,
      # Start to serve requests, typically the last entry
      FlatracoonOrchestratorWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: FlatracoonOrchestrator.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    FlatracoonOrchestratorWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
