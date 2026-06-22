# SPDX-License-Identifier: MPL-2.0
# Copyright (c) Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
defmodule FlatracoonOrchestratorWeb.ErrorJSONTest do
  use FlatracoonOrchestratorWeb.ConnCase, async: true

  test "renders 404" do
    assert FlatracoonOrchestratorWeb.ErrorJSON.render("404.json", %{}) == %{errors: %{detail: "Not Found"}}
  end

  test "renders 500" do
    assert FlatracoonOrchestratorWeb.ErrorJSON.render("500.json", %{}) ==
             %{errors: %{detail: "Internal Server Error"}}
  end
end
