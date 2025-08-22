defmodule Bodhi.Chats do
  @moduledoc """
  The Chats context.
  """

  import Ecto.Query, warn: false
  alias Bodhi.Repo

  alias Bodhi.Chats.Chat

  @doc """
  Returns the list of chats.

  ## Examples

      iex> list_chats()
      [%Chat{}, ...]

  """
  @spec list_chats() :: [Chat.t()]
  def list_chats do
    Chat
    |> Repo.all()
    |> Repo.preload(:messages)
  end

  @doc """
  Gets a single chat.

  Raises `Ecto.NoResultsError` if the Chat does not exist.

  ## Examples

      iex> get_chat!(123)
      %Chat{}

      iex> get_chat!(456)
      ** (Ecto.NoResultsError)

  """
  @spec get_chat!(non_neg_integer()) :: Chat.t()
  def get_chat!(id), do: Repo.get!(Chat, id)

  @doc """
  Creates a chat.

  ## Examples

      iex> create_chat(%{field: value})
      {:ok, %Chat{}}

      iex> create_chat(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec create_chat(map()) :: {:ok, Chat.t()} | {:error, Ecto.Changeset.t()}
  def create_chat(attrs \\ %{}) do
    %Chat{}
    |> Chat.changeset(attrs)
    |> Repo.insert()
  end

  @spec maybe_create_chat(Telegex.Type.Chat.t() | map()) ::
          {:ok, Chat.t()} | {:error, Ecto.Changeset.t()}
  def maybe_create_chat(%Telegex.Type.Chat{id: id} = attrs) do
    Chat
    |> Repo.get(id)
    |> case do
      nil ->
        create_chat(attrs)

      chat ->
        chat
        |> Chat.changeset(attrs)
        |> Repo.update()
    end
  end

  @doc """
  Updates a chat.

  ## Examples

      iex> update_chat(chat, %{field: new_value})
      {:ok, %Chat{}}

      iex> update_chat(chat, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec update_chat(Chat.t(), map()) :: {:ok, Chat.t()} | {:error, Ecto.Changeset.t()}
  def update_chat(%Chat{} = chat, attrs) do
    chat
    |> Chat.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a chat.

  ## Examples

      iex> delete_chat(chat)
      {:ok, %Chat{}}

      iex> delete_chat(chat)
      {:error, %Ecto.Changeset{}}

  """
  @spec delete_chat(Chat.t()) :: {:ok, Chat.t()} | {:error, Ecto.Changeset.t()}
  def delete_chat(%Chat{} = chat) do
    Repo.delete(chat)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking chat changes.

  ## Examples

      iex> change_chat(chat)
      %Ecto.Changeset{data: %Chat{}}

  """
  @spec change_chat(Chat.t(), map()) :: Ecto.Changeset.t()
  def change_chat(%Chat{} = chat, attrs \\ %{}) do
    Chat.changeset(chat, attrs)
  end

  alias Bodhi.Chats.Message

  @doc """
  Returns the list of messages.

  ## Examples

      iex> list_messages()
      [%Message{}, ...]

  """
  @spec list_messages() :: [Message.t()]
  def list_messages do
    Repo.all(Message)
  end

  @doc """
  Returns all messages for chat.

  ## Examples

      iex> get_chat_messages(%Chat{})
      [%Message{}, ...]

  """
  @spec get_chat_messages(Chat.t() | non_neg_integer()) :: [Message.t()]
  def get_chat_messages(%Chat{id: chat_id}), do: get_chat_messages(chat_id)

  def get_chat_messages(chat_id) do
    from(m in Message,
      where: m.chat_id == ^chat_id,
      order_by: [asc: m.inserted_at]
    )
    |> Repo.all()
  end

  @doc """
  Returns last message for chat.

  ## Examples

      iex> get_last_message(%Chat{})
      %Message{}

  """
  @spec get_last_message(Chat.t() | non_neg_integer()) :: Message.t()
  def get_last_message(%Chat{id: chat_id}), do: get_last_message(chat_id)

  def get_last_message(chat_id) do
    from(m in Message,
      where: m.chat_id == ^chat_id,
      order_by: [desc: m.inserted_at],
      limit: 1
    )
    |> Repo.one!()
  end

  @doc """
  Gets a single message.

  Raises `Ecto.NoResultsError` if the Message does not exist.

  ## Examples

      iex> get_message!(123)
      %Message{}

      iex> get_message!(456)
      ** (Ecto.NoResultsError)

  """
  @spec get_message!(non_neg_integer()) :: Message.t()
  def get_message!(id), do: Repo.get!(Message, id)

  @doc """
  Creates a message.

  ## Examples

      iex> create_message(%{field: value})
      {:ok, %Message{}}

      iex> create_message(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec create_message(map()) :: {:ok, Message.t()} | {:error, Ecto.Changeset.t()}
  def create_message(attrs \\ %{}) do
    %Message{}
    |> Message.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a message.

  ## Examples

      iex> update_message(message, %{field: new_value})
      {:ok, %Message{}}

      iex> update_message(message, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec update_message(Message.t(), map()) :: {:ok, Message.t()} | {:error, Ecto.Changeset.t()}
  def update_message(%Message{} = message, attrs) do
    message
    |> Message.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a message.

  ## Examples

      iex> delete_message(message)
      {:ok, %Message{}}

      iex> delete_message(message)
      {:error, %Ecto.Changeset{}}

  """
  @spec delete_message(Message.t()) :: {:ok, Message.t()} | {:error, Ecto.Changeset.t()}
  def delete_message(%Message{} = message) do
    Repo.delete(message)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking message changes.

  ## Examples

      iex> change_message(message)
      %Ecto.Changeset{data: %Message{}}

  """
  @spec change_message(Message.t(), map()) :: Ecto.Changeset.t()
  def change_message(%Message{} = message, attrs \\ %{}) do
    Message.changeset(message, attrs)
  end
end
