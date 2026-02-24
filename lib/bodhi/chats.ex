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

  alias Bodhi.Chats.LlmResponse
  alias Bodhi.Chats.Message
  alias Bodhi.Chats.Summary

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
  Returns all messages for chat with LLM response preloaded.

  Used by admin views that display AI model metadata.
  """
  @spec get_chat_messages_with_metadata(
          Chat.t() | non_neg_integer()
        ) :: [Message.t()]
  def get_chat_messages_with_metadata(%Chat{id: chat_id}),
    do: get_chat_messages_with_metadata(chat_id)

  def get_chat_messages_with_metadata(chat_id) do
    from(m in Message,
      where: m.chat_id == ^chat_id,
      order_by: [asc: m.inserted_at],
      preload: :llm_response
    )
    |> Repo.all()
  end

  @doc """
  Returns context for AI: summaries + recent messages.

  Assembles chat context by combining older summaries with recent messages
  from the last N days (default: 7). This reduces token usage for long conversations.

  ## Examples

      iex> get_chat_context_for_ai(123)
      [%Message{}, ...]

      iex> get_chat_context_for_ai(123, recent_days: 14)
      [%Message{}, ...]

  """
  @spec get_chat_context_for_ai(non_neg_integer(), keyword()) :: [Message.t()]
  def get_chat_context_for_ai(chat_id, opts \\ []) do
    default_days = summarization_config(:recent_days, 7)
    recent_days = Keyword.get(opts, :recent_days, default_days)
    cutoff_date = Date.utc_today() |> Date.add(-recent_days)

    recent_messages = get_recent_messages(chat_id, cutoff_date)

    case summarization_config(:enabled, false) do
      true ->
        summaries =
          get_summaries_before_date(chat_id, cutoff_date)

        build_context(summaries, recent_messages, chat_id)

      false ->
        recent_messages
    end
  end

  # Builds context by combining summaries and recent
  # messages. Summaries are wrapped as synthetic Message
  # structs with system user_id to distinguish them from
  # real user messages.
  # These structs are NOT persisted to the database.
  defp build_context(summaries, messages, chat_id) do
    system_uid = Bodhi.Chats.Summarizer.system_user_id()

    summary_messages =
      Enum.map(summaries, fn summary ->
        %Message{
          text:
            "Summary for #{summary.summary_date}: " <>
              "#{summary.summary_text} " <>
              "(#{summary.message_count} messages)",
          chat_id: chat_id,
          user_id: system_uid,
          inserted_at: summary.inserted_at
        }
      end)

    summary_messages ++ messages
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

  # LLM Response functions

  @doc """
  Creates an LLM response record.

  ## Examples

      iex> create_llm_response(%{ai_model: "gpt-4"})
      {:ok, %LlmResponse{}}

  """
  @spec create_llm_response(map()) ::
          {:ok, LlmResponse.t()}
          | {:error, Ecto.Changeset.t()}
  def create_llm_response(attrs) do
    %LlmResponse{}
    |> LlmResponse.changeset(attrs)
    |> Repo.insert()
  end

  # Summary functions

  @doc """
  Gets chat IDs that have messages on a specific date.

  ## Examples

      iex> get_active_chats_for_date(~D[2024-01-01])
      [123, 456]

  """
  @spec get_active_chats_for_date(Date.t()) :: [non_neg_integer()]
  def get_active_chats_for_date(date) do
    {start_dt, end_dt} = date_to_naive_range(date)

    from(m in Message,
      where:
        m.inserted_at >= ^start_dt and
          m.inserted_at < ^end_dt,
      distinct: m.chat_id,
      select: m.chat_id
    )
    |> Repo.all()
  end

  @doc """
  Gets all messages for a specific chat on a specific date.

  ## Examples

      iex> get_messages_for_date(123, ~D[2024-01-01])
      [%Message{}, ...]

  """
  @spec get_messages_for_date(non_neg_integer(), Date.t()) :: [Message.t()]
  def get_messages_for_date(chat_id, date) do
    {start_dt, end_dt} = date_to_naive_range(date)

    from(m in Message,
      where:
        m.chat_id == ^chat_id and
          m.inserted_at >= ^start_dt and
          m.inserted_at < ^end_dt,
      order_by: [asc: m.inserted_at]
    )
    |> Repo.all()
  end

  @doc """
  Gets recent messages for a chat after a cutoff date.

  ## Examples

      iex> get_recent_messages(123, ~D[2024-01-15])
      [%Message{}, ...]

  """
  @spec get_recent_messages(non_neg_integer(), Date.t()) :: [Message.t()]
  def get_recent_messages(chat_id, cutoff_date) do
    cutoff_datetime =
      cutoff_date
      |> DateTime.new!(~T[00:00:00], "Etc/UTC")
      |> DateTime.to_naive()

    from(m in Message,
      where: m.chat_id == ^chat_id and m.inserted_at >= ^cutoff_datetime,
      order_by: [asc: m.inserted_at]
    )
    |> Repo.all()
  end

  @doc """
  Gets summaries for a chat before a specific date.

  ## Examples

      iex> get_summaries_before_date(123, ~D[2024-01-15])
      [%Summary{}, ...]

  """
  @spec get_summaries_before_date(non_neg_integer(), Date.t()) :: [Summary.t()]
  def get_summaries_before_date(chat_id, cutoff_date) do
    from(s in Summary,
      where: s.chat_id == ^chat_id and s.summary_date < ^cutoff_date,
      order_by: [asc: s.summary_date]
    )
    |> Repo.all()
  end

  @doc """
  Gets a summary for a specific chat and date.

  ## Examples

      iex> get_summary(123, ~D[2024-01-01])
      %Summary{}

      iex> get_summary(123, ~D[2024-01-01])
      nil

  """
  @spec get_summary(non_neg_integer(), Date.t()) :: Summary.t() | nil
  def get_summary(chat_id, summary_date) do
    from(s in Summary,
      where: s.chat_id == ^chat_id and s.summary_date == ^summary_date,
      limit: 1
    )
    |> Repo.one()
  end

  @doc """
  Creates a summary.

  ## Examples

      iex> create_summary(%{chat_id: 123, summary_text: "...", summary_date: ~D[2024-01-01]})
      {:ok, %Summary{}}

      iex> create_summary(%{chat_id: nil})
      {:error, %Ecto.Changeset{}}

  """
  @spec create_summary(map()) ::
          {:ok, Summary.t()} | {:error, Ecto.Changeset.t()}
  def create_summary(attrs) do
    %Summary{}
    |> Summary.changeset(attrs)
    |> Repo.insert(
      on_conflict: :nothing,
      conflict_target: [:chat_id, :summary_date]
    )
  end

  defp summarization_config(key, default) do
    :bodhi
    |> Application.get_env(:summarization, [])
    |> Keyword.get(key, default)
  end

  defp date_to_naive_range(date) do
    start_dt =
      date
      |> DateTime.new!(~T[00:00:00], "Etc/UTC")
      |> DateTime.to_naive()

    end_dt =
      date
      |> Date.add(1)
      |> DateTime.new!(~T[00:00:00], "Etc/UTC")
      |> DateTime.to_naive()

    {start_dt, end_dt}
  end
end
