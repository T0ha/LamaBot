defmodule BodhiWeb.ChatLive.Index do
  use BodhiWeb, :live_view

  alias Bodhi.Chats

  on_mount BodhiWeb.Plugs.Auth

  @impl true
  @spec mount(map(), map(), Phoenix.LiveView.Socket.t()) ::
          {:ok, Phoenix.LiveView.Socket.t()}
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :chats, Chats.list_chats())}
  end

  @impl true
  @spec handle_params(
          map(),
          String.t(),
          Phoenix.LiveView.Socket.t()
        ) :: {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Chat")
    |> assign(:chat, Chats.get_chat!(id))
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Chats")
    |> assign(:chat, nil)
  end
end
