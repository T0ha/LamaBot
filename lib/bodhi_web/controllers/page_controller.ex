defmodule BodhiWeb.PageController do
  use BodhiWeb, :controller

  def index(conn, _params) do
    page_description = ~s(Compassionate and supportive chat bot helping to cope with strong emotions in hard situations.)
    url = Routes.page_url(conn, :index)
    conn
    |> assign(:url, url)
    |> assign(:page_description, page_description)
    |> assign(:bot_username, "compassion_lama_bot")
    |> render("index.html")
  end
end
