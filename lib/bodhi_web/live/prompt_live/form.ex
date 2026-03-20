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
        <:actions :if={@versions != []}>
          <form
            id="version-select-form"
            phx-change="select_version"
          >
            <select
              id="version_select"
              name="version"
              class="select select-bordered select-sm"
            >
              <option
                value="current"
                selected={@selected_version == :current}
              >
                Current (v{@prompt.version})
              </option>
              <option
                :for={v <- @versions}
                value={v.version}
                selected={
                  @selected_version == v.version
                }
              >
                v{v.version} — {v.valid_from &&
                  Calendar.strftime(
                    v.valid_from,
                    "%Y-%m-%d %H:%M"
                  )}
              </option>
            </select>
          </form>
        </:actions>
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
          <.button
            phx-disable-with="Saving..."
            variant="primary"
          >
            {if @selected_version != :current,
              do: "Restore & Save",
              else: "Save Prompt"}
          </.button>
          <.button navigate={~p"/prompts"}>
            Cancel
          </.button>
        </footer>
      </.form>
    </Layouts.admin>
    """
  end

  @impl true
  @spec mount(map(), map(), Phoenix.LiveView.Socket.t()) ::
          {:ok, Phoenix.LiveView.Socket.t()}
  def mount(params, _session, socket) do
    {:ok,
     apply_action(
       socket,
       socket.assigns.live_action,
       params
     )}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    prompt = Prompts.get_prompt!(id)
    versions = Prompts.list_prompt_versions(prompt.id)

    socket
    |> assign(:page, %{title: "Edit Prompt"})
    |> assign(:prompt, prompt)
    |> assign(:versions, versions)
    |> assign(:selected_version, :current)
    |> assign(:form, to_form(Prompts.change_prompt(prompt)))
  end

  @impl true
  @spec handle_event(
          String.t(),
          map(),
          Phoenix.LiveView.Socket.t()
        ) :: {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_event(
        "select_version",
        %{"version" => "current"},
        socket
      ) do
    prompt = socket.assigns.prompt

    {:noreply,
     socket
     |> assign(:selected_version, :current)
     |> assign(
       :form,
       to_form(Prompts.change_prompt(prompt))
     )}
  end

  def handle_event(
        "select_version",
        %{"version" => version_str},
        socket
      ) do
    case Integer.parse(version_str) do
      {version, ""} ->
        prompt = socket.assigns.prompt

        old =
          Prompts.get_prompt_version!(
            prompt.id,
            version
          )

        changeset =
          Prompts.change_prompt(prompt, %{text: old.text})

        {:noreply,
         socket
         |> assign(:selected_version, version)
         |> assign(
           :form,
           to_form(changeset, action: :validate)
         )}

      _ ->
        {:noreply, socket}
    end
  end

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

    {:noreply,
     assign(
       socket,
       form: to_form(changeset, action: :validate)
     )}
  end

  def handle_event(
        "save",
        %{"prompt" => prompt_params},
        socket
      ) do
    case Prompts.update_prompt(
           socket.assigns.prompt,
           prompt_params,
           socket.assigns.current_user.id
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
