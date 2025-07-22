defmodule BodhiWeb.UserLiveTest do
  use BodhiWeb.ConnCase

  import Phoenix.LiveViewTest
  import Bodhi.Factory

  defp create_user(%{conn: conn}) do
    admin = insert(:user, is_admin: true)

    token = Phoenix.Token.sign(BodhiWeb.Endpoint, "user auth", admin.id)

    conn =
      conn
      |> Plug.Test.init_test_session(%{})
      |> put_session(:token, token)

    user = insert(:user)

    %{conn: conn, user: user, admin: admin}
  end

  describe "Index" do
    setup [:create_user]

    test "lists all users", %{conn: conn} do
      {:ok, _index_live, html} =
        live(conn, Routes.user_index_path(conn, :index))

      assert html =~ "Listing Users"
    end
  end
end
