defmodule BodhiWeb.LlmConfigLive.Index do
  @moduledoc false

  use BodhiWeb, :live_view

  alias Bodhi.LlmConfigs

  on_mount BodhiWeb.Plugs.Auth

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.admin flash={@flash}>
      <.header>
        LLM Configurations
        <:actions>
          <.button
            phx-click="sync_models"
            disabled={@syncing}
          >
            <.icon
              :if={@syncing}
              name="hero-arrow-path"
              class="animate-spin"
            />
            <.icon
              :if={!@syncing}
              name="hero-arrow-path"
            />
            {if @syncing, do: "Syncing...", else: "Sync Models"}
          </.button>
          <.button
            variant="primary"
            navigate={~p"/llm-configs/new"}
          >
            <.icon name="hero-plus" /> New Config
          </.button>
        </:actions>
      </.header>

      <.table
        id="llm_configs"
        rows={@streams.llm_configs}
      >
        <:col :let={{_id, cfg}} label="Name">
          {cfg.name}
        </:col>
        <:col :let={{_id, cfg}} label="Model">
          {cfg.model}
        </:col>
        <:col :let={{_id, cfg}} label="Position">
          {cfg.position}
        </:col>
        <:col :let={{_id, cfg}} label="Temperature">
          {cfg.temperature || "—"}
        </:col>
        <:col :let={{_id, cfg}} label="Max Tokens">
          {cfg.max_tokens || "—"}
        </:col>
        <:col :let={{_id, cfg}} label="Active">
          <span class={[
            "badge",
            if(cfg.active,
              do: "badge-success",
              else: "badge-ghost"
            )
          ]}>
            {if cfg.active, do: "Active", else: "Inactive"}
          </span>
        </:col>
        <:action :let={{_id, cfg}}>
          <.link navigate={~p"/llm-configs/#{cfg}/edit"}>
            Edit
          </.link>
        </:action>
        <:action :let={{_id, cfg}}>
          <.link
            phx-click="toggle_active"
            phx-value-id={cfg.id}
          >
            {if cfg.active,
              do: "Deactivate",
              else: "Activate"}
          </.link>
        </:action>
        <:action :let={{id, cfg}}>
          <.link
            phx-click={
              JS.push("delete", value: %{id: cfg.id})
              |> hide("##{id}")
            }
            data-confirm="Are you sure?"
          >
            Delete
          </.link>
        </:action>
      </.table>
    </Layouts.admin>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page, %{title: "LLM Configurations"})
     |> assign(:syncing, false)
     |> stream(
       :llm_configs,
       LlmConfigs.list_llm_configs()
     )}
  end

  @impl true
  def handle_event("sync_models", _params, socket) do
    socket = assign(socket, :syncing, true)

    result =
      case Bodhi.LLM.fetch_models() do
        {:ok, models} ->
          LlmConfigs.sync_models(models)

        {:error, reason} ->
          {:error, reason}
      end

    socket =
      socket
      |> assign(:syncing, false)
      |> stream(
        :llm_configs,
        LlmConfigs.list_llm_configs(),
        reset: true
      )

    socket =
      case result do
        {:ok, %{created: c, deactivated: d}} ->
          put_flash(
            socket,
            :info,
            "Sync complete: #{c} created," <>
              " #{d} deactivated"
          )

        {:error, reason} ->
          put_flash(
            socket,
            :error,
            "Sync failed: #{reason}"
          )
      end

    {:noreply, socket}
  end

  def handle_event("delete", %{"id" => id}, socket) do
    config = LlmConfigs.get_llm_config!(id)
    {:ok, _} = LlmConfigs.delete_llm_config(config)

    {:noreply, stream_delete(socket, :llm_configs, config)}
  end

  def handle_event("toggle_active", %{"id" => id}, socket) do
    config = LlmConfigs.get_llm_config!(id)

    {:ok, updated} =
      LlmConfigs.update_llm_config(config, %{
        active: !config.active
      })

    {:noreply, stream_insert(socket, :llm_configs, updated)}
  end
end
