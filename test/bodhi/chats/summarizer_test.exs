defmodule Bodhi.Chats.SummarizerTest do
  use Bodhi.DataCase

  import Mox

  alias Bodhi.Chats.Summarizer

  setup :verify_on_exit!

  describe "generate_and_store/3" do
    test "creates a summary via AI and stores it" do
      chat = insert(:chat)
      msg = insert(:message, chat: chat)
      date = NaiveDateTime.to_date(msg.inserted_at)

      Bodhi.LLMMock
      |> expect(:ask_llm, fn _messages ->
        {:ok, "Test summary text"}
      end)

      assert :ok =
               Summarizer.generate_and_store(
                 chat.id,
                 date,
                 [msg]
               )

      summary = Bodhi.Chats.get_summary(chat.id, date)
      assert summary.summary_text == "Test summary text"
      assert summary.message_count == 1
      assert summary.chat_id == chat.id
    end

    test "returns error when AI call fails" do
      chat = insert(:chat)
      msg = insert(:message, chat: chat)

      Bodhi.LLMMock
      |> expect(:ask_llm, fn _messages ->
        {:error, "API error"}
      end)

      assert {:error, "API error"} =
               Summarizer.generate_and_store(
                 chat.id,
                 ~D[2024-01-01],
                 [msg]
               )
    end
  end

  describe "build_summarization_prompt/1" do
    test "prepends instruction message" do
      msg = build(:message, text: "Hello")
      result = Summarizer.build_summarization_prompt([msg])

      assert [instruction | rest] = result
      assert instruction.chat_id == -1
      assert instruction.user_id == -1
      assert instruction.text =~ "Summarize"
      assert rest == [msg]
    end
  end

  describe "current_ai_model/0" do
    test "returns the configured AI model name" do
      model = Summarizer.current_ai_model()
      assert model == "LLMMock"
    end
  end
end
