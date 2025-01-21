defmodule BodhiWeb.AuthController do
  use BodhiWeb, :controller
  alias Bodhi.Users
  alias Bodhi.Users.User

  def login(conn, %{"token" => token}) do
    with {:ok, user_id} <- Phoenix.Token.verify(conn, "user auth", token, max_age: 86400),
      %User{is_admin: true}  = user <- Users.get_user!(user_id) do

      conn
      |> put_session(:token, token)
      |> assign(:user, user)
      |> redirect(to: "/users")
    else
      _ ->
        conn
        |> put_flash(:error, "You are not authorized to access this page!")
        |> redirect(to: "/")
    end
  end


  def logout(conn, _params) do
    conn
    |> clear_session()
    |> redirect(to: "/")
  end
end
