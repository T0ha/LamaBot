defmodule BodhiWeb.Plugs.Auth do
  @moduledoc """
  Web authentication plug
  """
  import Plug.Conn
  import Phoenix.Controller, only: [redirect: 2, put_flash: 3]

  alias Bodhi.Users
  alias Bodhi.Users.User

  @spec init(any()) :: any()
  def init(default), do: default

  @spec call(Plug.Conn.t(), any()) :: Plug.Conn.t()
  def call(conn, _) do
    with token <- get_session(conn, "token"),
         {:ok, user_id} <- Phoenix.Token.verify(conn, "user auth", token, max_age: 86_400),
         %User{is_admin: true} = user <- Users.get_user!(user_id) do
      conn
      |> assign(:current_user, user)
      |> put_session(:current_user, user)
    else
      _ ->
        conn
        |> put_flash(:error, "You are not authorized to access this page!")
        |> redirect(to: "/")
        |> halt()
    end
  end

  def on_mount(:default, _params, %{"current_user" => user} = _session, socket) do
    socket =
      socket
      |> Phoenix.Component.assign(:current_user, user)
      |> Phoenix.Component.assign(:with_header?, true)

    {:cont, socket}
  end

  def on_mount(:default, _params, _session, socket), do: {:cont, socket}
end
