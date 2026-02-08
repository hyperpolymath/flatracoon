defmodule FlatracoonOrchestratorWeb.ApiController do
  use FlatracoonOrchestratorWeb, :controller
  alias FlatracoonOrchestrator.{ModuleRegistry, HealthMonitor}

  def list_modules(conn, _params) do
    modules = ModuleRegistry.list_modules()
    json(conn, %{modules: modules})
  end

  def get_module(conn, %{"name" => name}) do
    case ModuleRegistry.get_module(name) do
      {:ok, module} ->
        json(conn, %{module: module})
      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Module not found"})
    end
  end

  def health_summary(conn, _params) do
    health = HealthMonitor.get_summary()
    json(conn, %{health: health})
  end

  def deployment_order(conn, _params) do
    order = ModuleRegistry.deployment_order()
    json(conn, %{order: order})
  end

  def deploy_all(conn, _params) do
    case ModuleRegistry.deploy_all() do
      :ok ->
        json(conn, %{status: "deployment_initiated", message: "All modules deployment started"})
      {:error, reason} ->
        conn
        |> put_status(:internal_server_error)
        |> json(%{error: "Deployment failed", reason: reason})
    end
  end

  def deploy_module(conn, %{"name" => name}) do
    case ModuleRegistry.deploy_module(name) do
      :ok ->
        json(conn, %{status: "deployment_initiated", module: name})
      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Module not found"})
      {:error, reason} ->
        conn
        |> put_status(:internal_server_error)
        |> json(%{error: "Deployment failed", reason: reason})
    end
  end

  def restart_module(conn, %{"name" => name}) do
    case ModuleRegistry.restart_module(name) do
      :ok ->
        json(conn, %{status: "restart_initiated", module: name})
      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Module not found"})
      {:error, reason} ->
        conn
        |> put_status(:internal_server_error)
        |> json(%{error: "Restart failed", reason: reason})
    end
  end

  def stop_module(conn, %{"name" => name}) do
    case ModuleRegistry.stop_module(name) do
      :ok ->
        json(conn, %{status: "stop_initiated", module: name})
      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Module not found"})
      {:error, reason} ->
        conn
        |> put_status(:internal_server_error)
        |> json(%{error: "Stop failed", reason: reason})
    end
  end

  def get_logs(conn, %{"name" => name} = params) do
    lines = Map.get(params, "lines", "50") |> String.to_integer()

    case ModuleRegistry.get_logs(name, lines) do
      {:ok, logs} ->
        json(conn, %{module: name, logs: logs})
      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Module not found"})
      {:error, reason} ->
        conn
        |> put_status(:internal_server_error)
        |> json(%{error: "Failed to retrieve logs", reason: reason})
    end
  end
end
