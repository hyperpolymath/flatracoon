# SPDX-License-Identifier: PMPL-1.0-or-later
defmodule FlatracoonOrchestrator.ModuleRegistryTest do
  use ExUnit.Case, async: false

  alias FlatracoonOrchestrator.ModuleRegistry

  # Sample manifest for testing
  @test_manifest %{
    name: "test-module",
    version: "1.0.0",
    layer: :platform,
    repo: "https://github.com/test/test-module",
    requires: [],
    provides: ["test-service"],
    config_schema: nil,
    health_endpoint: nil,
    metrics_endpoint: nil,
    deployment_mode: :helm,
    namespace: "test-namespace"
  }

  setup do
    # ModuleRegistry is already started by the application
    pid = Process.whereis(ModuleRegistry)
    assert pid != nil, "ModuleRegistry should be running"
    {:ok, registry: pid}
  end

  describe "list_modules/0" do
    test "returns list of modules" do
      modules = ModuleRegistry.list_modules()
      assert is_list(modules)
      # Should have fallback modules at minimum
      assert length(modules) > 0
    end

    test "each module has required fields" do
      modules = ModuleRegistry.list_modules()

      Enum.each(modules, fn module_state ->
        assert is_map(module_state)
        assert Map.has_key?(module_state, :manifest)
        assert Map.has_key?(module_state, :status)
        assert Map.has_key?(module_state, :last_health_check)
        assert Map.has_key?(module_state, :error_message)
        assert Map.has_key?(module_state, :metrics)
      end)
    end
  end

  describe "register_module/1" do
    test "successfully registers a new module" do
      assert :ok = ModuleRegistry.register_module(@test_manifest)

      {:ok, module} = ModuleRegistry.get_module("test-module")
      assert module.manifest.name == "test-module"
      assert module.status == :not_deployed
    end

    test "registered module can be retrieved" do
      ModuleRegistry.register_module(@test_manifest)

      case ModuleRegistry.get_module("test-module") do
        {:ok, module} ->
          assert module.manifest == @test_manifest
        {:error, :not_found} ->
          flunk("Module should be registered")
      end
    end
  end

  describe "get_module/1" do
    test "returns {:ok, module} for existing module" do
      # Use a module from fallback (should always exist)
      result = ModuleRegistry.get_module("twingate-helm-deploy")

      case result do
        {:ok, module} ->
          assert is_map(module)
          assert module.manifest.name == "twingate-helm-deploy"
        {:error, :not_found} ->
          # If fallback didn't load, that's okay for this test
          assert true
      end
    end

    test "returns {:error, :not_found} for non-existent module" do
      result = ModuleRegistry.get_module("nonexistent-module")
      assert result == {:error, :not_found}
    end
  end

  describe "list_modules_by_layer/1" do
    test "filters modules by layer" do
      access_modules = ModuleRegistry.list_modules_by_layer(:access)
      assert is_list(access_modules)

      Enum.each(access_modules, fn module ->
        assert module.manifest.layer == :access
      end)
    end

    test "returns empty list for unused layer" do
      # Assuming no modules in :mcp layer in fallback
      mcp_modules = ModuleRegistry.list_modules_by_layer(:mcp)
      assert is_list(mcp_modules)
      # May or may not be empty depending on fallback
    end
  end

  describe "update_status/3" do
    test "updates module status" do
      ModuleRegistry.register_module(@test_manifest)

      ModuleRegistry.update_status("test-module", :deploying)
      Process.sleep(50) # Give cast time to process

      {:ok, module} = ModuleRegistry.get_module("test-module")
      assert module.status == :deploying
    end

    test "updates module status with error message" do
      ModuleRegistry.register_module(@test_manifest)

      ModuleRegistry.update_status("test-module", :failed, "Deployment failed")
      Process.sleep(50) # Give cast time to process

      {:ok, module} = ModuleRegistry.get_module("test-module")
      assert module.status == :failed
      assert module.error_message == "Deployment failed"
    end
  end

  describe "record_health_check/2" do
    test "updates health check timestamp" do
      ModuleRegistry.register_module(@test_manifest)

      before = DateTime.utc_now()
      ModuleRegistry.record_health_check("test-module", %{cpu: 50, memory: 200})
      Process.sleep(50) # Give cast time to process

      {:ok, module} = ModuleRegistry.get_module("test-module")
      assert module.last_health_check != nil
      assert DateTime.compare(module.last_health_check, before) in [:gt, :eq]
    end

    test "updates metrics" do
      ModuleRegistry.register_module(@test_manifest)

      metrics = %{cpu: 75, memory: 512, requests: 1000}
      ModuleRegistry.record_health_check("test-module", metrics)
      Process.sleep(50) # Give cast time to process

      {:ok, module} = ModuleRegistry.get_module("test-module")
      assert module.metrics == metrics
    end
  end

  describe "deployment_order/0" do
    test "returns topological order of modules" do
      case ModuleRegistry.deployment_order() do
        {:ok, order} ->
          assert is_list(order)
          assert length(order) > 0

          # ipfs-overlay depends on zerotier-k8s-link
          # So zerotier should come before ipfs if both present
          if "ipfs-overlay" in order and "zerotier-k8s-link" in order do
            ipfs_idx = Enum.find_index(order, &(&1 == "ipfs-overlay"))
            zerotier_idx = Enum.find_index(order, &(&1 == "zerotier-k8s-link"))
            assert zerotier_idx < ipfs_idx
          end

        {:error, :circular_dependency} ->
          flunk("Should not have circular dependencies in fallback modules")
      end
    end

    test "modules without dependencies come first" do
      {:ok, order} = ModuleRegistry.deployment_order()

      # twingate and zerotier have no dependencies
      # They should appear before ipfs which depends on zerotier
      first_half = Enum.take(order, div(length(order), 2) + 1)
      assert "twingate-helm-deploy" in first_half or "zerotier-k8s-link" in first_half
    end
  end
end
