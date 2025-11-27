defmodule BodhiWeb.ChatLive.Messages do
  use BodhiWeb, :live_view

  alias Bodhi.Chats
  alias Bodhi.Chats.Message

  on_mount BodhiWeb.Plugs.Auth

  @impl true
  @spec mount(map(), map(), Phoenix.LiveView.Socket.t()) ::
          {:ok, Phoenix.LiveView.Socket.t()}
  def mount(%{"chat_id" => chat_id} = _params, _session, socket) do
    {:ok, stream(socket, :messages, Chats.get_chat_messages(chat_id))}
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

  defp apply_action(socket, :index, %{"chat_id" => chat_id} = _params) do
    socket
    |> assign(:page, %{title: "Messages from Chat #{chat_id}"})
    |> assign(:chat_id, chat_id)
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

    {:noreply, assign(socket, :messages, Chats.list_messages())}
  end

  def from(chat_id, message) when is_binary(chat_id),
    do: from(String.to_integer(chat_id), message)

  def from(chat_id, %Message{user_id: user_id}) when chat_id == user_id, do: "User"
  def from(_chat_id, _message), do: "Bot"
end
