defmodule BodhiWeb.MessageLive.Index do
  use BodhiWeb, :live_view

  alias Bodhi.Chats
  alias Bodhi.Chats.Message

  on_mount BodhiWeb.Plugs.Auth

  @impl true
  @spec mount(map(), map(), Phoenix.LiveView.Socket.t()) ::
          {:ok, Phoenix.LiveView.Socket.t()}
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :messages, list_messages())}
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
    |> assign(:page_title, "Edit Message")
    |> assign(:message, Chats.get_message!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Message")
    |> assign(:message, %Message{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Messages")
    |> assign(:message, nil)
  end

  @impl true
  @spec handle_event(
          String.t(),
          map(),
          Phoenix.LiveView.Socket.t()
        ) :: {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_event("delete", %{"id" => id}, socket) do
    message = Chats.get_message!(id)
    {:ok, _} = Chats.delete_message(message)

    {:noreply, assign(socket, :messages, list_messages())}
  end

  defp list_messages do
    Chats.list_messages()
  end
end
