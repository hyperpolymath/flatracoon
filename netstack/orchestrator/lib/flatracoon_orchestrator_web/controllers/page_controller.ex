# SPDX-License-Identifier: MPL-2.0
# Copyright (c) Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
defmodule FlatracoonOrchestratorWeb.PageController do
  use FlatracoonOrchestratorWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
