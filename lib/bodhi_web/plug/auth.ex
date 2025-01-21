defmodule BodhiWeb.Plugs.Auth do
  import Plug.Conn
  import Phoenix.Controller, only: [redirect: 2, put_flash: 3]


  alias Bodhi.Users
  alias Bodhi.Users.User

  def init(default), do: default

  def call(conn, _) do
    with token <- get_session(conn, "token"),
      {:ok, user_id} <- Phoenix.Token.verify(conn, "user auth", token, max_age: 86400),
      %User{is_admin: true} = user <- Users.get_user!(user_id) do

      conn
      |> assign(:user, user)
    else
      _ ->
        conn
        |> put_flash(:error, "You are not authorized to access this page!")
        |> redirect(to: "/")
    end
  end
end
