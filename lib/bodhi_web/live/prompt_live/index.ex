defmodule BodhiWeb.PromptLive.Index do
  @moduledoc false
  use BodhiWeb, :live_view

  alias Bodhi.Prompts
  alias Bodhi.Prompts.Prompt

  on_mount BodhiWeb.Plugs.Auth

  @impl true
  @spec mount(map(), map(), Phoenix.LiveView.Socket.t()) ::
          {:ok, Phoenix.LiveView.Socket.t()}
  def mount(_params, _session, socket) do
    prompt =
      if connected?(socket),
        do: Prompts.get_or_create_context_prompt(),
        else: Prompts.get_latest_prompt() || %Prompt{text: ""}

    {:ok,
     socket
     |> assign(:page, %{title: "Context Prompt"})
     |> assign(:prompt, prompt)}
  end
end
