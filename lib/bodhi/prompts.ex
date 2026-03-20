defmodule Bodhi.Prompts do
  @moduledoc """
  The Prompts context.
  """

  import Ecto.Query, warn: false
  alias Bodhi.Repo

  require Logger

  alias Bodhi.Prompts.Prompt
  alias Bodhi.Prompts.PromptVersion

  @doc """
  Returns the list of prompts.

  ## Examples

      iex> list_prompts()
      [%Prompt{}, ...]

  """
  @spec list_prompts() :: [Prompt.t()]
  def list_prompts do
    Repo.all(Prompt)
  end

  @doc """
  Gets a single prompt.

  Raises `Ecto.NoResultsError` if the Prompt does not exist.

  ## Examples

      iex> get_prompt!(123)
      %Prompt{}

      iex> get_prompt!(456)
      ** (Ecto.NoResultsError)

  """
  @spec get_prompt!(non_neg_integer()) :: Prompt.t()
  def get_prompt!(id), do: Repo.get!(Prompt, id)

  @doc """
  Gets the latest context prompt.

  Raises `Ecto.NoResultsError` if no context prompt exists.

  ## Examples

      iex> get_latest_prompt!()
      %Prompt{}

      iex> get_latest_prompt!()
      ** (Ecto.NoResultsError)

  """
  @spec get_latest_prompt!() :: Prompt.t()
  def get_latest_prompt! do
    latest_context_query() |> Repo.one!()
  end

  @doc """
  Gets the latest context prompt,
  returning nil if none exists.

  ## Examples

      iex> get_latest_prompt()
      %Prompt{}

      iex> get_latest_prompt()
      nil

  """
  @spec get_latest_prompt() :: Prompt.t() | nil
  def get_latest_prompt do
    latest_context_query() |> Repo.one()
  end

  @doc """
  Gets the latest context prompt, creating a default
  empty one if none exists.

  ## Examples

      iex> get_or_create_context_prompt()
      %Prompt{type: :context}

  """
  @spec get_or_create_context_prompt() :: Prompt.t()
  def get_or_create_context_prompt do
    case get_latest_prompt() do
      %Prompt{} = prompt ->
        prompt

      nil ->
        create_default_context_prompt()
    end
  end

  defp create_default_context_prompt do
    attrs = %{
      text: "You are a helpful assistant.",
      type: :context,
      lang: "en",
      active: false
    }

    case create_prompt(attrs) do
      {:ok, prompt} ->
        prompt

      {:error, changeset} ->
        Logger.warning(
          "Failed to create default context prompt: " <>
            inspect(changeset.errors)
        )

        case get_latest_prompt() do
          %Prompt{} = prompt ->
            prompt

          nil ->
            raise "Failed to create default context prompt: " <>
                    inspect(changeset.errors)
        end
    end
  end

  defp latest_context_query do
    from(p in Prompt, where: p.type == :context)
  end

  @doc """
  Gets the latest start message prompt for the given language.

  Returns nil if no matching prompt exists.

  ## Examples

      iex> get_start_message("en")
      %Prompt{}

      iex> get_start_message("xx")
      nil

  """
  @spec get_start_message(String.t()) :: Prompt.t() | nil
  def get_start_message(lang \\ "en") do
    from(p in Prompt,
      where: p.type == :start_message and p.lang == ^lang,
      order_by: {:desc, p.inserted_at},
      limit: 1
    )
    |> Repo.one()
  end

  @doc """
  Gets a random single prompt by type and language.

  Raises `Ecto.NoResultsError` if the Prompt does not exist.

  ## Examples

      iex> get_random_prompt_by_type_and_lang(type, lang)
      %Prompt{}

      iex> get_random_prompt_by_type_and_lang(type)
      ** (Ecto.NoResultsError)

  """
  @spec get_random_prompt_by_type_and_lang(Prompt.type(), String.t()) :: Prompt.t()
  def get_random_prompt_by_type_and_lang(type, lang \\ "en") do
    from(p in Prompt,
      where: p.type == ^type and p.lang == ^lang,
      order_by: {:desc, p.inserted_at}
    )
    |> Repo.all()
    |> case do
      [] when lang != "en" ->
        get_random_prompt_by_type_and_lang(type)

      [] ->
        raise "Ecto.NoResultsError"

      prompts ->
        prompts
        |> Enum.shuffle()
        |> hd()
    end
  end

  @doc """
  Creates a prompt.

  ## Examples

      iex> create_prompt(%{field: value})
      {:ok, %Prompt{}}

      iex> create_prompt(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec create_prompt(map()) :: {:ok, Prompt.t()} | {:error, Ecto.Changeset.t()}
  def create_prompt(attrs \\ %{}) do
    %Prompt{}
    |> Prompt.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a prompt.

  ## Examples

      iex> update_prompt(prompt, %{field: new_value})
      {:ok, %Prompt{}}

      iex> update_prompt(prompt, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec update_prompt(Prompt.t(), map(), pos_integer() | nil) ::
          {:ok, Prompt.t()} | {:error, Ecto.Changeset.t()}
  def update_prompt(%Prompt{} = prompt, attrs, changed_by \\ nil) do
    prompt
    |> Prompt.changeset(attrs)
    |> maybe_put_changed_by(changed_by)
    |> Repo.update()
  end

  # Only set changed_by when there are actual content changes,
  # so unchanged saves don't defeat the trigger's
  # ignore_unchanged_values check.
  defp maybe_put_changed_by(changeset, nil), do: changeset

  defp maybe_put_changed_by(changeset, user_id) do
    if changeset.changes == %{} do
      changeset
    else
      Ecto.Changeset.put_change(
        changeset,
        :changed_by,
        user_id
      )
    end
  end

  @doc """
  Deletes a prompt.

  ## Examples

      iex> delete_prompt(prompt)
      {:ok, %Prompt{}}

      iex> delete_prompt(prompt)
      {:error, %Ecto.Changeset{}}

  """
  @spec delete_prompt(Prompt.t()) :: {:ok, Prompt.t()} | {:error, Ecto.Changeset.t()}
  def delete_prompt(%Prompt{} = prompt) do
    Repo.delete(prompt)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking prompt changes.

  ## Examples

      iex> change_prompt(prompt)
      %Ecto.Changeset{data: %Prompt{}}

  """
  @spec change_prompt(Prompt.t(), map()) :: Ecto.Changeset.t()
  def change_prompt(%Prompt{} = prompt, attrs \\ %{}) do
    Prompt.changeset(prompt, attrs)
  end

  @doc """
  Returns the version history for a prompt, ordered by
  version descending. Includes `valid_from` and `valid_to`
  timestamps extracted from `sys_period`.
  """
  @spec list_prompt_versions(pos_integer()) ::
          [PromptVersion.t()]
  def list_prompt_versions(prompt_id) do
    from(v in PromptVersion,
      where: v.id == ^prompt_id,
      order_by: [desc: v.version],
      select_merge: %{
        valid_from: fragment("lower(sys_period)"),
        valid_to: fragment("upper(sys_period)")
      }
    )
    |> Repo.all()
  end

  @doc """
  Gets a specific version of a prompt from history.

  Raises `Ecto.NoResultsError` if the version does not exist.
  """
  @spec get_prompt_version!(pos_integer(), pos_integer()) ::
          PromptVersion.t()
  def get_prompt_version!(prompt_id, version) do
    prompt_version_query(prompt_id, version)
    |> Repo.one!()
  end

  @doc """
  Gets a specific version of a prompt from history.

  Returns `nil` if the version does not exist.
  """
  @spec get_prompt_version(pos_integer(), pos_integer()) ::
          PromptVersion.t() | nil
  def get_prompt_version(prompt_id, version) do
    prompt_version_query(prompt_id, version)
    |> Repo.one()
  end

  defp prompt_version_query(prompt_id, version) do
    from(v in PromptVersion,
      where: v.id == ^prompt_id and v.version == ^version,
      select_merge: %{
        valid_from: fragment("lower(sys_period)"),
        valid_to: fragment("upper(sys_period)")
      }
    )
  end

  @doc """
  Restores a prompt to a previous version. This is
  append-only: a new version is created with the old
  text. Only the text field is restored.
  """
  @spec restore_prompt_version(
          Prompt.t(),
          pos_integer(),
          pos_integer()
        ) ::
          {:ok, Prompt.t()}
          | {:error, Ecto.Changeset.t()}
          | {:error, :version_not_found}
  def restore_prompt_version(
        %Prompt{} = prompt,
        version,
        user_id
      ) do
    case get_prompt_version(prompt.id, version) do
      nil ->
        {:error, :version_not_found}

      old ->
        update_prompt(prompt, %{text: old.text}, user_id)
    end
  end
end
