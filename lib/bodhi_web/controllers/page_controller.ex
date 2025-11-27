defmodule BodhiWeb.PageController do
  use BodhiWeb, :controller

  alias Bodhi.Pages

  plug :put_layout, html: {BodhiWeb.Layouts, :page}

  @spec index(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def index(conn, _params) do
    page(conn, %{"slug" => "index"})
  end

  @spec page(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def page(conn, %{"slug" => slug} = _params) do
    page = Pages.get_page_by_slug!(slug)
    {:ok, bot} = Bodhi.Telegram.get_me()

    url = url(~p"/")

    conn
    |> assign(:seo, true)
    |> assign(:url, url)
    |> assign(:page, page)
    |> assign(:bot, bot)
    |> put_format(:html)
    |> render(String.to_atom(page.template))
  end

  def list(conn, _params) do
    page =
      "list"
      |> Pages.get_page_by_slug!()

    pages = Pages.list_pages()
    {:ok, bot} = Bodhi.Telegram.get_me()
    url = url(~p"/")

    conn
    |> assign(:seo, true)
    |> assign(:pages, pages)
    |> assign(:page, page)
    |> assign(:url, url)
    |> assign(:bot, bot)
    |> put_format(:html)
    |> render("list")
  end
end
