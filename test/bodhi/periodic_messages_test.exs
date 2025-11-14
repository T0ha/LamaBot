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
    test "sends follow-up message when conditions are met", %{chat: chat} do
      type = "followup"
      period = 1
      unit = "days"

      prompt = insert(:prompt, type: type, lang: "en")

      insert(:message, chat: chat, from: chat.user, inserted_at: Faker.DateTime.backward(3))

      assert :ok =
               PeriodicMessages.perform(%Oban.Job{
                 args: %{
                   "chat_id" => chat.id,
                   "message_type" => type,
                   "peiod" => period,
                   "unit" => unit
                 }
               })

      assert_called(PostHog.capture("followup_sent", :_))
      assert_called(Telegex.send_message(chat.id, prompt.text))
    end

    test "not sends follow-up before @followup_threshold pass", %{chat: chat} do
      type = "followup"
      period = 1
      unit = "days"

      prompt = insert(:prompt, type: type, lang: "en")

      insert(:message, chat: chat, from: chat.user, inserted_at: Faker.DateTime.backward(0))

      assert :ok =
               PeriodicMessages.perform(%Oban.Job{
                 args: %{
                   "chat_id" => chat.id,
                   "message_type" => type,
                   "peiod" => period,
                   "unit" => unit
                 }
               })

      assert_not_called(PostHog.capture("followup_sent", :_))
      assert_not_called(Telegex.send_message(chat.id, prompt.text))
    end
  end
end
