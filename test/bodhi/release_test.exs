defmodule Bodhi.ReleaseTest do
  use Bodhi.ObanCase

  import ExUnit.CaptureLog

  alias Bodhi.Chats

  describe "backfill_summaries/1" do
    test "dry run does not create summaries" do
      chat = insert(:chat)
      date = ~D[2024-06-15]

      insert(:message,
        chat: chat,
        inserted_at: ~N[2024-06-15 12:00:00]
      )

      log =
        capture_log(fn ->
          assert :ok =
                   Bodhi.Release.backfill_summaries(
                     dry_run: true,
                     from_date: date,
                     to_date: date,
                     chat_ids: [chat.id]
                   )
        end)

      assert log =~ "dry_run: true"
      assert log =~ "1 summaries created"
      assert Chats.get_summary(chat.id, date) == nil
    end

    test "creates summaries for dates with messages" do
      chat = insert(:chat)
      date = ~D[2024-06-15]

      insert(:message,
        chat: chat,
        inserted_at: ~N[2024-06-15 12:00:00]
      )

      Bodhi.LLMMock
      |> expect(:ask_llm, fn _messages ->
        {:ok, %Bodhi.LLM.Response{content: "Backfill summary"}}
      end)

      capture_log(fn ->
        assert :ok =
                 Bodhi.Release.backfill_summaries(
                   from_date: date,
                   to_date: date,
                   chat_ids: [chat.id]
                 )
      end)

      summary = Chats.get_summary(chat.id, date)
      assert summary
      assert summary.summary_text == "Backfill summary"
      assert summary.message_count == 1
    end

    test "skips dates that already have summaries" do
      chat = insert(:chat)
      date = ~D[2024-06-15]

      insert(:message,
        chat: chat,
        inserted_at: ~N[2024-06-15 12:00:00]
      )

      insert(:summary,
        chat: chat,
        summary_date: date
      )

      # AI should NOT be called
      log =
        capture_log(fn ->
          assert :ok =
                   Bodhi.Release.backfill_summaries(
                     from_date: date,
                     to_date: date,
                     chat_ids: [chat.id]
                   )
        end)

      assert log =~ "0 summaries created"
    end

    test "skips dates with no messages" do
      chat = insert(:chat)

      log =
        capture_log(fn ->
          assert :ok =
                   Bodhi.Release.backfill_summaries(
                     from_date: ~D[2024-06-15],
                     to_date: ~D[2024-06-15],
                     chat_ids: [chat.id]
                   )
        end)

      assert log =~ "0 summaries created"
    end

    test "processes multiple dates in range" do
      chat = insert(:chat)

      insert(:message,
        chat: chat,
        inserted_at: ~N[2024-06-15 12:00:00]
      )

      insert(:message,
        chat: chat,
        inserted_at: ~N[2024-06-16 12:00:00]
      )

      Bodhi.LLMMock
      |> expect(:ask_llm, 2, fn _messages ->
        {:ok, %Bodhi.LLM.Response{content: "Summary"}}
      end)

      log =
        capture_log(fn ->
          assert :ok =
                   Bodhi.Release.backfill_summaries(
                     from_date: ~D[2024-06-15],
                     to_date: ~D[2024-06-16],
                     chat_ids: [chat.id]
                   )
        end)

      assert log =~ "2 summaries created"
      assert Chats.get_summary(chat.id, ~D[2024-06-15])
      assert Chats.get_summary(chat.id, ~D[2024-06-16])
    end

    test "continues on AI error" do
      chat = insert(:chat)

      insert(:message,
        chat: chat,
        inserted_at: ~N[2024-06-15 12:00:00]
      )

      insert(:message,
        chat: chat,
        inserted_at: ~N[2024-06-16 12:00:00]
      )

      Bodhi.LLMMock
      |> expect(:ask_llm, fn _messages ->
        {:error, "API failure"}
      end)
      |> expect(:ask_llm, fn _messages ->
        {:ok, %Bodhi.LLM.Response{content: "Second day summary"}}
      end)

      log =
        capture_log(fn ->
          assert :ok =
                   Bodhi.Release.backfill_summaries(
                     from_date: ~D[2024-06-15],
                     to_date: ~D[2024-06-16],
                     chat_ids: [chat.id]
                   )
        end)

      assert log =~ "1 summaries created"
      assert log =~ "Failed to create summary"
      assert Chats.get_summary(chat.id, ~D[2024-06-15]) == nil
      assert Chats.get_summary(chat.id, ~D[2024-06-16])
    end

    test "filters by chat_ids option" do
      chat1 = insert(:chat)
      chat2 = insert(:chat)
      date = ~D[2024-06-15]

      insert(:message,
        chat: chat1,
        inserted_at: ~N[2024-06-15 12:00:00]
      )

      insert(:message,
        chat: chat2,
        inserted_at: ~N[2024-06-15 12:00:00]
      )

      Bodhi.LLMMock
      |> expect(:ask_llm, fn _messages ->
        {:ok, %Bodhi.LLM.Response{content: "Only chat1"}}
      end)

      capture_log(fn ->
        assert :ok =
                 Bodhi.Release.backfill_summaries(
                   from_date: date,
                   to_date: date,
                   chat_ids: [chat1.id]
                 )
      end)

      assert Chats.get_summary(chat1.id, date)
      assert Chats.get_summary(chat2.id, date) == nil
    end
  end
end
