defmodule Bodhi.Release do
  @moduledoc """
  Used for executing DB release tasks when run in production
  without Mix installed.
  """
  @app :bodhi

  require Logger

  import Ecto.Query

  alias Bodhi.Chats.Summarizer

  def migrate do
    load_app()

    for repo <- repos() do
      {:ok, _, _} =
        Ecto.Migrator.with_repo(
          repo,
          &Ecto.Migrator.run(&1, :up, all: true)
        )
    end
  end

  def rollback(repo, version) do
    load_app()

    {:ok, _, _} =
      Ecto.Migrator.with_repo(
        repo,
        &Ecto.Migrator.run(&1, :down, to: version)
      )
  end

  @doc """
  Backfills summaries for all historical messages.

  WARNING: This will consume AI API credits for each day
  of each chat!

  Options:
    - dry_run: true - Preview without creating summaries
    - from_date: Date.t() - Start date (default: earliest)
    - to_date: Date.t() - End date (default: yesterday)
    - chat_ids: [integer()] - Specific chats (default: all)

  ## Examples

      # Dry run to see what would be processed
      Bodhi.Release.backfill_summaries(dry_run: true)

      # Backfill all chats
      Bodhi.Release.backfill_summaries()

      # Backfill specific date range
      Bodhi.Release.backfill_summaries(
        from_date: ~D[2024-01-01],
        to_date: ~D[2024-12-31]
      )

      # Backfill specific chats
      Bodhi.Release.backfill_summaries(chat_ids: [123, 456])
  """
  @spec backfill_summaries(keyword()) :: :ok
  def backfill_summaries(opts \\ []) do
    load_app()
    start_app()

    dry_run = Keyword.get(opts, :dry_run, false)

    to_date =
      Keyword.get(opts, :to_date, Date.utc_today() |> Date.add(-1))

    Logger.info("Starting summary backfill (dry_run: #{dry_run})")

    chat_ids = get_chat_ids_to_process(opts)
    Logger.info("Found #{length(chat_ids)} chats to process")

    results =
      Enum.map(chat_ids, fn chat_id ->
        backfill_chat_summaries(
          chat_id,
          to_date,
          opts,
          dry_run
        )
      end)

    total_chats = length(results)

    total_summaries =
      results
      |> Enum.map(fn {_, count, _} -> count end)
      |> Enum.sum()

    total_skipped =
      results
      |> Enum.map(fn {_, _, skipped} -> skipped end)
      |> Enum.sum()

    Logger.info("""
    Backfill complete:
      - Chats processed: #{total_chats}
      - Summaries created: #{total_summaries}
      - Days skipped (already exist): #{total_skipped}
      - Dry run: #{dry_run}
    """)

    :ok
  end

  defp get_chat_ids_to_process(opts) do
    case Keyword.get(opts, :chat_ids) do
      nil ->
        Bodhi.Repo.all(
          from(m in Bodhi.Chats.Message,
            distinct: m.chat_id,
            select: m.chat_id
          )
        )

      chat_ids when is_list(chat_ids) ->
        chat_ids
    end
  end

  defp backfill_chat_summaries(chat_id, to_date, opts, dry_run) do
    from_date = get_from_date_for_chat(chat_id, opts)

    Logger.info(
      "Processing chat #{chat_id} " <>
        "from #{from_date} to #{to_date}"
    )

    dates = Date.range(from_date, to_date)

    {created, skipped} =
      process_date_range(chat_id, dates, dry_run)

    Logger.info(
      "Chat #{chat_id}: #{created} summaries created, " <>
        "#{skipped} days skipped"
    )

    {chat_id, created, skipped}
  end

  defp get_from_date_for_chat(chat_id, opts) do
    case Keyword.get(opts, :from_date) do
      nil ->
        query =
          from(m in Bodhi.Chats.Message,
            where: m.chat_id == ^chat_id,
            select: min(m.inserted_at),
            limit: 1
          )

        case Bodhi.Repo.one(query) do
          nil -> Date.utc_today()
          earliest -> NaiveDateTime.to_date(earliest)
        end

      date ->
        date
    end
  end

  defp process_date_range(chat_id, dates, dry_run) do
    Enum.reduce(dates, {0, 0}, fn date, {created, skipped} ->
      case process_single_date(chat_id, date, dry_run) do
        :created -> {created + 1, skipped}
        :skipped -> {created, skipped + 1}
        :error -> {created, skipped + 1}
      end
    end)
  end

  defp process_single_date(chat_id, date, dry_run) do
    if Bodhi.Chats.get_summary(chat_id, date) do
      :skipped
    else
      process_date_messages(chat_id, date, dry_run)
    end
  end

  defp process_date_messages(chat_id, date, dry_run) do
    messages =
      Bodhi.Chats.get_messages_for_date(chat_id, date)

    if Enum.empty?(messages) do
      :skipped
    else
      create_summary_for_date(
        chat_id,
        date,
        messages,
        dry_run
      )
    end
  end

  defp create_summary_for_date(chat_id, date, messages, true) do
    Logger.debug(
      "Would create summary for chat #{chat_id} " <>
        "on #{date} (#{length(messages)} messages)"
    )

    :created
  end

  defp create_summary_for_date(chat_id, date, messages, false) do
    Logger.debug(
      "Creating summary for chat #{chat_id} " <>
        "on #{date} (#{length(messages)} messages)"
    )

    case Summarizer.generate_and_store(
           chat_id,
           date,
           messages
         ) do
      :ok ->
        :created

      {:error, reason} ->
        Logger.error(
          "Failed to create summary for chat #{chat_id} " <>
            "on #{date}: #{inspect(reason)}"
        )

        :error
    end
  end

  defp repos do
    Application.fetch_env!(@app, :ecto_repos)
  end

  defp load_app do
    Application.ensure_all_started(:ssl)
    Application.ensure_loaded(@app)
  end

  defp start_app do
    {:ok, _} = Application.ensure_all_started(@app)
  end
end
