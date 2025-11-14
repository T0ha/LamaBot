defmodule BodhiWeb.PageLive.Show do
  use BodhiWeb, :live_view

  alias Bodhi.Pages

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.admin flash={@flash}>
      <.header>
        Page {@page.id}
        <:subtitle>This is a page record from your database.</:subtitle>
        <:actions>
          <.button navigate={~p"/pages"}>
            <.icon name="hero-arrow-left" />
          </.button>
          <.button variant="primary" navigate={~p"/pages/#{@page}/edit?return_to=show"}>
            <.icon name="hero-pencil-square" /> Edit page
          </.button>
        </:actions>
      </.header>

      <.list>
        <:item title="Slug">{@page.slug}</:item>
        <:item title="Header">{@page.header}</:item>
        <:item title="Title">{@page.title}</:item>
        <:item title="Description">{@page.description}</:item>
        <:item title="Format">{@page.format}</:item>
        <:item title="Content">{@page.content}</:item>
      </.list>
    </Layouts.admin>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    {:ok,
     socket
     |> assign(:page, %{title: "Show Page"})
     |> assign(:page, Pages.get_page!(id))}
  end
end
