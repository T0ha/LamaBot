defmodule Bodhi.Users do
  @moduledoc """
  The Users context.
  """

  import Ecto.Query, warn: false
  alias Bodhi.Repo

  alias Bodhi.Users.User

  @doc """
  Returns the list of users.

  ## Examples

      iex> list_users()
      [%User{}, ...]

  """
  @spec list_users() :: [User.t()]
  def list_users do
    Repo.all(User)
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  @spec get_user!(non_neg_integer()) :: User.t()
  def get_user!(id), do: Repo.get!(User, id)

  @spec get_by_chat!(chat_id :: non_neg_integer()) :: User.t()
  def get_by_chat!(chat_id) do
    from(u in User,
      # join: c in "chats", on: c.user_id == u.id,
      where: u.id == ^chat_id,
      select: u
    )
    |> Repo.one!()
  end

  @doc """
  Creates a user.

  ## Examples

      iex> create_user(%{field: value})
      {:ok, %User{}}

      iex> create_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec create_user(map()) :: {:ok, User.t()} | {:error, Ecto.Changeset.t()} | no_return()
  def create_user(attrs \\ %{}) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  @spec create_or_update_user(Telegex.Type.User.t() | map()) ::
          {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  def create_or_update_user(%Telegex.Type.User{id: id} = attrs) do
    User
    |> Repo.get(id)
    |> case do
      nil ->
        create_user(attrs)

      user ->
        user
        |> Repo.reload()
        |> User.changeset(attrs)
        |> Repo.update()
    end
  end

  @doc """
  Updates a user.

  ## Examples

      iex> update_user(user, %{field: new_value})
      {:ok, %User{}}

      iex> update_user(user, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec update_user(User.t(), map()) :: {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  def update_user(%User{} = user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a user.

  ## Examples

      iex> delete_user(user)
      {:ok, %User{}}

      iex> delete_user(user)
      {:error, %Ecto.Changeset{}}

  """
  @spec delete_user(User.t()) :: {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  def delete_user(%User{} = user) do
    Repo.delete(user)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.

  ## Examples

      iex> change_user(user)
      %Ecto.Changeset{data: %User{}}

  """
  @spec change_user(User.t(), map()) :: Ecto.Changeset.t()
  def change_user(%User{} = user, attrs \\ %{}) do
    User.changeset(user, attrs)
  end
end
