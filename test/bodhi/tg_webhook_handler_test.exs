defmodule Bodhi.TgWebhookHandlerTest do
  use Bodhi.ObanCase

  alias Telegex.Type.{Chat, Message, MessageEntity, Update, User}
  alias Bodhi.TgWebhookHandler

  describe "handle_update/1" do
    test "Any TG update are handled correctly" do
      assert :ok == TgWebhookHandler.on_update(%Update{update_id: Faker.random_bytes(100)})
    end

    @tag text: Faker.Lorem.sentence()
    test "TG messages are handled correctly", tags do
      test_handle_message(tags)
    end

    @tag text: "/start", gemini: false, command: true
    test "/start are handled correctly", tags do
      prompt = insert(:prompt, type: "start_message", lang: "en")
      test_handle_message(tags, reply: prompt.text)
      #  assert_called(Telegex.send_message(chat_id, prompt.text))
      #  assert response.text == prompt.text
    end

    @tag text: "/login", gemini: false, command: true, db: false, oban: false
    test "/login for admin returns link", tags do
      admin = insert(:user, is_admin: true)

      test_handle_message(tags, fields: %{[:message, :from, :id] => admin.id})
      #  assert_called(Telegex.send_message(chat_id, prompt.text))
      #  assert response.text == prompt.text
    end

    @tag text: "/login", gemini: false, command: true, reply: false, db: false, oban: false
    test "/login for non admin doesn't respond", tags do
      user = insert(:user, is_admin: false)
      test_handle_message(tags, fields: %{[:message, :from, :id] => user.id})
    end

    @tag text: "/#{Faker.Lorem.word()}", gemini: false, command: true, relpy: false
    test "Unknown / commands are handled correctly", tags do
      test_handle_message(tags)
    end
  end

  describe "send_message/2" do
    test "Sends and saves message correctly", %{chat: chat} do
      text = Faker.Lorem.paragraph()

      assert {:ok, %Bodhi.Chats.Message{} = message} =
               TgWebhookHandler.send_message(chat.id, text)

      assert message.chat_id == chat.id
      assert message.text == text

      assert_called(Telegex.send_message(chat.id, text))

      assert message ==
               Bodhi.Chats.get_last_message(chat.id)
    end
  end

  def gen_update(%{text: text} = tags, fields \\ %{}) do
    command? = Map.get(tags, :command, false)

    entities =
      if command? do
        [
          %MessageEntity{
            type: "bot_command",
            length: byte_size(text),
            offset: 0
          }
        ]
      else
        []
      end

    %Update{
      update_id: Faker.random_bytes(100),
      message: %Message{
        message_id: Faker.random_between(1, 65536),
        text: text,
        entities: entities,
        date: DateTime.utc_now() |> DateTime.to_unix(),
        chat: %Chat{
          id: Faker.random_between(1, 65536),
          title: Faker.Person.name(),
          type: "private"
        },
        from: %User{
          id: Faker.random_between(1, 65536),
          first_name: Faker.Person.first_name(),
          last_name: Faker.Person.last_name(),
          is_bot: false,
          username: Faker.Person.name(),
          language_code: "en"
        }
      }
    }
    |> then(fn update ->
      for {key, value} <- fields, reduce: update do
        upd -> put_in(upd, Enum.map(key, &Access.key!/1), value)
      end
    end)
  end

  def test_handle_message(tags, opts \\ []) do
    db? = Map.get(tags, :db, true)
    oban? = Map.get(tags, :oban, true)
    gemini? = Map.get(tags, :gemini, true)
    reply? = Map.get(tags, :reply, true)

    update = gen_update(tags, Keyword.get(opts, :fields, %{}))
    chat_id = update.message.chat.id

    assert :ok ==
             TgWebhookHandler.on_update(update)

    if gemini? do
      assert_called(Bodhi.Gemini.ask_gemini([:_]))
    else
      assert_not_called(Bodhi.Gemini.ask_gemini([:_]))
    end

    if reply? do
      assert_called(Telegex.send_message(chat_id, Keyword.get(opts, :reply, :_)))
    else
      assert_not_called(Telegex.send_message(chat_id, :_))
    end

    if db? do
      assert [received | other] =
               Bodhi.Chats.get_chat_messages(chat_id)

      assert received.text == update.message.text
      assert received.user_id == update.message.from.id

      if reply? do
        assert [response] = other

        if opts[:reply] do
          assert response.text == Keyword.get(opts, :reply)
        end
      else
        assert other == []
      end

      assert %Bodhi.Chats.Chat{
               id: ^chat_id
             } = Bodhi.Chats.get_chat!(chat_id)

      assert %Bodhi.Users.User{} = Bodhi.Users.get_user!(update.message.from.id)
    end

    if oban? do
      assert_enqueued(
        worker: Bodhi.PeriodicMessages,
        args: %{
          "message_type" => "followup",
          "chat_id" => chat_id,
          "peiod" => 1,
          "unit" => "days"
        }
      )
    end
  end
end
