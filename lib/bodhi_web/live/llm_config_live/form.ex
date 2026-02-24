defmodule BodhiWeb.LlmConfigLive.Form do
  @moduledoc false

  use BodhiWeb, :live_view

  alias Bodhi.LlmConfigs
  alias Bodhi.LlmConfigs.LlmConfig

  on_mount BodhiWeb.Plugs.Auth

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.admin flash={@flash}>
      <.header>
        {@page_title}
      </.header>

      <.form
        for={@form}
        id="llm-config-form"
        phx-change="validate"
        phx-submit="save"
      >
        <.input
          field={@form[:name]}
          type="text"
          label="Name"
        />
        <.input
          field={@form[:model]}
          type="text"
          label="Model"
        />
        <.input
          field={@form[:position]}
          type="number"
          label="Position"
        />
        <.input
          field={@form[:temperature]}
          type="number"
          label="Temperature"
          step="0.1"
        />
        <.input
          field={@form[:max_tokens]}
          type="number"
          label="Max Tokens"
        />
        <.input
          field={@form[:active]}
          type="checkbox"
          label="Active"
        />
        <footer>
          <.button phx-disable-with="Saving..." variant="primary">
            Save Config
          </.button>
          <.button navigate={~p"/llm-configs"}>
            Cancel
          </.button>
        </footer>
      </.form>
    </Layouts.admin>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    {:ok, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    config = LlmConfigs.get_llm_config!(id)

    socket
    |> assign(:page, %{title: "Edit LLM Config"})
    |> assign(:page_title, "Edit LLM Config")
    |> assign(:llm_config, config)
    |> assign(:form, to_form(LlmConfigs.change_llm_config(config)))
  end

  defp apply_action(socket, :new, _params) do
    config = %LlmConfig{}

    socket
    |> assign(:page, %{title: "New LLM Config"})
    |> assign(:page_title, "New LLM Config")
    |> assign(:llm_config, config)
    |> assign(:form, to_form(LlmConfigs.change_llm_config(config)))
  end

  @impl true
  def handle_event("validate", %{"llm_config" => params}, socket) do
    changeset =
      LlmConfigs.change_llm_config(
        socket.assigns.llm_config,
        params
      )

    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"llm_config" => params}, socket) do
    save_config(socket, socket.assigns.live_action, params)
  end

  defp save_config(socket, :edit, params) do
    case LlmConfigs.update_llm_config(
           socket.assigns.llm_config,
           params
         ) do
      {:ok, _config} ->
        {:noreply,
         socket
         |> put_flash(:info, "LLM config updated successfully")
         |> push_navigate(to: ~p"/llm-configs")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_config(socket, :new, params) do
    case LlmConfigs.create_llm_config(params) do
      {:ok, _config} ->
        {:noreply,
         socket
         |> put_flash(:info, "LLM config created successfully")
         |> push_navigate(to: ~p"/llm-configs")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end
end
