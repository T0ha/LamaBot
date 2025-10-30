defmodule Bodhi.ChatsTest do
  use Bodhi.DataCase

  alias Bodhi.Chats

  describe "chats" do
    alias Bodhi.Chats.Chat

    test "list_chats/0 returns all chats" do
      chat = insert(:chat, messages: [])
      assert Chats.list_chats() |> Repo.preload(:user) == [chat]
    end

    test "get_chat!/1 returns the chat with given id" do
      chat = insert(:chat)

      assert chat == Chats.get_chat!(chat.id) |> Repo.preload(:user)
    end

    test "create_chat/1 with valid data creates a chat" do
      chat_params =
        :chat
        |> params_for()
        |> Map.put(:id, Faker.random_between(1, 10_000))

      assert {:ok, %Chat{} = chat} = Chats.create_chat(chat_params)
      assert chat.title == chat_params.title
      assert chat.type == chat_params.type
    end

    test "create_chat/1 with invalid data returns error changeset" do
      chat = params_for(:chat, %{type: nil})
      assert {:error, %Ecto.Changeset{}} = Chats.create_chat(chat)
    end

    test "update_chat/2 with valid data updates the chat" do
      chat = insert(:chat)

      update_attrs = params_for(:chat)

      assert {:ok, %Chat{} = chat} = Chats.update_chat(chat, update_attrs)
      assert chat.title == update_attrs.title
      assert chat.type == update_attrs.type
    end

    test "update_chat/2 with invalid data returns error changeset" do
      chat = insert(:chat)
      update_attrs = %{type: nil}
      assert {:error, %Ecto.Changeset{}} = Chats.update_chat(chat, update_attrs)

      assert chat == Chats.get_chat!(chat.id) |> Repo.preload(:user)
    end

    test "delete_chat/1 deletes the chat" do
      chat = insert(:chat)
      assert {:ok, %Chat{}} = Chats.delete_chat(chat)
      assert_raise Ecto.NoResultsError, fn -> Chats.get_chat!(chat.id) end
    end

    test "change_chat/1 returns a chat changeset" do
      chat = build(:chat)
      assert %Ecto.Changeset{} = Chats.change_chat(chat)
    end
  end

  describe "messages" do
    alias Bodhi.Chats.Message

    test "list_message/0 returns all messages" do
      message = insert(:message)
      assert [^message] = Chats.list_messages() |> Repo.preload([[chat: :user], :from])
    end

    test "get_message!/1 returns the message with given id" do
      message = insert(:message)
      assert Chats.get_message!(message.id) |> Repo.preload([[chat: :user], :from]) == message
    end

    test "create_message/1 with valid data creates a message" do
      valid_attrs = params_with_assocs(:message)

      assert {:ok, %Message{} = message} = Chats.create_message(valid_attrs)
      assert message.caption == valid_attrs.caption
      assert message.date == valid_attrs.date
      assert message.text == valid_attrs.text
      assert message.user_id == valid_attrs.user_id
      assert message.chat_id == valid_attrs.chat_id
    end

    test "create_message/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} =
               Chats.create_message(params_for(:message, %{from: nil}))
    end

    test "update_message/2 with valid data updates the message" do
      message = insert(:message)

      update_attrs = params_with_assocs(:message)

      assert {:ok, %Message{} = message} = Chats.update_message(message, update_attrs)
      assert message.caption == update_attrs.caption
      assert message.date == update_attrs.date
      assert message.text == update_attrs.text
      assert message.user_id == update_attrs.user_id
      assert message.chat_id == update_attrs.chat_id
    end

    test "update_message/2 with invalid data returns error changeset" do
      message = insert(:message)
      assert {:error, %Ecto.Changeset{}} = Chats.update_message(message, %{user_id: nil})
      assert message == Chats.get_message!(message.id) |> Repo.preload([[chat: :user], :from])
    end

    test "delete_message/1 deletes the message" do
      message = insert(:message)
      assert {:ok, %Message{}} = Chats.delete_message(message)
      assert_raise Ecto.NoResultsError, fn -> Chats.get_message!(message.id) end
    end

    test "change_message/1 returns a message changeset" do
      message = insert(:message)
      assert %Ecto.Changeset{} = Chats.change_message(message)
    end
  end
end
