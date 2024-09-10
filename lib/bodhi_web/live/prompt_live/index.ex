defmodule BodhiWeb.PromptLive.Index do
  use BodhiWeb, :live_view

  alias Bodhi.Prompts
  alias Bodhi.Prompts.Prompt

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :prompts, list_prompts())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Prompt")
    |> assign(:prompt, Prompts.get_prompt!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Prompt")
    |> assign(:prompt, %Prompt{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Prompts")
    |> assign(:prompt, nil)
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    prompt = Prompts.get_prompt!(id)
    {:ok, _} = Prompts.delete_prompt(prompt)

    {:noreply, assign(socket, :prompts, list_prompts())}
  end

  defp list_prompts do
    Prompts.list_prompts()
  end
end
