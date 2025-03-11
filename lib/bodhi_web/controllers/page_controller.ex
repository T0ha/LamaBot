defmodule BodhiWeb.PageController do
  use BodhiWeb, :controller

  def index(conn, _params) do
    conn
    |> assign(:bot_username, "compassion_lama_bot")
    |> render("index.html")
  end
end
