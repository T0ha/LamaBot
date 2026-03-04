defmodule BodhiWeb.PromptLive.Index do
  use BodhiWeb, :live_view

  alias Bodhi.Prompts

  on_mount BodhiWeb.Plugs.Auth

  @impl true
  @spec mount(map(), map(), Phoenix.LiveView.Socket.t()) ::
          {:ok, Phoenix.LiveView.Socket.t()}
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page, %{title: "Context Prompt"})
     |> assign(:prompt, Prompts.get_latest_prompt())}
  end
end
