defmodule Bodhi.Workers.DailyChatSummarizerTest do
  use Bodhi.ObanCase

  alias Bodhi.Workers.DailyChatSummarizer

  describe "perform/1" do
    test "summarizes yesterday's active chats" do
      chat = insert(:chat)
      yesterday = Date.utc_today() |> Date.add(-1)

      yesterday_naive =
        yesterday
        |> DateTime.new!(~T[12:00:00], "Etc/UTC")
        |> DateTime.to_naive()

      insert(:message,
        chat: chat,
        inserted_at: yesterday_naive
      )

      Bodhi.LLMMock
      |> expect(:ask_llm, fn messages ->
        assert length(messages) == 2
        {:ok, "Yesterday's summary"}
      end)

      assert :ok =
               DailyChatSummarizer.perform(%Oban.Job{
                 args: %{}
               })

      summary =
        Bodhi.Chats.get_summary(chat.id, yesterday)

      assert summary
      assert summary.summary_text == "Yesterday's summary"
      assert summary.message_count == 1
    end

    test "skips chats that already have summaries" do
      chat = insert(:chat)
      yesterday = Date.utc_today() |> Date.add(-1)

      yesterday_naive =
        yesterday
        |> DateTime.new!(~T[12:00:00], "Etc/UTC")
        |> DateTime.to_naive()

      insert(:message,
        chat: chat,
        inserted_at: yesterday_naive
      )

      insert(:summary,
        chat: chat,
        summary_date: yesterday
      )

      # AI should NOT be called since summary exists
      assert :ok =
               DailyChatSummarizer.perform(%Oban.Job{
                 args: %{}
               })
    end

    test "returns :ok even when no active chats" do
      assert :ok =
               DailyChatSummarizer.perform(%Oban.Job{
                 args: %{}
               })
    end

    test "continues on error for individual chats" do
      chat1 = insert(:chat)
      chat2 = insert(:chat)
      yesterday = Date.utc_today() |> Date.add(-1)

      yesterday_naive =
        yesterday
        |> DateTime.new!(~T[12:00:00], "Etc/UTC")
        |> DateTime.to_naive()

      insert(:message,
        chat: chat1,
        inserted_at: yesterday_naive
      )

      insert(:message,
        chat: chat2,
        inserted_at: yesterday_naive
      )

      Bodhi.LLMMock
      |> expect(:ask_llm, fn _messages ->
        {:error, "API failure"}
      end)
      |> expect(:ask_llm, fn _messages ->
        {:ok, "Chat 2 summary"}
      end)

      assert :ok =
               DailyChatSummarizer.perform(%Oban.Job{
                 args: %{}
               })
    end
  end
end
