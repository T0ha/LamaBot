defmodule Bodhi.PeriodicMessagesTest do
  use Bodhi.ObanCase, async: true

  alias Bodhi.PeriodicMessages

  describe "create_for_new_user/3" do
    test "schedules a new periodic message job" do
      type = :followup
      period = Faker.random_between(1, 10)
      unit = :days

      message = build(:message)

      assert %Oban.Job{} =
               PeriodicMessages.create_for_new_user(type, {period, unit}, message.chat_id)

      assert_enqueued(
        worker: PeriodicMessages,
        args: %{
          "message_type" => type,
          "chat_id" => message.chat_id,
          "peiod" => period,
          "unit" => unit
        }
      )
    end
  end

  describe "perform/1" do
    test "sends follow-up message when conditions are met", %{chat: chat, bot_user: bot_user} do
      type = "followup"
      period = 1
      unit = "days"

      prompt = insert(:prompt, type: type, lang: "en")

      insert(:message, chat: chat, from: chat.user, inserted_at: Faker.DateTime.backward(3))

      # Expect the Telegram message to be sent
      chat_id = chat.id
      prompt_text = prompt.text

      expect(Bodhi.TelegramMock, :send_message, fn ^chat_id, text ->
        assert text == prompt_text

        {:ok,
         %Telegex.Type.Message{
           from: %Telegex.Type.User{
             id: bot_user.id,
             first_name: bot_user.first_name,
             last_name: bot_user.last_name,
             username: bot_user.username,
             is_bot: true
           },
           chat: %Telegex.Type.Chat{id: chat_id, type: "private"},
           date: DateTime.utc_now() |> DateTime.to_unix(),
           message_id: Faker.random_between(1, 1000),
           text: text
         }}
      end)

      assert :ok =
               PeriodicMessages.perform(%Oban.Job{
                 args: %{
                   "chat_id" => chat.id,
                   "message_type" => type,
                   "peiod" => period,
                   "unit" => unit
                 }
               })
    end

    test "not sends follow-up before @followup_threshold pass", %{chat: chat} do
      type = "followup"
      period = 1
      unit = "days"

      _prompt = insert(:prompt, type: type, lang: "en")

      insert(:message, chat: chat, from: chat.user, inserted_at: Faker.DateTime.backward(0))

      # No expectation for send_message - we're testing it should NOT be called
      # The stub from setup will handle any unexpected calls and fail the test

      assert :ok =
               PeriodicMessages.perform(%Oban.Job{
                 args: %{
                   "chat_id" => chat.id,
                   "message_type" => type,
                   "peiod" => period,
                   "unit" => unit
                 }
               })

      # No assertions needed - Mox will verify send_message was not called
    end
  end
end
