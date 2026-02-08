# SPDX-License-Identifier: PMPL-1.0-or-later
defmodule FlatracoonOrchestrator.Integration.OrchestratorApiTest do
  @moduledoc """
  Integration tests for the orchestrator API endpoints.
  Tests the full HTTP → Controller → ModuleRegistry flow.
  """

  use FlatracoonOrchestratorWeb.ConnCase, async: false

  alias FlatracoonOrchestrator.ModuleRegistry

  setup do
    # ModuleRegistry is already started by the application
    pid = Process.whereis(ModuleRegistry)
    assert pid != nil, "ModuleRegistry should be running"
    :ok
  end

  describe "GET /api/modules" do
    @tag :skip
    test "returns list of all modules", %{conn: conn} do
      # Skipped - route not yet implemented
      conn = get(conn, ~p"/api/modules")

      assert json_response(conn, 200)
      response = json_response(conn, 200)

      assert is_list(response["modules"])
      assert length(response["modules"]) > 0

      # Verify module structure
      first_module = hd(response["modules"])
      assert Map.has_key?(first_module, "name")
      assert Map.has_key?(first_module, "status")
      assert Map.has_key?(first_module, "layer")
    end

    @tag :skip
    test "modules have valid statuses", %{conn: conn} do
      # Skipped - route not yet implemented
      conn = get(conn, ~p"/api/modules")
      response = json_response(conn, 200)

      valid_statuses = ["not_deployed", "deploying", "healthy", "degraded", "failed"]

      Enum.each(response["modules"], fn module ->
        assert module["status"] in valid_statuses
      end)
    end
  end

  describe "GET /api/modules/:name" do
    @tag :skip
    test "returns specific module details", %{conn: conn} do
      # Skipped - route not yet implemented
      # Register a test module first
      manifest = %{
        name: "test-integration-module",
        version: "1.0.0",
        layer: :platform,
        repo: "https://github.com/test/module",
        requires: [],
        provides: ["test"],
        config_schema: nil,
        health_endpoint: nil,
        metrics_endpoint: nil,
        deployment_mode: :helm,
        namespace: "test"
      }

      ModuleRegistry.register_module(manifest)

      conn = get(conn, ~p"/api/modules/test-integration-module")
      response = json_response(conn, 200)

      assert response["name"] == "test-integration-module"
      assert response["version"] == "1.0.0"
      assert response["layer"] == "platform"
      assert response["status"] == "not_deployed"
    end

    @tag :skip
    test "returns 404 for non-existent module", %{conn: conn} do
      # Skipped - route not yet implemented
      conn = get(conn, ~p"/api/modules/nonexistent")
      assert json_response(conn, 404)
    end
  end

  describe "GET /api/modules?layer=:layer" do
    @tag :skip
    test "filters modules by layer", %{conn: conn} do
      # Skipped - route not yet implemented
      conn = get(conn, ~p"/api/modules?layer=access")
      response = json_response(conn, 200)

      assert is_list(response["modules"])

      # All returned modules should be in access layer
      Enum.each(response["modules"], fn module ->
        assert module["layer"] == "access"
      end)
    end
  end

  describe "POST /api/deploy/:name" do
    @tag :skip
    test "triggers module deployment", %{conn: conn} do
      # This test is skipped because it requires kubectl access
      # In a real integration test environment, you'd have a test k8s cluster

      manifest = %{
        name: "test-deploy-module",
        version: "1.0.0",
        layer: :platform,
        repo: "https://github.com/test/module",
        requires: [],
        provides: ["test"],
        config_schema: nil,
        health_endpoint: nil,
        metrics_endpoint: nil,
        deployment_mode: :helm,
        namespace: "test"
      }

      ModuleRegistry.register_module(manifest)

      conn = post(conn, ~p"/api/deploy/test-deploy-module")
      response = json_response(conn, 200)

      assert response["status"] == "deploying" or response["status"] == "failed"
      assert Map.has_key?(response, "message")
    end
  end

  describe "GET /api/deployment-order" do
    @tag :skip
    test "returns modules in deployment order", %{conn: conn} do
      # Skipped - route not yet implemented
      conn = get(conn, ~p"/api/deployment-order")
      response = json_response(conn, 200)

      assert is_list(response["order"])
      assert length(response["order"]) > 0

      # Verify ordering: dependencies come before dependents
      order = response["order"]

      if "ipfs-overlay" in order and "zerotier-k8s-link" in order do
        ipfs_idx = Enum.find_index(order, &(&1 == "ipfs-overlay"))
        zerotier_idx = Enum.find_index(order, &(&1 == "zerotier-k8s-link"))
        assert zerotier_idx < ipfs_idx, "zerotier should be deployed before ipfs"
      end
    end
  end

  describe "GET /api/health" do
    @tag :skip
    test "returns overall system health", %{conn: conn} do
      # Skipped - route not yet implemented
      conn = get(conn, ~p"/api/health")
      response = json_response(conn, 200)

      assert Map.has_key?(response, "status")
      assert response["status"] in ["healthy", "degraded", "unhealthy"]
      assert Map.has_key?(response, "modules")
      assert is_integer(response["total_modules"])
    end
  end

  describe "GET /api/modules/:name/logs" do
    @tag :skip
    test "retrieves module logs", %{conn: conn} do
      # Skipped - requires actual deployed module
      conn = get(conn, ~p"/api/modules/test-module/logs?lines=50")
      # Would assert on log content
    end
  end
end
