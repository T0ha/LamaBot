defmodule Bodhi.Prompts do
  @moduledoc """
  The Prompts context.
  """

  import Ecto.Query, warn: false
  alias Bodhi.Repo

  alias Bodhi.Prompts.Prompt

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
  Gets a single prompt.

  Raises `Ecto.NoResultsError` if the Prompt does not exist.

  ## Examples

      iex> get_latest_prompt!()
      %Prompt{}

      iex> get_latest_prompt!()
      ** (Ecto.NoResultsError)

  """
  @spec get_latest_prompt!() :: Prompt.t()
  def get_latest_prompt!() do
    from(p in Prompt,
      where: p.type == :context,
      order_by: {:desc, p.inserted_at},
      limit: 1
    )
    |> Repo.one!()
  end

  @doc """
  Gets a single prompt.

  Raises `Ecto.NoResultsError` if the Prompt does not exist.

  ## Examples

      iex> get_start_message(lang)
      {:ok, %Prompt{}}

      iex> get_start_message("")
  {:error

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
  @spec update_prompt(Prompt.t(), map()) :: {:ok, Prompt.t()} | {:error, Ecto.Changeset.t()}
  def update_prompt(%Prompt{} = prompt, attrs) do
    prompt
    |> Prompt.changeset(attrs)
    |> Repo.update()
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
end
