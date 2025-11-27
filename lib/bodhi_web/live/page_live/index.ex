defmodule BodhiWeb.PageLive.Index do
  use BodhiWeb, :live_view

  alias Bodhi.Pages

  on_mount BodhiWeb.Plugs.Auth

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.admin flash={@flash}>
      <.header>
        Listing Pages
        <:actions>
          <.button variant="primary" navigate={~p"/pages/new"}>
            <.icon name="hero-plus" /> New Page
          </.button>
        </:actions>
      </.header>

      <.table
        id="pages"
        rows={@streams.pages}
        row_click={fn {_id, page} -> JS.navigate(~p"/pages/#{page}") end}
      >
        <:col :let={{_id, page}} label="Slug">{page.slug}</:col>
        <:col :let={{_id, page}} label="Header">{page.header}</:col>
        <:col :let={{_id, page}} label="Title">{page.title}</:col>
        <:col :let={{_id, page}} label="Description">{page.description}</:col>
        <:col :let={{_id, page}} label="Format">{page.format}</:col>
        <:col :let={{_id, page}} label="Content">{page.content}</:col>
        <:action :let={{_id, page}}>
          <div class="sr-only">
            <.link navigate={~p"/pages/#{page}"}>Show</.link>
          </div>
          <.link navigate={~p"/pages/#{page}/edit"}>Edit</.link>
        </:action>
        <:action :let={{id, page}}>
          <.link
            phx-click={JS.push("delete", value: %{id: page.id}) |> hide("##{id}")}
            data-confirm="Are you sure?"
          >
            Delete
          </.link>
        </:action>
      </.table>
    </Layouts.admin>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page, %{title: "Listing Pages"})
     |> stream(:pages, Pages.list_pages())}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    page = Pages.get_page!(id)
    {:ok, _} = Pages.delete_page(page)

    {:noreply, stream_delete(socket, :pages, page)}
  end
end
