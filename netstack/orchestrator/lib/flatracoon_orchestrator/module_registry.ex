# SPDX-License-Identifier: PMPL-1.0-or-later
# Module Registry - Tracks all FlatRacoon stack components

defmodule FlatracoonOrchestrator.ModuleRegistry do
  @moduledoc """
  Central registry for all FlatRacoon stack modules.
  Tracks deployment state, health status, and capabilities.
  """

  use GenServer
  require Logger

  alias FlatracoonOrchestrator.ModuleDiscovery

  @type module_status :: :not_deployed | :deploying | :healthy | :degraded | :failed
  @type module_layer ::
          :access
          | :overlay
          | :storage
          | :network
          | :naming
          | :backbone
          | :platform
          | :observability
          | :mcp

  @type module_manifest :: %{
          name: String.t(),
          version: String.t(),
          layer: module_layer(),
          repo: String.t(),
          requires: [String.t()],
          provides: [String.t()],
          config_schema: String.t() | nil,
          health_endpoint: String.t() | nil,
          metrics_endpoint: String.t() | nil,
          deployment_mode: :helm | :kubectl | :daemonset | :statefulset,
          namespace: String.t()
        }

  @type module_state :: %{
          manifest: module_manifest(),
          status: module_status(),
          last_health_check: DateTime.t() | nil,
          error_message: String.t() | nil,
          metrics: map()
        }

  ## Client API

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @doc """
  Register a module with its manifest.
  """
  @spec register_module(module_manifest()) :: :ok | {:error, term()}
  def register_module(manifest) do
    GenServer.call(__MODULE__, {:register, manifest})
  end

  @doc """
  Get all registered modules.
  """
  @spec list_modules() :: [module_state()]
  def list_modules do
    GenServer.call(__MODULE__, :list_modules)
  end

  @doc """
  Get modules by layer.
  """
  @spec list_modules_by_layer(module_layer()) :: [module_state()]
  def list_modules_by_layer(layer) do
    GenServer.call(__MODULE__, {:list_by_layer, layer})
  end

  @doc """
  Get a specific module by name.
  """
  @spec get_module(String.t()) :: {:ok, module_state()} | {:error, :not_found}
  def get_module(name) do
    GenServer.call(__MODULE__, {:get_module, name})
  end

  @doc """
  Update module status.
  """
  @spec update_status(String.t(), module_status(), String.t() | nil) :: :ok
  def update_status(name, status, error_message \\ nil) do
    GenServer.cast(__MODULE__, {:update_status, name, status, error_message})
  end

  @doc """
  Update module health check timestamp.
  """
  @spec record_health_check(String.t(), map()) :: :ok
  def record_health_check(name, metrics \\ %{}) do
    GenServer.cast(__MODULE__, {:record_health_check, name, metrics})
  end

  @doc """
  Get dependency graph (topologically sorted deployment order).
  """
  @spec deployment_order() :: {:ok, [String.t()]} | {:error, :circular_dependency}
  def deployment_order do
    GenServer.call(__MODULE__, :deployment_order)
  end

  @doc """
  Deploy all modules in dependency order.
  """
  @spec deploy_all() :: :ok | {:error, term()}
  def deploy_all do
    GenServer.call(__MODULE__, :deploy_all, :infinity)
  end

  @doc """
  Deploy a specific module.
  """
  @spec deploy_module(String.t()) :: :ok | {:error, :not_found} | {:error, term()}
  def deploy_module(name) do
    GenServer.call(__MODULE__, {:deploy_module, name}, 60_000)
  end

  @doc """
  Restart a specific module.
  """
  @spec restart_module(String.t()) :: :ok | {:error, :not_found} | {:error, term()}
  def restart_module(name) do
    GenServer.call(__MODULE__, {:restart_module, name}, 60_000)
  end

  @doc """
  Stop a specific module.
  """
  @spec stop_module(String.t()) :: :ok | {:error, :not_found} | {:error, term()}
  def stop_module(name) do
    GenServer.call(__MODULE__, {:stop_module, name}, 60_000)
  end

  @doc """
  Get logs for a specific module.
  """
  @spec get_logs(String.t(), non_neg_integer()) :: {:ok, String.t()} | {:error, :not_found} | {:error, term()}
  def get_logs(name, lines \\ 50) do
    GenServer.call(__MODULE__, {:get_logs, name, lines})
  end

  ## Server Callbacks

  @impl true
  def init(_) do
    # Initial state: map of module_name => module_state
    # Try to discover modules from manifest directories
    state =
      case FlatracoonOrchestrator.ModuleDiscovery.discover_modules() do
        modules when map_size(modules) > 0 ->
          Logger.info("Loaded #{map_size(modules)} modules from discovery")
          modules

        _empty ->
          Logger.warning("No modules discovered, using fallback definitions")
          FlatracoonOrchestrator.ModuleDiscovery.fallback_modules()
      end

    Logger.info("ModuleRegistry initialized with #{map_size(state)} modules")
    {:ok, state}
  end

  @impl true
  def handle_call({:register, manifest}, _from, state) do
    name = manifest.name

    module_state = %{
      manifest: manifest,
      status: :not_deployed,
      last_health_check: nil,
      error_message: nil,
      metrics: %{}
    }

    new_state = Map.put(state, name, module_state)
    Logger.info("Registered module: #{name} (layer: #{manifest.layer})")
    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call(:list_modules, _from, state) do
    modules = Map.values(state)
    {:reply, modules, state}
  end

  @impl true
  def handle_call({:list_by_layer, layer}, _from, state) do
    modules =
      state
      |> Map.values()
      |> Enum.filter(&(&1.manifest.layer == layer))

    {:reply, modules, state}
  end

  @impl true
  def handle_call({:get_module, name}, _from, state) do
    case Map.get(state, name) do
      nil -> {:reply, {:error, :not_found}, state}
      module -> {:reply, {:ok, module}, state}
    end
  end

  @impl true
  def handle_call(:deployment_order, _from, state) do
    # Build dependency graph and return topological sort
    case topological_sort(state) do
      {:ok, order} -> {:reply, {:ok, order}, state}
      {:error, reason} -> {:reply, {:error, reason}, state}
    end
  end

  @impl true
  def handle_call(:deploy_all, _from, state) do
    case topological_sort(state) do
      {:ok, order} ->
        result =
          Enum.reduce_while(order, :ok, fn name, _ ->
            case do_deploy_module(name, Map.get(state, name)) do
              :ok -> {:cont, :ok}
              {:error, reason} -> {:halt, {:error, {name, reason}}}
            end
          end)

        {:reply, result, state}

      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  @impl true
  def handle_call({:deploy_module, name}, _from, state) do
    case Map.get(state, name) do
      nil ->
        {:reply, {:error, :not_found}, state}

      module_state ->
        result = do_deploy_module(name, module_state)
        {:reply, result, state}
    end
  end

  @impl true
  def handle_call({:restart_module, name}, _from, state) do
    case Map.get(state, name) do
      nil ->
        {:reply, {:error, :not_found}, state}

      module_state ->
        result = do_restart_module(name, module_state)
        {:reply, result, state}
    end
  end

  @impl true
  def handle_call({:stop_module, name}, _from, state) do
    case Map.get(state, name) do
      nil ->
        {:reply, {:error, :not_found}, state}

      module_state ->
        result = do_stop_module(name, module_state)
        {:reply, result, state}
    end
  end

  @impl true
  def handle_call({:get_logs, name, lines}, _from, state) do
    case Map.get(state, name) do
      nil ->
        {:reply, {:error, :not_found}, state}

      module_state ->
        result = do_get_logs(name, module_state, lines)
        {:reply, result, state}
    end
  end

  @impl true
  def handle_cast({:update_status, name, status, error_message}, state) do
    new_state =
      case Map.get(state, name) do
        nil ->
          Logger.warning("Attempted to update status for non-existent module: #{name}")
          state

        module_state ->
          updated = %{module_state | status: status, error_message: error_message}
          Map.put(state, name, updated)
      end

    Logger.info("Module #{name} status: #{status}")
    {:noreply, new_state}
  end

  @impl true
  def handle_cast({:record_health_check, name, metrics}, state) do
    new_state =
      case Map.get(state, name) do
        nil ->
          Logger.warning("Attempted to record health check for non-existent module: #{name}")
          state

        module_state ->
          updated = %{
            module_state
            | last_health_check: DateTime.utc_now(),
              metrics: metrics
          }
          Map.put(state, name, updated)
      end

    {:noreply, new_state}
  end

  ## Private Functions

  defp topological_sort(state) do
    # Build adjacency list: module -> [dependencies]
    # Filter out any nil module states (should not happen, but defensive)
    graph =
      state
      |> Enum.filter(fn {_name, module_state} -> module_state != nil end)
      |> Enum.map(fn {name, module_state} ->
        {name, module_state.manifest.requires}
      end)
      |> Enum.into(%{})

    # Kahn's algorithm for topological sort
    in_degree =
      graph
      |> Enum.reduce(%{}, fn {node, deps}, acc ->
        acc = Map.put_new(acc, node, 0)

        Enum.reduce(deps, acc, fn dep, acc2 ->
          Map.update(acc2, dep, 1, &(&1 + 1))
        end)
      end)

    queue =
      in_degree
      |> Enum.filter(fn {_node, degree} -> degree == 0 end)
      |> Enum.map(fn {node, _degree} -> node end)

    do_topological_sort(graph, in_degree, queue, [])
  end

  defp do_topological_sort(_graph, _in_degree, [], result) do
    {:ok, Enum.reverse(result)}
  end

  defp do_topological_sort(graph, in_degree, [node | queue], result) do
    # Process node
    new_result = [node | result]

    # Get neighbors (modules that depend on this node)
    neighbors =
      graph
      |> Enum.filter(fn {_name, deps} -> node in deps end)
      |> Enum.map(fn {name, _deps} -> name end)

    # Decrease in-degree for neighbors
    {new_in_degree, new_queue} =
      Enum.reduce(neighbors, {in_degree, queue}, fn neighbor, {deg_acc, queue_acc} ->
        new_degree = Map.get(deg_acc, neighbor, 1) - 1
        deg_acc = Map.put(deg_acc, neighbor, new_degree)

        if new_degree == 0 do
          {deg_acc, [neighbor | queue_acc]}
        else
          {deg_acc, queue_acc}
        end
      end)

    do_topological_sort(graph, new_in_degree, new_queue, new_result)
  end

  # Deployment helper functions with exit code verification

  defp do_deploy_module(name, module_state) do
    Logger.info("Deploying module: #{name}")

    manifest = module_state.manifest
    namespace = manifest.namespace
    deployment_mode = manifest.deployment_mode

    # Update status to deploying
    update_status(name, :deploying)

    case deployment_mode do
      :helm ->
        deploy_helm_module(name, manifest, namespace)

      :kubectl ->
        deploy_kubectl_module(name, manifest, namespace)

      mode when mode in [:daemonset, :statefulset] ->
        deploy_kubectl_module(name, manifest, namespace)

      _ ->
        {:error, "Unsupported deployment mode: #{deployment_mode}"}
    end
  end

  defp deploy_helm_module(name, manifest, namespace) do
    chart_path = "../modules/#{manifest.repo |> String.split("/") |> List.last()}"

    # Run helm install/upgrade with exit code checking
    {output, exit_code} =
      System.cmd("helm", [
        "upgrade",
        "--install",
        name,
        chart_path,
        "--namespace",
        namespace,
        "--create-namespace",
        "--wait",
        "--timeout",
        "5m"
      ], stderr_to_stdout: true)

    case exit_code do
      0 ->
        update_status(name, :healthy)
        verify_deployment(name, namespace)

      _ ->
        Logger.error("Helm deployment failed for #{name}: #{output}")
        update_status(name, :failed, "Helm deployment failed: #{String.slice(output, 0, 200)}")
        {:error, "Helm deployment failed with exit code #{exit_code}"}
    end
  end

  defp deploy_kubectl_module(name, manifest, namespace) do
    manifest_path = "../modules/#{manifest.repo |> String.split("/") |> List.last()}/manifests/"

    # Run kubectl apply with exit code checking
    {output, exit_code} =
      System.cmd("kubectl", [
        "apply",
        "-f",
        manifest_path,
        "--namespace",
        namespace
      ], stderr_to_stdout: true)

    case exit_code do
      0 ->
        update_status(name, :deploying)
        verify_deployment(name, namespace)

      _ ->
        Logger.error("Kubectl deployment failed for #{name}: #{output}")
        update_status(name, :failed, "Kubectl deployment failed: #{String.slice(output, 0, 200)}")
        {:error, "Kubectl deployment failed with exit code #{exit_code}"}
    end
  end

  defp verify_deployment(name, namespace) do
    # Poll deployment status for up to 30 seconds
    max_attempts = 30
    verify_deployment_loop(name, namespace, max_attempts)
  end

  defp verify_deployment_loop(_name, _namespace, 0) do
    {:error, "Deployment verification timeout"}
  end

  defp verify_deployment_loop(name, namespace, attempts_left) do
    {_output, exit_code} =
      System.cmd("kubectl", [
        "rollout",
        "status",
        "deployment/#{name}",
        "--namespace",
        namespace,
        "--timeout",
        "1s"
      ], stderr_to_stdout: true)

    case exit_code do
      0 ->
        update_status(name, :healthy)
        :ok

      _ ->
        # Wait 1 second and retry
        Process.sleep(1000)
        verify_deployment_loop(name, namespace, attempts_left - 1)
    end
  end

  defp do_restart_module(name, module_state) do
    Logger.info("Restarting module: #{name}")
    namespace = module_state.manifest.namespace

    {output, exit_code} =
      System.cmd("kubectl", [
        "rollout",
        "restart",
        "deployment/#{name}",
        "--namespace",
        namespace
      ], stderr_to_stdout: true)

    case exit_code do
      0 ->
        update_status(name, :deploying)
        verify_deployment(name, namespace)

      _ ->
        Logger.error("Restart failed for #{name}: #{output}")
        update_status(name, :failed, "Restart failed: #{String.slice(output, 0, 200)}")
        {:error, "Restart failed with exit code #{exit_code}"}
    end
  end

  defp do_stop_module(name, module_state) do
    Logger.info("Stopping module: #{name}")
    namespace = module_state.manifest.namespace

    {output, exit_code} =
      System.cmd("kubectl", [
        "scale",
        "deployment/#{name}",
        "--replicas=0",
        "--namespace",
        namespace
      ], stderr_to_stdout: true)

    case exit_code do
      0 ->
        update_status(name, :not_deployed)
        :ok

      _ ->
        Logger.error("Stop failed for #{name}: #{output}")
        update_status(name, :failed, "Stop failed: #{String.slice(output, 0, 200)}")
        {:error, "Stop failed with exit code #{exit_code}"}
    end
  end

  defp do_get_logs(name, module_state, lines) do
    namespace = module_state.manifest.namespace

    {output, exit_code} =
      System.cmd("kubectl", [
        "logs",
        "deployment/#{name}",
        "--namespace",
        namespace,
        "--tail=#{lines}",
        "--all-containers=true"
      ], stderr_to_stdout: true)

    case exit_code do
      0 ->
        {:ok, output}

      _ ->
        Logger.error("Get logs failed for #{name}: #{output}")
        {:error, "Get logs failed with exit code #{exit_code}"}
    end
  end
end
