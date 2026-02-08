defmodule FlatracoonOrchestratorWeb.Router do
  use FlatracoonOrchestratorWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {FlatracoonOrchestratorWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", FlatracoonOrchestratorWeb do
    pipe_through :browser

    live "/", DashboardLive, :index
    get "/page", PageController, :home
  end

  # API routes for TUI and external clients
  scope "/api", FlatracoonOrchestratorWeb do
    pipe_through :api

    get "/modules", ApiController, :list_modules
    get "/modules/:name", ApiController, :get_module
    get "/health", ApiController, :health_summary
    get "/deployment_order", ApiController, :deployment_order
    post "/deploy", ApiController, :deploy_all
    post "/deploy/:name", ApiController, :deploy_module
    post "/restart/:name", ApiController, :restart_module
    post "/stop/:name", ApiController, :stop_module
    get "/logs/:name", ApiController, :get_logs
  end

  # Enable LiveDashboard in development
  if Application.compile_env(:flatracoon_orchestrator, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: FlatracoonOrchestratorWeb.Telemetry
    end
  end
end
