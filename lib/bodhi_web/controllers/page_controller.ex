defmodule BodhiWeb.PageController do
  use BodhiWeb, :controller

  @spec index(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def index(conn, _params) do
    page_description =
      ~s(Compassionate and supportive chat bot helping to cope with strong emotions in hard situations.)

    url = url(~p"/")

    conn
    |> assign(:url, url)
    |> assign(:page_description, page_description)
    |> assign(:bot_username, "compassion_lama_bot")
    |> render(:index)
  end
end
