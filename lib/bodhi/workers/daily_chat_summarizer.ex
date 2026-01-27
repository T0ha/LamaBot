defmodule Bodhi.Workers.DailyChatSummarizer do
  @moduledoc """
  Runs daily at 2 AM UTC to summarize all active chats from previous day.
  Processes chats sequentially in a single job.
  Follows the pattern from Bodhi.PeriodicMessages.
  """

  use Oban.Worker,
    queue: :default,
    max_attempts: 3

  require Logger

  alias Bodhi.Chats
  alias Bodhi.Chats.Message

  @impl Oban.Worker
  def perform(%Oban.Job{}) do
    yesterday = Date.utc_today() |> Date.add(-1)

    Logger.info("Starting daily summarization for #{yesterday}")

    # Find chats with messages from yesterday
    active_chats = Chats.get_active_chats_for_date(yesterday)

    # Process each chat sequentially
    results =
      Enum.map(active_chats, fn chat_id ->
        summarize_chat(chat_id, yesterday)
      end)

    # Log summary statistics
    success_count = Enum.count(results, &match?(:ok, &1))
    error_count = Enum.count(results, &match?({:error, _}, &1))

    Logger.info(
      "Daily summarization complete: #{success_count} successful, #{error_count} failed"
    )

    :ok
  end

  defp summarize_chat(chat_id, summary_date) do
    # Check if summary already exists (idempotency)
    case Chats.get_summary(chat_id, summary_date) do
      nil ->
        # Fetch messages for that date
        messages = Chats.get_messages_for_date(chat_id, summary_date)

        case length(messages) do
          0 ->
            Logger.debug("Chat #{chat_id}: No messages to summarize for #{summary_date}")
            :ok

          count ->
            Logger.info("Chat #{chat_id}: Summarizing #{count} messages for #{summary_date}")

            # Prepare summarization prompt
            summary_messages = build_summarization_prompt(messages)

            # Call AI backend
            case Bodhi.AI.ask_llm(summary_messages) do
              {:ok, summary_text} ->
                # Store summary
                {:ok, _summary} =
                  Chats.create_summary(%{
                    chat_id: chat_id,
                    summary_date: summary_date,
                    summary_text: summary_text,
                    message_count: count,
                    start_time: List.first(messages).inserted_at,
                    end_time: List.last(messages).inserted_at,
                    ai_model: get_current_ai_model()
                  })

                Logger.info("Chat #{chat_id}: Summary created successfully")
                :ok

              {:error, reason} = error ->
                Logger.error("Chat #{chat_id}: Summarization failed - #{inspect(reason)}")
                error
            end
        end

      _existing_summary ->
        Logger.debug("Chat #{chat_id}: Summary already exists for #{summary_date}")
        :ok
    end
  rescue
    e ->
      Logger.error("Chat #{chat_id}: Exception during summarization - #{inspect(e)}")
      {:error, e}
  end

  defp build_summarization_prompt(messages) do
    # Get summarization system prompt
    summary_instruction = %Message{
      text:
        "Summarize the following conversation concisely. Capture key topics, questions, decisions, and emotional tone. Keep it under 200 words. Focus on what matters for future context.",
      chat_id: -1,
      # Special marker for system messages
      user_id: -1
    }

    # Combine instruction with messages
    [summary_instruction | messages]
  end

  defp get_current_ai_model do
    Application.get_env(:bodhi, :ai_client)
    |> Module.split()
    |> List.last()
  end
end
