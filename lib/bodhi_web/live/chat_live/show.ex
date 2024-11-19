defmodule BodhiWeb.ChatLive.Show do
  use BodhiWeb, :live_view

  alias Bodhi.Chats

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:chat, Chats.get_chat!(id))}
  end

  defp page_title(:show), do: "Show Chat"
  defp page_title(:edit), do: "Edit Chat"
end
