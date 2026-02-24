defmodule Bodhi.LlmConfigs do
  @moduledoc """
  Context for managing LLM model configurations.

  Provides CRUD operations for LLM configs stored in the
  database and caches active configurations via Nebulex.
  """

  import Ecto.Query, warn: false

  alias Bodhi.Cache
  alias Bodhi.Repo
  alias Bodhi.LlmConfigs.LlmConfig

  @cache_key :active_llm_configs

  @allowed_sort_fields ~w(name model position active)a

  @doc """
  Returns LLM configs filtered and sorted by params.

  Supported params (all optional, string keys):
  - `"active"` — `"active"`, `"inactive"`, or `"all"`
  - `"search"` — partial match on name or model
  - `"sort_by"` — column name (name/model/position/active)
  - `"sort_dir"` — `"asc"` or `"desc"`

  Defaults to all configs ordered by position ascending.
  """
  @spec list_llm_configs(map()) :: [LlmConfig.t()]
  def list_llm_configs(params \\ %{}) do
    LlmConfig
    |> filter_by_active(params)
    |> filter_by_search(params)
    |> sort_by(params)
    |> Repo.all()
  end

  @doc """
  Gets a single LLM config.

  Raises `Ecto.NoResultsError` if not found.
  """
  @spec get_llm_config!(non_neg_integer()) :: LlmConfig.t()
  def get_llm_config!(id), do: Repo.get!(LlmConfig, id)

  @doc """
  Returns all active configs ordered by position.
  """
  @spec get_active_configs() :: [LlmConfig.t()]
  def get_active_configs do
    LlmConfig
    |> where(active: true)
    |> order_by(:position)
    |> Repo.all()
  end

  @doc """
  Creates an LLM config.
  """
  @spec create_llm_config(map()) ::
          {:ok, LlmConfig.t()} | {:error, Ecto.Changeset.t()}
  def create_llm_config(attrs) do
    result =
      %LlmConfig{}
      |> LlmConfig.changeset(attrs)
      |> Repo.insert()

    maybe_invalidate_cache(result, attrs)
    result
  end

  @doc """
  Updates an LLM config.
  """
  @spec update_llm_config(LlmConfig.t(), map()) ::
          {:ok, LlmConfig.t()} | {:error, Ecto.Changeset.t()}
  def update_llm_config(%LlmConfig{} = config, attrs) do
    result =
      config
      |> LlmConfig.changeset(attrs)
      |> Repo.update()

    with {:ok, _} <- result do
      if config.active || touches_active?(attrs) do
        invalidate_cache()
      end
    end

    result
  end

  @doc """
  Deletes an LLM config.
  """
  @spec delete_llm_config(LlmConfig.t()) ::
          {:ok, LlmConfig.t()} | {:error, Ecto.Changeset.t()}
  def delete_llm_config(%LlmConfig{} = config) do
    result = Repo.delete(config)

    with {:ok, deleted} <- result do
      if deleted.active, do: invalidate_cache()
    end

    result
  end

  @doc """
  Returns a changeset for tracking LLM config changes.
  """
  @spec change_llm_config(LlmConfig.t(), map()) ::
          Ecto.Changeset.t()
  def change_llm_config(%LlmConfig{} = config, attrs \\ %{}) do
    LlmConfig.changeset(config, attrs)
  end

  @doc """
  Syncs remote models into the database.

  - New models (not in DB): created as inactive
  - Existing models (matched by `model`): untouched
  - Stale models (in DB, not in remote): set `active: false`

  Returns `{:ok, %{created: N, deactivated: N}}`.
  """
  @spec sync_models([map()]) ::
          {:ok, %{created: non_neg_integer(), deactivated: non_neg_integer()}}
  def sync_models(remote_models) do
    remote_ids =
      MapSet.new(remote_models, & &1["id"])

    remote_by_id =
      Map.new(remote_models, &{&1["id"], &1})

    existing =
      LlmConfig
      |> select([c], {c.model, c.id})
      |> Repo.all()

    existing_ids = MapSet.new(existing, &elem(&1, 0))

    new_ids = MapSet.difference(remote_ids, existing_ids)
    stale_ids = MapSet.difference(existing_ids, remote_ids)

    created = create_new_models(new_ids, remote_by_id)

    {deactivated, _} =
      LlmConfig
      |> where([c], c.model in ^MapSet.to_list(stale_ids))
      |> where([c], c.active == true)
      |> Repo.update_all(set: [active: false])

    invalidate_cache()

    {:ok, %{created: created, deactivated: deactivated}}
  end

  defp create_new_models(new_ids, remote_by_id) do
    existing_names =
      LlmConfig
      |> select([c], c.name)
      |> Repo.all()
      |> MapSet.new()

    new_ids
    |> Enum.reduce({0, existing_names}, fn id, {count, names} ->
      model_data = Map.get(remote_by_id, id)
      name = model_data["name"] || id

      {final_name, names} =
        if MapSet.member?(names, name) do
          {id, MapSet.put(names, id)}
        else
          {name, MapSet.put(names, name)}
        end

      next_position = next_position()

      attrs = %{
        name: final_name,
        model: id,
        position: next_position,
        active: false
      }

      case create_llm_config(attrs) do
        {:ok, _} -> {count + 1, names}
        {:error, _} -> {count, names}
      end
    end)
    |> elem(0)
  end

  defp next_position do
    LlmConfig
    |> select([c], max(c.position))
    |> Repo.one()
    |> case do
      nil -> 0
      max -> max + 1
    end
  end

  @doc false
  @spec invalidate_cache() :: :ok
  def invalidate_cache do
    Cache.delete(@cache_key)
    :ok
  end

  defp filter_by_active(query, %{"active" => "active"}),
    do: where(query, active: true)

  defp filter_by_active(query, %{"active" => "inactive"}),
    do: where(query, active: false)

  defp filter_by_active(query, _params), do: query

  defp filter_by_search(query, %{"search" => s})
       when s != "" do
    term = "%#{s}%"

    where(
      query,
      [c],
      ilike(c.name, ^term) or ilike(c.model, ^term)
    )
  end

  defp filter_by_search(query, _params), do: query

  defp sort_by(query, %{
         "sort_by" => field,
         "sort_dir" => dir
       }) do
    field = safe_sort_field(field)
    dir = if dir == "desc", do: :desc, else: :asc
    order_by(query, [{^dir, ^field}])
  end

  defp sort_by(query, _params),
    do: order_by(query, :position)

  defp safe_sort_field(field) do
    field
    |> String.to_existing_atom()
    |> then(fn atom ->
      if atom in @allowed_sort_fields, do: atom, else: :position
    end)
  rescue
    ArgumentError -> :position
  end

  defp maybe_invalidate_cache({:ok, _}, attrs) do
    if touches_active?(attrs), do: invalidate_cache()
  end

  defp maybe_invalidate_cache(_, _), do: :ok

  defp touches_active?(attrs) do
    active =
      Map.get(attrs, :active) || Map.get(attrs, "active")

    active == true
  end
end
