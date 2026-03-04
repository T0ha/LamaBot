defmodule BodhiWeb.PromptLive.Form do
  @moduledoc false
  use BodhiWeb, :live_view

  alias Bodhi.Prompts

  on_mount BodhiWeb.Plugs.Auth

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.admin flash={@flash}>
      <.header>
        {@page.title}
        <:subtitle>
          Edit the context prompt used for AI interactions.
        </:subtitle>
      </.header>

      <.form
        for={@form}
        id="prompt-form"
        phx-change="validate"
        phx-submit="save"
      >
        <.input
          field={@form[:text]}
          type="textarea"
          label="Prompt text"
        />
        <footer>
          <.button phx-disable-with="Saving..." variant="primary">
            Save Prompt
          </.button>
          <.button navigate={~p"/prompts"}>Cancel</.button>
        </footer>
      </.form>
    </Layouts.admin>
    """
  end

  @impl true
  @spec mount(map(), map(), Phoenix.LiveView.Socket.t()) ::
          {:ok, Phoenix.LiveView.Socket.t()}
  def mount(params, _session, socket) do
    {:ok, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    prompt = Prompts.get_prompt!(id)

    socket
    |> assign(:page, %{title: "Edit Prompt"})
    |> assign(:prompt, prompt)
    |> assign(:form, to_form(Prompts.change_prompt(prompt)))
  end

  @impl true
  @spec handle_event(
          String.t(),
          map(),
          Phoenix.LiveView.Socket.t()
        ) :: {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_event(
        "validate",
        %{"prompt" => prompt_params},
        socket
      ) do
    changeset =
      Prompts.change_prompt(
        socket.assigns.prompt,
        prompt_params
      )

    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event(
        "save",
        %{"prompt" => prompt_params},
        socket
      ) do
    case Prompts.update_prompt(
           socket.assigns.prompt,
           prompt_params
         ) do
      {:ok, _prompt} ->
        {:noreply,
         socket
         |> put_flash(:info, "Prompt updated successfully")
         |> push_navigate(to: ~p"/prompts")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end
end
