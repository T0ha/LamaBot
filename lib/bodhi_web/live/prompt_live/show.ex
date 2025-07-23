defmodule BodhiWeb.PromptLive.Show do
  use BodhiWeb, :live_view

  alias Bodhi.Prompts

  @impl true
  @spec mount(map(), map(), Phoenix.LiveView.Socket.t()) ::
          {:ok, Phoenix.LiveView.Socket.t()}
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  @spec handle_params(map(), String.t(), Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:prompt, Prompts.get_prompt!(id))}
  end

  defp page_title(:show), do: "Show Prompt"
  defp page_title(:edit), do: "Edit Prompt"
end
