defmodule BodhiWeb.PageControllerTest do
  use BodhiWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "Talk to Lama Bot"
    assert html_response(conn, 200) =~ "Compassionate"
  end
end
