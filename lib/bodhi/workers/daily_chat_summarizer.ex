defmodule Bodhi.Workers.DailyChatSummarizer do
  @moduledoc """
  Runs daily at 2 AM UTC to summarize all active chats
  from previous day. Processes chats sequentially in a
  single job.
  """

  use Oban.Worker,
    queue: :default,
    max_attempts: 3

  require Logger

  alias Bodhi.Chats
  alias Bodhi.Chats.Summarizer

  @impl Oban.Worker
  def perform(%Oban.Job{}) do
    if summarization_enabled?() do
      run_summarization()
    else
      Logger.info("Summarization disabled, skipping")
      :ok
    end
  end

  defp summarization_enabled? do
    :bodhi
    |> Application.get_env(:summarization, [])
    |> Keyword.get(:enabled, false)
  end

  defp run_summarization do
    yesterday = Date.utc_today() |> Date.add(-1)

    Logger.info("Starting daily summarization for #{yesterday}")

    active_chats = Chats.get_active_chats_for_date(yesterday)

    results =
      Enum.map(active_chats, fn chat_id ->
        summarize_chat(chat_id, yesterday)
      end)

    success_count = Enum.count(results, &match?(:ok, &1))
    error_count = Enum.count(results, &match?({:error, _}, &1))

    Logger.info(
      "Daily summarization complete: " <>
        "#{success_count} successful, #{error_count} failed"
    )

    case {success_count, error_count} do
      {_, 0} ->
        :ok

      {0, _} ->
        {:error, "All #{error_count} chats failed"}

      _ ->
        :ok
    end
  end

  defp summarize_chat(chat_id, summary_date) do
    case Chats.get_summary(chat_id, summary_date) do
      nil ->
        create_summary_for_chat(chat_id, summary_date)

      _existing ->
        Logger.debug(
          "Chat #{chat_id}: Summary already exists " <>
            "for #{summary_date}"
        )

        :ok
    end
  rescue
    e in [Ecto.QueryError, DBConnection.ConnectionError] ->
      Logger.error(Exception.format(:error, e, __STACKTRACE__))

      {:error, e}
  end

  defp create_summary_for_chat(chat_id, summary_date) do
    messages = Chats.get_messages_for_date(chat_id, summary_date)

    if Enum.empty?(messages) do
      Logger.debug(
        "Chat #{chat_id}: No messages to summarize " <>
          "for #{summary_date}"
      )

      :ok
    else
      count = length(messages)

      Logger.info(
        "Chat #{chat_id}: Summarizing #{count} messages " <>
          "for #{summary_date}"
      )

      case Summarizer.generate_and_store(
             chat_id,
             summary_date,
             messages
           ) do
        :ok ->
          Logger.info("Chat #{chat_id}: Summary created successfully")

          :ok

        {:error, reason} = error ->
          Logger.error(
            "Chat #{chat_id}: Summarization failed - " <>
              "#{inspect(reason)}"
          )

          error
      end
    end
  end
end
