defmodule Bodhi.PeriodicMessagesTest do
  use Bodhi.ObanCase, async: true

  alias Bodhi.PeriodicMessages
  alias Bodhi.Chats
  alias Bodhi.Chats.Message
  alias Bodhi.Users
  alias Bodhi.Users.User
  alias Bodhi.Prompts
  alias Bodhi.Prompts.Prompt

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
        args: %{"message_type" => type, "chat_id" => message.chat_id, "peiod" => period, "unit" => unit}
      )
    end
  end

  describe "perform/1" do
    test_with_mocks "sends follow-up message when conditions are met", %{}, [
      {Chats, [],
       [
         get_last_message: fn _ ->
           %Message{
             user_id: Faker.random_between(1, 1000),
             inserted_at: Faker.DateTime.backward(3)
           }
         end
       ]},
      {Users, [],
       [
         get_by_chat!: fn _ ->
           %User{
             id: Faker.random_between(1, 1000),
             language_code: "en"
           }
         end
       ]},
      {Prompts, [],
       [
         get_random_prompt_by_type_and_lang: fn _, _ ->
           %Prompt{
             id: Faker.random_between(1, 1000),
             text: Faker.Lorem.sentence()
           }
         end
       ]}
    ] do
      chat_id = Faker.random_between(1, 1000)
      type = "followup"
      period = 1
      unit = "days"

      assert :ok =
               PeriodicMessages.perform(%Oban.Job{
          args: %{"chat_id" => chat_id, "message_type" => type, "peiod" => period, "unit" => unit}
               })

      assert_called Posthog.capture(:_, :_)
      assert_called Telegex.send_message(chat_id, :_)
    end

    test_with_mocks "not sends follow-up before @followup_threshold pass", %{}, [
      {Chats, [],
       [
         get_last_message: fn _ ->
           %Message{
             user_id: Faker.random_between(1, 1000),
             inserted_at: Faker.DateTime.backward(0)
           }
         end
       ]},
      {Users, [],
       [
         get_by_chat!: fn _ ->
           %User{
             id: Faker.random_between(1, 1000),
             language_code: "en"
           }
         end
       ]},
      {Prompts, [],
       [
         get_random_prompt_by_type_and_lang: fn _, _ ->
           %Prompt{
             id: Faker.random_between(1, 1000),
             text: Faker.Lorem.sentence()
           }
         end
       ]}
    ] do
      chat_id = Faker.random_between(1, 1000)
      type = "followup"
      period = 1
      unit = "days"

      assert :ok =
               PeriodicMessages.perform(%Oban.Job{
          args: %{"chat_id" => chat_id, "message_type" => type, "peiod" => period, "unit" => unit}
               })

      assert_not_called Posthog.capture(:_, :_)
      assert_not_called Telegex.send_message(chat_id, :_)
    end
  end
end
