defmodule Bodhi.Chats.Summarizer do
  @moduledoc """
  Shared summarization logic used by both the daily worker
  and the release backfill tool.
  """

  require Logger

  alias Bodhi.Chats
  alias Bodhi.Chats.Message

  @system_user_id -1
  @system_chat_id -1

  @summarization_prompt """
  Summarize the following conversation concisely. \
  Capture key topics, questions, decisions, \
  and emotional tone. Keep it under 200 words. \
  Focus on what matters for future context.\
  """

  @doc """
  Generates a summary for the given messages and stores it.

  Calls the AI backend to summarize, then persists the
  result via `Chats.create_summary/1`.

  Returns `:ok` on success, `{:error, reason}` on failure.
  """
  @spec generate_and_store(
          non_neg_integer(),
          Date.t(),
          [Message.t()]
        ) :: :ok | {:error, String.t() | Ecto.Changeset.t()}
  def generate_and_store(_chat_id, _date, []) do
    {:error, "Cannot summarize empty messages"}
  end

  def generate_and_store(chat_id, date, messages) do
    prompt = build_summarization_prompt(messages)

    with {:ok, summary_text} <- Bodhi.AI.ask_llm(prompt),
         {:ok, _summary} <-
           store_summary(
             chat_id,
             date,
             summary_text,
             messages
           ) do
      :ok
    end
  end

  @doc """
  Builds the summarization prompt by prepending an
  instruction message to the conversation messages.
  """
  @spec build_summarization_prompt([Message.t()]) ::
          [Message.t()]
  def build_summarization_prompt(messages) do
    instruction = %Message{
      text: @summarization_prompt,
      chat_id: @system_chat_id,
      user_id: @system_user_id
    }

    [instruction | messages]
  end

  @doc """
  Returns the name of the currently configured AI model.
  """
  @spec current_ai_model() :: String.t()
  def current_ai_model do
    :bodhi
    |> Application.fetch_env!(:ai_client)
    |> Module.split()
    |> List.last()
  end

  defp store_summary(
         chat_id,
         date,
         summary_text,
         [first | _] = messages
       ) do
    Chats.create_summary(%{
      chat_id: chat_id,
      summary_date: date,
      summary_text: summary_text,
      message_count: length(messages),
      start_time: first.inserted_at,
      end_time: List.last(messages).inserted_at,
      ai_model: current_ai_model()
    })
  end

  @doc false
  def system_user_id, do: @system_user_id
end
