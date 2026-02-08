# SPDX-License-Identifier: PMPL-1.0-or-later
# Dashboard LiveView - Real-time FlatRacoon stack monitoring

defmodule FlatracoonOrchestratorWeb.DashboardLive do
  use FlatracoonOrchestratorWeb, :live_view
  require Logger
  alias FlatracoonOrchestrator.{ModuleRegistry, HealthMonitor}

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      # Subscribe to updates
      :timer.send_interval(5000, self(), :refresh)
    end

    socket =
      socket
      |> assign(:modules, load_modules(:all))
      |> assign(:selected_layer, :all)

    {:ok, socket}
  end

  @impl true
  def handle_event("select_layer", %{"layer" => layer}, socket) do
    selected_layer = String.to_existing_atom(layer)

    socket =
      socket
      |> assign(:selected_layer, selected_layer)
      |> assign(:modules, load_modules(selected_layer))

    {:noreply, socket}
  end

  @impl true
  def handle_event("check_health", %{"module" => module_name}, socket) do
    HealthMonitor.check_module(module_name)
    Process.send_after(self(), :refresh, 500)
    {:noreply, socket}
  end

  @impl true
  def handle_event("check_all", _params, socket) do
    HealthMonitor.check_all()
    Process.send_after(self(), :refresh, 1000)
    {:noreply, socket}
  end

  @impl true
  def handle_info(:refresh, socket) do
    socket = assign(socket, :modules, load_modules(socket.assigns.selected_layer))
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-900 text-gray-100">
      <!-- Header -->
      <header class="bg-gray-800 border-b border-gray-700 p-6">
        <div class="container mx-auto">
          <h1 class="text-3xl font-bold text-purple-400">FlatRacoon Network Stack</h1>
          <p class="text-gray-400 mt-2">Orchestrator Dashboard</p>
        </div>
      </header>

      <!-- Main Content -->
      <div class="container mx-auto p-6">
        <!-- Actions Bar -->
        <div class="flex justify-between items-center mb-6">
          <div class="flex gap-2">
            <button
              phx-click="select_layer"
              phx-value-layer="all"
              class={"px-4 py-2 rounded #{if @selected_layer == :all, do: "bg-purple-600", else: "bg-gray-700 hover:bg-gray-600"}"}
            >
              All Layers
            </button>
            <button
              phx-click="select_layer"
              phx-value-layer="access"
              class={"px-4 py-2 rounded #{if @selected_layer == :access, do: "bg-purple-600", else: "bg-gray-700 hover:bg-gray-600"}"}
            >
              Access
            </button>
            <button
              phx-click="select_layer"
              phx-value-layer="overlay"
              class={"px-4 py-2 rounded #{if @selected_layer == :overlay, do: "bg-purple-600", else: "bg-gray-700 hover:bg-gray-600"}"}
            >
              Overlay
            </button>
            <button
              phx-click="select_layer"
              phx-value-layer="storage"
              class={"px-4 py-2 rounded #{if @selected_layer == :storage, do: "bg-purple-600", else: "bg-gray-700 hover:bg-gray-600"}"}
            >
              Storage
            </button>
            <button
              phx-click="select_layer"
              phx-value-layer="mcp"
              class={"px-4 py-2 rounded #{if @selected_layer == :mcp, do: "bg-purple-600", else: "bg-gray-700 hover:bg-gray-600"}"}
            >
              MCP
            </button>
          </div>

          <button
            phx-click="check_all"
            class="px-6 py-2 bg-green-600 hover:bg-green-700 rounded font-semibold"
          >
            Check All Health
          </button>
        </div>

        <!-- Stack Status Overview -->
        <div class="grid grid-cols-1 md:grid-cols-4 gap-4 mb-8">
          <%= for {status, count} <- status_counts(@modules) do %>
            <div class="bg-gray-800 p-4 rounded-lg border border-gray-700">
              <div class="flex items-center justify-between">
                <span class="text-gray-400 text-sm font-medium">
                  <%= status_label(status) %>
                </span>
                <span class={"text-2xl font-bold #{status_color(status)}"}>
                  <%= count %>
                </span>
              </div>
            </div>
          <% end %>
        </div>

        <!-- Modules Grid -->
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          <%= for module <- @modules do %>
            <div class="bg-gray-800 rounded-lg border border-gray-700 p-6 hover:border-purple-500 transition">
              <!-- Module Header -->
              <div class="flex items-start justify-between mb-4">
                <div>
                  <h3 class="text-xl font-bold text-purple-300">
                    <%= module.manifest.name %>
                  </h3>
                  <p class="text-sm text-gray-400">
                    <%= layer_label(module.manifest.layer) %> Layer
                  </p>
                </div>
                <span class={"px-3 py-1 rounded-full text-xs font-semibold #{status_badge_class(module.status)}"}>
                  <%= status_label(module.status) %>
                </span>
              </div>

              <!-- Module Info -->
              <div class="space-y-2 text-sm mb-4">
                <div class="flex justify-between">
                  <span class="text-gray-400">Version:</span>
                  <span class="text-gray-200"><%= module.manifest.version %></span>
                </div>
                <div class="flex justify-between">
                  <span class="text-gray-400">Namespace:</span>
                  <span class="text-gray-200"><%= module.manifest.namespace %></span>
                </div>
                <div class="flex justify-between">
                  <span class="text-gray-400">Mode:</span>
                  <span class="text-gray-200">
                    <%= module.manifest.deployment_mode %>
                  </span>
                </div>
              </div>

              <!-- Health Metrics -->
              <%= if module.metrics != %{} do %>
                <div class="bg-gray-900 rounded p-3 mb-4">
                  <h4 class="text-xs font-semibold text-gray-400 mb-2">Metrics</h4>
                  <div class="space-y-1 text-xs text-gray-300">
                    <%= for {key, value} <- module.metrics do %>
                      <div class="flex justify-between">
                        <span><%= key %>:</span>
                        <span class="font-mono"><%= value %></span>
                      </div>
                    <% end %>
                  </div>
                </div>
              <% end %>

              <!-- Error Message -->
              <%= if module.error_message do %>
                <div class="bg-red-900/20 border border-red-700 rounded p-3 mb-4">
                  <p class="text-xs text-red-300"><%= module.error_message %></p>
                </div>
              <% end %>

              <!-- Last Check -->
              <%= if module.last_health_check do %>
                <p class="text-xs text-gray-500 mb-4">
                  Last check: <%= format_time(module.last_health_check) %>
                </p>
              <% end %>

              <!-- Actions -->
              <button
                phx-click="check_health"
                phx-value-module={module.manifest.name}
                class="w-full px-4 py-2 bg-purple-600 hover:bg-purple-700 rounded text-sm font-semibold"
              >
                Check Health
              </button>
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  ## Helper Functions

  defp load_modules(:all) do
    ModuleRegistry.list_modules()
    |> Enum.sort_by(& &1.manifest.name)
  end

  defp load_modules(layer) do
    ModuleRegistry.list_modules_by_layer(layer)
    |> Enum.sort_by(& &1.manifest.name)
  end

  defp status_counts(modules) do
    modules
    |> Enum.group_by(& &1.status)
    |> Enum.map(fn {status, mods} -> {status, length(mods)} end)
    |> Enum.into(%{})
  end

  defp status_label(:not_deployed), do: "Not Deployed"
  defp status_label(:deploying), do: "Deploying"
  defp status_label(:healthy), do: "Healthy"
  defp status_label(:degraded), do: "Degraded"
  defp status_label(:failed), do: "Failed"

  defp status_color(:not_deployed), do: "text-gray-400"
  defp status_color(:deploying), do: "text-yellow-400"
  defp status_color(:healthy), do: "text-green-400"
  defp status_color(:degraded), do: "text-orange-400"
  defp status_color(:failed), do: "text-red-400"

  defp status_badge_class(:not_deployed), do: "bg-gray-700 text-gray-300"
  defp status_badge_class(:deploying), do: "bg-yellow-700 text-yellow-100"
  defp status_badge_class(:healthy), do: "bg-green-700 text-green-100"
  defp status_badge_class(:degraded), do: "bg-orange-700 text-orange-100"
  defp status_badge_class(:failed), do: "bg-red-700 text-red-100"

  defp layer_label(:access), do: "Access"
  defp layer_label(:overlay), do: "Overlay"
  defp layer_label(:storage), do: "Storage"
  defp layer_label(:network), do: "Network"
  defp layer_label(:naming), do: "Naming"
  defp layer_label(:backbone), do: "Backbone"
  defp layer_label(:platform), do: "Platform"
  defp layer_label(:observability), do: "Observability"
  defp layer_label(:mcp), do: "MCP"

  defp format_time(nil), do: "Never"

  defp format_time(datetime) do
    seconds_ago = DateTime.diff(DateTime.utc_now(), datetime)

    cond do
      seconds_ago < 60 -> "#{seconds_ago}s ago"
      seconds_ago < 3600 -> "#{div(seconds_ago, 60)}m ago"
      true -> "#{div(seconds_ago, 3600)}h ago"
    end
  end
end
