# SPDX-License-Identifier: PMPL-1.0-or-later
# Health Monitor - Aggregates health checks from all modules

defmodule FlatracoonOrchestrator.HealthMonitor do
  @moduledoc """
  Periodic health check monitor for all FlatRacoon stack modules.
  Polls health endpoints and updates module status in the registry.
  """

  use GenServer
  require Logger
  alias FlatracoonOrchestrator.ModuleRegistry

  @check_interval :timer.seconds(30)

  ## Client API

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @doc """
  Trigger an immediate health check for all modules.
  """
  def check_all do
    GenServer.cast(__MODULE__, :check_all)
  end

  @doc """
  Trigger health check for a specific module.
  """
  def check_module(name) do
    GenServer.cast(__MODULE__, {:check_module, name})
  end

  ## Server Callbacks

  @impl true
  def init(_) do
    # Schedule periodic health checks
    schedule_check()
    Logger.info("HealthMonitor started")
    {:ok, %{}}
  end

  @impl true
  def handle_cast(:check_all, state) do
    modules = ModuleRegistry.list_modules()
    Enum.each(modules, &perform_health_check/1)
    {:noreply, state}
  end

  @impl true
  def handle_cast({:check_module, name}, state) do
    case ModuleRegistry.get_module(name) do
      {:ok, module_state} ->
        perform_health_check(module_state)

      {:error, :not_found} ->
        Logger.warning("Module not found for health check: #{name}")
    end

    {:noreply, state}
  end

  @impl true
  def handle_info(:periodic_check, state) do
    modules = ModuleRegistry.list_modules()
    Enum.each(modules, &perform_health_check/1)
    schedule_check()
    {:noreply, state}
  end

  ## Private Functions

  defp schedule_check do
    Process.send_after(self(), :periodic_check, @check_interval)
  end

  defp perform_health_check(%{manifest: manifest, status: status} = _module_state) do
    name = manifest.name

    # Skip health check if not deployed
    if status == :not_deployed do
      Logger.debug("Skipping health check for #{name} (not deployed)")
      :ok
    else
      check_kubernetes_health(manifest)
    end
  end

  defp check_kubernetes_health(manifest) do
    namespace = manifest.namespace
    name = manifest.name

    case check_deployment_status(namespace, name, manifest.deployment_mode) do
      {:ok, metrics} ->
        ModuleRegistry.update_status(name, :healthy, nil)
        ModuleRegistry.record_health_check(name, metrics)
        Logger.debug("Health check passed: #{name}")

      {:degraded, metrics, reason} ->
        ModuleRegistry.update_status(name, :degraded, reason)
        ModuleRegistry.record_health_check(name, metrics)
        Logger.warning("Health check degraded: #{name} - #{reason}")

      {:error, reason} ->
        ModuleRegistry.update_status(name, :failed, reason)
        Logger.error("Health check failed: #{name} - #{reason}")
    end
  end

  defp check_deployment_status(namespace, name, :helm) do
    # Check Helm release status
    case System.cmd("helm", ["status", name, "-n", namespace, "-o", "json"], stderr_to_stdout: true) do
      {output, 0} ->
        case Jason.decode(output) do
          {:ok, %{"info" => %{"status" => "deployed"}}} ->
            {:ok, %{helm_status: "deployed"}}

          {:ok, %{"info" => %{"status" => status}}} ->
            {:degraded, %{helm_status: status}, "Helm status: #{status}"}

          _ ->
            {:error, "Failed to parse Helm output"}
        end

      {output, _} ->
        {:error, "Helm command failed: #{output}"}
    end
  rescue
    e -> {:error, "Exception during Helm check: #{Exception.message(e)}"}
  end

  defp check_deployment_status(namespace, _name, :daemonset) do
    # Check DaemonSet status
    case System.cmd("kubectl", [
           "get",
           "daemonset",
           "-n",
           namespace,
           "-o",
           "json"
         ]) do
      {output, 0} ->
        case Jason.decode(output) do
          {:ok, %{"items" => [_ | _] = items}} ->
            ds = List.first(items)

            status = ds["status"]
            desired = status["desiredNumberScheduled"] || 0
            ready = status["numberReady"] || 0

            if ready == desired and desired > 0 do
              {:ok, %{desired: desired, ready: ready}}
            else
              {:degraded, %{desired: desired, ready: ready}, "#{ready}/#{desired} pods ready"}
            end

          _ ->
            {:error, "No DaemonSets found"}
        end

      {output, _} ->
        {:error, "kubectl command failed: #{output}"}
    end
  rescue
    e -> {:error, "Exception during DaemonSet check: #{Exception.message(e)}"}
  end

  defp check_deployment_status(namespace, _name, :statefulset) do
    # Check StatefulSet status
    case System.cmd("kubectl", [
           "get",
           "statefulset",
           "-n",
           namespace,
           "-o",
           "json"
         ]) do
      {output, 0} ->
        case Jason.decode(output) do
          {:ok, %{"items" => [_ | _] = items}} ->
            sts = List.first(items)
            status = sts["status"]
            replicas = status["replicas"] || 0
            ready = status["readyReplicas"] || 0

            if ready == replicas and replicas > 0 do
              {:ok, %{replicas: replicas, ready: ready}}
            else
              {:degraded, %{replicas: replicas, ready: ready}, "#{ready}/#{replicas} replicas ready"}
            end

          _ ->
            {:error, "No StatefulSets found"}
        end

      {output, _} ->
        {:error, "kubectl command failed: #{output}"}
    end
  rescue
    e -> {:error, "Exception during StatefulSet check: #{Exception.message(e)}"}
  end

  defp check_deployment_status(namespace, _name, :kubectl) do
    # Generic kubectl check (look for any pods in namespace)
    case System.cmd("kubectl", ["get", "pods", "-n", namespace, "-o", "json"]) do
      {output, 0} ->
        case Jason.decode(output) do
          {:ok, %{"items" => [_ | _] = items}} ->
            running = Enum.count(items, fn pod ->
              pod["status"]["phase"] == "Running"
            end)

            total = length(items)

            if running == total and total > 0 do
              {:ok, %{total_pods: total, running_pods: running}}
            else
              {:degraded, %{total_pods: total, running_pods: running},
               "#{running}/#{total} pods running"}
            end

          _ ->
            {:error, "No pods found"}
        end

      {output, _} ->
        {:error, "kubectl command failed: #{output}"}
    end
  rescue
    e -> {:error, "Exception during kubectl check: #{Exception.message(e)}"}
  end
end
