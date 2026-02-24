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

      <div class="flex items-center gap-4 my-4">
        <form
          id="filter-form"
          phx-change="filter"
          class="flex items-center gap-4"
        >
          <select name="active" class="select select-sm">
            <option
              value="all"
              selected={@params["active"] == "all"}
            >
              All
            </option>
            <option
              value="active"
              selected={@params["active"] == "active"}
            >
              Active
            </option>
            <option
              value="inactive"
              selected={@params["active"] == "inactive"}
            >
              Inactive
            </option>
          </select>
          <input
            type="search"
            name="search"
            value={@params["search"]}
            placeholder="Search name or model..."
            class="input input-sm"
            phx-debounce="300"
          />
        </form>
      </div>

      <div class="overflow-y-auto px-4 sm:overflow-visible sm:px-0">
        <table class="w-[40rem] mt-4 sm:w-full">
          <thead class="text-sm text-left leading-6 text-zinc-500">
            <tr>
              <.sort_header
                field="name"
                label="Name"
                params={@params}
              />
              <.sort_header
                field="model"
                label="Model"
                params={@params}
              />
              <.sort_header
                field="position"
                label="Position"
                params={@params}
              />
              <th class="p-0 pb-4 pr-6 font-normal">
                Temperature
              </th>
              <th class="p-0 pb-4 pr-6 font-normal">
                Max Tokens
              </th>
              <.sort_header
                field="active"
                label="Active"
                params={@params}
              />
              <th class="p-0 pb-4 font-normal">
                <span class="sr-only">Actions</span>
              </th>
            </tr>
          </thead>
          <tbody
            id="llm_configs"
            phx-update="stream"
            class={[
              "relative divide-y divide-zinc-100",
              "border-t border-zinc-200 text-sm",
              "leading-6 text-zinc-700"
            ]}
          >
            <tr
              :for={{id, cfg} <- @streams.llm_configs}
              id={id}
              class="group hover:bg-zinc-50"
            >
              <td class="p-0 relative">
                <div class="block py-4 pr-6">
                  <span class="font-semibold text-zinc-900">
                    {cfg.name}
                  </span>
                </div>
              </td>
              <td class="p-0">
                <div class="block py-4 pr-6">
                  {cfg.model}
                </div>
              </td>
              <td class="p-0">
                <div class="block py-4 pr-6">
                  {cfg.position}
                </div>
              </td>
              <td class="p-0">
                <div class="block py-4 pr-6">
                  {cfg.temperature || "—"}
                </div>
              </td>
              <td class="p-0">
                <div class="block py-4 pr-6">
                  {cfg.max_tokens || "—"}
                </div>
              </td>
              <td class="p-0">
                <div class="block py-4 pr-6">
                  <span class={[
                    "badge",
                    if(cfg.active,
                      do: "badge-success",
                      else: "badge-ghost"
                    )
                  ]}>
                    {if cfg.active,
                      do: "Active",
                      else: "Inactive"}
                  </span>
                </div>
              </td>
              <td class="p-0 w-0 font-semibold">
                <div class="flex gap-4 py-4">
                  <.link
                    navigate={~p"/llm-configs/#{cfg}/edit"}
                  >
                    Edit
                  </.link>
                  <.link
                    phx-click="toggle_active"
                    phx-value-id={cfg.id}
                  >
                    {if cfg.active,
                      do: "Deactivate",
                      else: "Activate"}
                  </.link>
                  <.link
                    phx-click={
                      JS.push("delete",
                        value: %{id: cfg.id}
                      )
                      |> hide("##{id}")
                    }
                    data-confirm="Are you sure?"
                  >
                    Delete
                  </.link>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </Layouts.admin>
    """
  end

  @default_params %{
    "active" => "all",
    "search" => "",
    "sort_by" => "position",
    "sort_dir" => "asc"
  }

  attr :field, :string, required: true
  attr :label, :string, required: true
  attr :params, :map, required: true

  defp sort_header(assigns) do
    ~H"""
    <th
      phx-click="sort"
      phx-value-field={@field}
      class="p-0 pb-4 pr-6 font-normal cursor-pointer"
    >
      {@label}
      <.icon
        :if={@params["sort_by"] == @field}
        name={
          if @params["sort_dir"] == "asc",
            do: "hero-chevron-up-mini",
            else: "hero-chevron-down-mini"
        }
        class="w-3 h-3 ml-1"
      />
    </th>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page, %{title: "LLM Configurations"})
     |> assign(:syncing, false)
     |> assign(:params, @default_params)
     |> apply_filters()}
  end

  @impl true
  def handle_event("filter", params, socket) do
    new_params =
      socket.assigns.params
      |> Map.merge(Map.take(params, ~w(active search)))

    {:noreply,
     socket
     |> assign(:params, new_params)
     |> apply_filters()}
  end

  def handle_event("sort", %{"field" => field}, socket) do
    params = socket.assigns.params

    dir =
      if params["sort_by"] == field && params["sort_dir"] == "asc",
        do: "desc",
        else: "asc"

    new_params =
      Map.merge(params, %{
        "sort_by" => field,
        "sort_dir" => dir
      })

    {:noreply,
     socket
     |> assign(:params, new_params)
     |> apply_filters()}
  end

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
      |> apply_filters()

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

    {:noreply, apply_filters(socket)}
  end

  def handle_event("toggle_active", %{"id" => id}, socket) do
    config = LlmConfigs.get_llm_config!(id)

    {:ok, _updated} =
      LlmConfigs.update_llm_config(config, %{
        active: !config.active
      })

    {:noreply, apply_filters(socket)}
  end

  defp apply_filters(socket) do
    configs =
      LlmConfigs.list_llm_configs(socket.assigns.params)

    stream(socket, :llm_configs, configs, reset: true)
  end
end
