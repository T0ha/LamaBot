defmodule Bodhi.Chats.ContextTest do
  use Bodhi.DataCase

  alias Bodhi.Chats

  describe "summary CRUD" do
    test "create_summary/1 with valid attrs" do
      chat = insert(:chat)

      attrs = %{
        chat_id: chat.id,
        summary_text: "Daily summary",
        summary_date: ~D[2024-06-15],
        message_count: 10
      }

      assert {:ok, summary} = Chats.create_summary(attrs)
      assert summary.chat_id == chat.id
      assert summary.summary_text == "Daily summary"
    end

    test "create_summary/1 with invalid attrs" do
      assert {:error, %Ecto.Changeset{}} =
               Chats.create_summary(%{chat_id: nil})
    end

    test "get_summary/2 returns existing summary" do
      summary = insert(:summary)

      found =
        Chats.get_summary(
          summary.chat_id,
          summary.summary_date
        )

      assert found.id == summary.id
    end

    test "get_summary/2 returns nil when not found" do
      assert nil == Chats.get_summary(999_999, ~D[2024-01-01])
    end
  end

  describe "get_active_chats_for_date/1" do
    test "returns chat IDs with messages on date" do
      chat = insert(:chat)

      insert(:message,
        chat: chat,
        inserted_at: ~N[2024-06-15 12:00:00]
      )

      result = Chats.get_active_chats_for_date(~D[2024-06-15])
      assert chat.id in result
    end

    test "excludes chats without messages on date" do
      chat = insert(:chat)

      insert(:message,
        chat: chat,
        inserted_at: ~N[2024-06-14 12:00:00]
      )

      result = Chats.get_active_chats_for_date(~D[2024-06-15])
      refute chat.id in result
    end
  end

  describe "get_messages_for_date/2" do
    test "returns messages for chat on given date" do
      chat = insert(:chat)

      msg =
        insert(:message,
          chat: chat,
          inserted_at: ~N[2024-06-15 10:00:00]
        )

      result =
        Chats.get_messages_for_date(chat.id, ~D[2024-06-15])

      assert length(result) == 1
      assert hd(result).id == msg.id
    end

    test "excludes messages from other dates" do
      chat = insert(:chat)

      insert(:message,
        chat: chat,
        inserted_at: ~N[2024-06-14 23:59:59]
      )

      result =
        Chats.get_messages_for_date(chat.id, ~D[2024-06-15])

      assert result == []
    end

    test "orders messages by inserted_at asc" do
      chat = insert(:chat)

      m2 =
        insert(:message,
          chat: chat,
          inserted_at: ~N[2024-06-15 14:00:00]
        )

      m1 =
        insert(:message,
          chat: chat,
          inserted_at: ~N[2024-06-15 08:00:00]
        )

      result =
        Chats.get_messages_for_date(chat.id, ~D[2024-06-15])

      assert [first, second] = result
      assert first.id == m1.id
      assert second.id == m2.id
    end
  end

  describe "get_recent_messages/2" do
    test "returns messages on or after cutoff date" do
      chat = insert(:chat)

      insert(:message,
        chat: chat,
        inserted_at: ~N[2024-06-14 23:59:59]
      )

      recent =
        insert(:message,
          chat: chat,
          inserted_at: ~N[2024-06-15 00:00:00]
        )

      result =
        Chats.get_recent_messages(chat.id, ~D[2024-06-15])

      assert length(result) == 1
      assert hd(result).id == recent.id
    end
  end

  describe "get_summaries_before_date/2" do
    test "returns summaries before cutoff" do
      chat = insert(:chat)

      old =
        insert(:summary,
          chat: chat,
          summary_date: ~D[2024-06-10]
        )

      _recent =
        insert(:summary,
          chat: chat,
          summary_date: ~D[2024-06-15]
        )

      result =
        Chats.get_summaries_before_date(
          chat.id,
          ~D[2024-06-15]
        )

      assert length(result) == 1
      assert hd(result).id == old.id
    end
  end

  describe "get_chat_context_for_ai/2" do
    test "returns recent messages when no summaries" do
      chat = insert(:chat)

      msg =
        insert(:message,
          chat: chat,
          inserted_at: NaiveDateTime.utc_now()
        )

      result = Chats.get_chat_context_for_ai(chat.id)
      assert length(result) == 1
      assert hd(result).id == msg.id
    end

    test "combines summaries and recent messages" do
      chat = insert(:chat)

      insert(:summary,
        chat: chat,
        summary_date: Date.utc_today() |> Date.add(-30),
        summary_text: "Old summary"
      )

      msg =
        insert(:message,
          chat: chat,
          inserted_at: NaiveDateTime.utc_now()
        )

      result = Chats.get_chat_context_for_ai(chat.id)

      assert length(result) == 2
      [summary_msg, recent_msg] = result
      assert summary_msg.text =~ "Old summary"
      assert summary_msg.user_id == -1
      assert recent_msg.id == msg.id
    end

    test "respects recent_days option" do
      chat = insert(:chat)

      insert(:message,
        chat: chat,
        inserted_at:
          NaiveDateTime.utc_now()
          |> NaiveDateTime.add(-4 * 86_400)
      )

      result =
        Chats.get_chat_context_for_ai(
          chat.id,
          recent_days: 3
        )

      assert result == []
    end
  end
end
