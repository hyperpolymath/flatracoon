defmodule FlatracoonOrchestratorWeb.PageController do
  use FlatracoonOrchestratorWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
