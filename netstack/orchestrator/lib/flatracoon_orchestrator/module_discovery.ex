# SPDX-License-Identifier: PMPL-1.0-or-later
# FlatRacoon Orchestrator - Module Discovery
# Automatically discovers and registers modules from manifest files

defmodule FlatracoonOrchestrator.ModuleDiscovery do
  @moduledoc """
  Automatically discovers network stack modules by scanning manifest directories.

  Supports:
  - Scanning `/etc/flatracoon/modules.d/` for *.manifest.ncl files
  - Parsing and validating Nickel manifests
  - Dynamic module registration
  - Periodic rescanning for new modules
  """

  require Logger

  alias FlatracoonOrchestrator.ModuleRegistry

  @manifest_dirs [
    "/etc/flatracoon/modules.d",
    "../modules",
    "modules"
  ]

  @manifest_pattern "*.manifest.ncl"

  @doc """
  Discover and load all modules from manifest directories.

  Returns a map of module_name => module_state for all discovered modules.
  """
  @spec discover_modules() :: map()
  def discover_modules do
    Logger.info("Starting module discovery...")

    @manifest_dirs
    |> Enum.filter(&File.dir?/1)
    |> Enum.flat_map(&scan_directory/1)
    |> Enum.map(&parse_manifest/1)
    |> Enum.filter(&valid_manifest?/1)
    |> Enum.reduce(%{}, fn manifest, acc ->
      Map.put(acc, manifest.name, build_module_state(manifest))
    end)
    |> tap(fn modules ->
      Logger.info("Discovered #{map_size(modules)} modules")
    end)
  end

  @doc """
  Scan a directory for manifest files matching the pattern.

  Returns a list of file paths.
  """
  @spec scan_directory(String.t()) :: [String.t()]
  def scan_directory(dir_path) do
    pattern = Path.join(dir_path, @manifest_pattern)

    case Path.wildcard(pattern) do
      [] ->
        Logger.debug("No manifests found in #{dir_path}")
        []

      files ->
        Logger.info("Found #{length(files)} manifest(s) in #{dir_path}")
        files
    end
  end

  @doc """
  Parse a Nickel manifest file using the `nickel` CLI.

  Returns a parsed manifest map or {:error, reason}.
  """
  @spec parse_manifest(String.t()) :: map() | {:error, term()}
  def parse_manifest(file_path) do
    Logger.debug("Parsing manifest: #{file_path}")

    case System.cmd("nickel", ["export", file_path], stderr_to_stdout: true) do
      {output, 0} ->
        case Jason.decode(output) do
          {:ok, json} ->
            manifest = convert_manifest(json)
            Logger.info("✓ Parsed manifest: #{manifest.name}")
            manifest

          {:error, reason} ->
            Logger.error("Failed to decode JSON from #{file_path}: #{inspect(reason)}")
            {:error, :json_decode_failed}
        end

      {error_output, exit_code} ->
        Logger.error("Failed to parse #{file_path} (exit #{exit_code}): #{error_output}")
        {:error, :nickel_parse_failed}
    end
  end

  # Convert JSON manifest to internal manifest structure.
  # Handles type conversions (string layers to atoms, etc.)
  @spec convert_manifest(map()) :: map()
  defp convert_manifest(json) do
    %{
      name: Map.get(json, "name"),
      version: Map.get(json, "version", "0.1.0"),
      layer: String.to_existing_atom(Map.get(json, "layer", "platform")),
      repo: Map.get(json, "repo"),
      requires: Map.get(json, "requires", []),
      provides: Map.get(json, "provides", []),
      config_schema: Map.get(json, "config_schema"),
      health_endpoint: Map.get(json, "health_endpoint"),
      metrics_endpoint: Map.get(json, "metrics_endpoint"),
      deployment_mode: parse_deployment_mode(Map.get(json, "deployment_mode", "helm")),
      namespace: Map.get(json, "namespace", "default")
    }
  rescue
    ArgumentError ->
      # String.to_existing_atom failed - layer doesn't exist
      Logger.warning("Invalid layer in manifest: #{Map.get(json, "layer")}")
      %{
        name: Map.get(json, "name", "unknown"),
        version: Map.get(json, "version", "0.1.0"),
        layer: :platform,  # Default fallback
        repo: Map.get(json, "repo"),
        requires: Map.get(json, "requires", []),
        provides: Map.get(json, "provides", []),
        config_schema: nil,
        health_endpoint: nil,
        metrics_endpoint: nil,
        deployment_mode: :helm,
        namespace: Map.get(json, "namespace", "default")
      }
  end

  # Parse deployment mode string to atom.
  @spec parse_deployment_mode(String.t()) :: :helm | :kubectl | :daemonset | :statefulset
  defp parse_deployment_mode("helm"), do: :helm
  defp parse_deployment_mode("kubectl"), do: :kubectl
  defp parse_deployment_mode("daemonset"), do: :daemonset
  defp parse_deployment_mode("statefulset"), do: :statefulset
  defp parse_deployment_mode(_), do: :helm  # Default fallback

  # Validate that a manifest has all required fields.
  # Returns true if valid, false otherwise.
  @spec valid_manifest?(map() | {:error, term()}) :: boolean()
  defp valid_manifest?({:error, _reason}), do: false

  defp valid_manifest?(manifest) when is_map(manifest) do
    required_fields = [:name, :version, :layer, :repo, :deployment_mode, :namespace]

    Enum.all?(required_fields, fn field ->
      Map.has_key?(manifest, field) and not is_nil(Map.get(manifest, field))
    end)
  end

  # Build a complete module_state map from a parsed manifest.
  # Adds default values for status, health checks, etc.
  @spec build_module_state(map()) :: map()
  defp build_module_state(manifest) do
    %{
      manifest: manifest,
      status: :not_deployed,
      last_health_check: nil,
      error_message: nil,
      metrics: %{}
    }
  end

  @doc """
  Create fallback hardcoded modules if discovery fails or finds nothing.

  This ensures the orchestrator can start even without manifest files.
  """
  @spec fallback_modules() :: map()
  def fallback_modules do
    Logger.warning("Using fallback hardcoded module definitions")

    %{
      "twingate-helm-deploy" => %{
        manifest: %{
          name: "twingate-helm-deploy",
          version: "0.1.0",
          layer: :access,
          repo: "https://github.com/hyperpolymath/twingate-helm-deploy",
          requires: [],
          provides: ["secure-access", "zero-trust-network"],
          config_schema: "configs/production.ncl",
          health_endpoint: nil,
          metrics_endpoint: nil,
          deployment_mode: :helm,
          namespace: "twingate-system"
        },
        status: :not_deployed,
        last_health_check: nil,
        error_message: nil,
        metrics: %{}
      },
      "zerotier-k8s-link" => %{
        manifest: %{
          name: "zerotier-k8s-link",
          version: "0.1.0",
          layer: :overlay,
          repo: "https://github.com/hyperpolymath/zerotier-k8s-link",
          requires: [],
          provides: ["overlay-network", "encrypted-mesh"],
          config_schema: "configs/network.ncl",
          health_endpoint: nil,
          metrics_endpoint: nil,
          deployment_mode: :daemonset,
          namespace: "zerotier-system"
        },
        status: :not_deployed,
        last_health_check: nil,
        error_message: nil,
        metrics: %{}
      },
      "ipfs-overlay" => %{
        manifest: %{
          name: "ipfs-overlay",
          version: "0.1.0",
          layer: :storage,
          repo: "https://github.com/hyperpolymath/ipfs-overlay",
          requires: ["zerotier-k8s-link"],
          provides: ["distributed-storage", "ipfs-cluster"],
          config_schema: "configs/ipfs.ncl",
          health_endpoint: nil,
          metrics_endpoint: nil,
          deployment_mode: :statefulset,
          namespace: "ipfs-system"
        },
        status: :not_deployed,
        last_health_check: nil,
        error_message: nil,
        metrics: %{}
      }
    }
  end
end
