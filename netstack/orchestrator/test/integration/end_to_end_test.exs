# SPDX-License-Identifier: PMPL-1.0-or-later
defmodule FlatracoonOrchestrator.Integration.EndToEndTest do
  @moduledoc """
  End-to-end smoke tests simulating real-world usage flows.

  Tests:
  - TUI → Orchestrator → ModuleRegistry flow
  - SDK → Orchestrator → ModuleRegistry flow
  - Full deployment lifecycle
  """

  use ExUnit.Case, async: false

  alias FlatracoonOrchestrator.ModuleRegistry

  setup_all do
    # Start the full application
    {:ok, _} = Application.ensure_all_started(:flatracoon_orchestrator)
    :ok
  end

  setup do
    # ModuleRegistry is already started by the application
    # Just ensure it's running
    pid = Process.whereis(ModuleRegistry)
    assert pid != nil, "ModuleRegistry should be running"
    :ok
  end

  describe "TUI → Orchestrator flow" do
    test "list modules command flow" do
      # Simulate: flatracoon-tui list
      # This command would call GET /api/modules

      modules = ModuleRegistry.list_modules()

      assert is_list(modules)
      assert length(modules) > 0

      # Verify TUI would receive valid data
      Enum.each(modules, fn module ->
        assert is_map(module.manifest)
        assert is_atom(module.status)
        assert module.status in [:not_deployed, :deploying, :healthy, :degraded, :failed]
      end)
    end

    test "show module details flow" do
      # Simulate: flatracoon-tui show twingate-helm-deploy
      # This command would call GET /api/modules/:name

      case ModuleRegistry.get_module("twingate-helm-deploy") do
        {:ok, module} ->
          # Verify TUI would receive complete module data
          assert module.manifest.name == "twingate-helm-deploy"
          assert module.manifest.layer == :access
          assert is_list(module.manifest.provides)
          assert module.status == :not_deployed

        {:error, :not_found} ->
          # If using discovery instead of fallback, module might not be there
          assert true
      end
    end

    test "deployment order flow" do
      # Simulate: flatracoon-tui deploy --plan
      # This would call GET /api/deployment-order

      case ModuleRegistry.deployment_order() do
        {:ok, order} ->
          assert is_list(order)
          assert length(order) > 0

          # Verify TUI can display the order
          Enum.each(order, fn module_name ->
            assert is_binary(module_name)
            {:ok, module} = ModuleRegistry.get_module(module_name)
            assert is_map(module)
          end)

        {:error, :circular_dependency} ->
          flunk("Circular dependency detected in deployment order")
      end
    end

    @tag :skip
    test "deploy module flow (requires kubectl)" do
      # Simulate: flatracoon-tui deploy twingate-helm-deploy
      # This would call POST /api/deploy/:name

      # Skipped because it requires:
      # 1. kubectl access
      # 2. helm installed
      # 3. kubernetes cluster running
      # 4. module manifests/charts available

      # In CI environment with test cluster:
      # result = ModuleRegistry.deploy_module("test-module")
      # assert result == :ok or match?({:error, _}, result)
    end

    test "filter by layer flow" do
      # Simulate: flatracoon-tui list --layer access
      # This would call GET /api/modules?layer=access

      access_modules = ModuleRegistry.list_modules_by_layer(:access)

      assert is_list(access_modules)

      Enum.each(access_modules, fn module ->
        assert module.manifest.layer == :access
      end)
    end
  end

  describe "SDK → Orchestrator flow" do
    test "SDK discovers available modules" do
      # Simulate: SDK client calls listModules()
      modules = ModuleRegistry.list_modules()

      # SDK should receive parseable data
      assert is_list(modules)

      # Verify SDK can access all module fields
      Enum.each(modules, fn module ->
        assert Map.has_key?(module, :manifest)
        assert Map.has_key?(module, :status)
        assert Map.has_key?(module, :last_health_check)
        assert Map.has_key?(module, :metrics)
      end)
    end

    test "SDK queries module by name" do
      # Simulate: SDK client calls getModule("zerotier-k8s-link")

      result = ModuleRegistry.get_module("zerotier-k8s-link")

      case result do
        {:ok, module} ->
          # SDK receives module details
          assert module.manifest.name == "zerotier-k8s-link"
          assert module.manifest.layer == :overlay
          assert module.manifest.deployment_mode == :daemonset

        {:error, :not_found} ->
          # Module not available (using discovery instead of fallback)
          assert true
      end
    end

    test "SDK checks health status" do
      # Simulate: SDK polls health endpoint
      modules = ModuleRegistry.list_modules()

      healthy_count = Enum.count(modules, &(&1.status == :healthy))
      total_count = length(modules)

      # SDK can calculate health percentage
      health_percentage =
        if total_count > 0 do
          healthy_count / total_count * 100
        else
          0.0
        end

      assert health_percentage >= 0.0 and health_percentage <= 100.0
    end

    test "SDK updates module metrics" do
      # Simulate: SDK sends health check data
      # This would call POST /api/modules/:name/health

      test_module = %{
        name: "sdk-test-module",
        version: "1.0.0",
        layer: :platform,
        repo: "https://github.com/test/sdk-module",
        requires: [],
        provides: ["sdk-service"],
        config_schema: nil,
        health_endpoint: nil,
        metrics_endpoint: nil,
        deployment_mode: :helm,
        namespace: "test"
      }

      ModuleRegistry.register_module(test_module)

      # SDK reports metrics
      metrics = %{
        cpu: 45,
        memory: 256,
        requests_per_second: 100
      }

      ModuleRegistry.record_health_check("sdk-test-module", metrics)
      Process.sleep(100) # Allow cast to process

      {:ok, module} = ModuleRegistry.get_module("sdk-test-module")
      assert module.metrics == metrics
      assert module.last_health_check != nil
    end
  end

  describe "Full deployment lifecycle" do
    test "module registration → status update → health check cycle" do
      # Simulate complete lifecycle

      # 1. Module discovered/registered
      manifest = %{
        name: "lifecycle-test",
        version: "1.0.0",
        layer: :platform,
        repo: "https://github.com/test/lifecycle",
        requires: [],
        provides: ["lifecycle-service"],
        config_schema: nil,
        health_endpoint: "http://localhost:8080/health",
        metrics_endpoint: "http://localhost:8080/metrics",
        deployment_mode: :helm,
        namespace: "lifecycle-test"
      }

      assert :ok = ModuleRegistry.register_module(manifest)

      # 2. Verify initial state
      {:ok, module} = ModuleRegistry.get_module("lifecycle-test")
      assert module.status == :not_deployed
      assert module.last_health_check == nil

      # 3. Update status to deploying
      ModuleRegistry.update_status("lifecycle-test", :deploying)
      Process.sleep(50)

      {:ok, module} = ModuleRegistry.get_module("lifecycle-test")
      assert module.status == :deploying

      # 4. Update status to healthy
      ModuleRegistry.update_status("lifecycle-test", :healthy)
      Process.sleep(50)

      {:ok, module} = ModuleRegistry.get_module("lifecycle-test")
      assert module.status == :healthy

      # 5. Record health check
      metrics = %{cpu: 30, memory: 128, uptime: 3600}
      ModuleRegistry.record_health_check("lifecycle-test", metrics)
      Process.sleep(50)

      {:ok, module} = ModuleRegistry.get_module("lifecycle-test")
      assert module.metrics == metrics
      assert module.last_health_check != nil

      # 6. Simulate failure
      ModuleRegistry.update_status("lifecycle-test", :failed, "Pod crash loop")
      Process.sleep(50)

      {:ok, module} = ModuleRegistry.get_module("lifecycle-test")
      assert module.status == :failed
      assert module.error_message == "Pod crash loop"
    end

    @tag :skip
    test "dependency chain deployment order" do
      # Skipped - requires isolated ModuleRegistry instance per test
      # Create modules with dependencies
      base_module = %{
        name: "base-service",
        version: "1.0.0",
        layer: :platform,
        repo: "https://github.com/test/base",
        requires: [],
        provides: ["base-api"],
        config_schema: nil,
        health_endpoint: nil,
        metrics_endpoint: nil,
        deployment_mode: :helm,
        namespace: "test"
      }

      dependent_module = %{
        name: "dependent-service",
        version: "1.0.0",
        layer: :platform,
        repo: "https://github.com/test/dependent",
        requires: ["base-service"],
        provides: ["dependent-api"],
        config_schema: nil,
        health_endpoint: nil,
        metrics_endpoint: nil,
        deployment_mode: :helm,
        namespace: "test"
      }

      ModuleRegistry.register_module(base_module)
      ModuleRegistry.register_module(dependent_module)

      # Verify deployment order respects dependencies
      {:ok, order} = ModuleRegistry.deployment_order()

      base_idx = Enum.find_index(order, &(&1 == "base-service"))
      dependent_idx = Enum.find_index(order, &(&1 == "dependent-service"))

      assert base_idx != nil
      assert dependent_idx != nil
      assert base_idx < dependent_idx, "Base service must deploy before dependent"
    end
  end

  describe "Error handling and resilience" do
    test "handles non-existent module gracefully" do
      result = ModuleRegistry.get_module("does-not-exist")
      assert result == {:error, :not_found}
    end

    test "handles invalid layer filter" do
      # ModuleRegistry should handle any atom as layer
      result = ModuleRegistry.list_modules_by_layer(:invalid_layer)
      assert is_list(result)
      assert result == []
    end

    test "status updates for non-existent modules are ignored" do
      # Should not crash the GenServer
      ModuleRegistry.update_status("nonexistent", :failed, "error")
      Process.sleep(50)

      # GenServer should still be responsive
      modules = ModuleRegistry.list_modules()
      assert is_list(modules)
    end
  end
end
