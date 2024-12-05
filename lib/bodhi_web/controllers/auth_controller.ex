defmodule BodhiWeb.AuthController do
  use BodhiWeb, :controller
  alias Bodhi.Users
  alias Bodhi.Users.User

  def login(conn, %{"token" => token}) do
    with {:ok, user_id} <- Phoenix.Token.verify(conn, "user auth", token, max_age: 86400),
      %User{is_admin: true}  = user <- Users.get_user!(user_id) do

      conn
      |> assign(:current_user, user)
      |> redirect(to: "/users")
    else
      _ ->
        text(conn, "401")
    end
  end
end
