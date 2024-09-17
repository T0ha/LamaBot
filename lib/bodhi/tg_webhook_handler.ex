defmodule Bodhi.TgWebhookHandler do
  use Telegex.Polling.GenHandler
  alias Expo.Message
  alias Ecto.Query.Builder.Update
  alias Telegex.Type.{Message, Update, User, MessageEntity}
  alias Bodhi.Prompts.Prompt

  @impl true
  def on_boot() do
    # env_config = Application.get_env(:bodhi, __MODULE__)
    # delete the webhook and set it again
    {:ok, true} = Telegex.delete_webhook()
    # set the webhook (url is required)
    # {:ok, true} = Telegex.set_webhook(env_config[:webhook_url])
    # specify port for web server
    # port has a default value of 4000, but it may change with library upgrades
    # %Telegex.Hook.Config{server_port: env_config[:server_port]}
    %Telegex.Polling.Config{}
  end

  @impl true
  def on_update(update) do
    IO.inspect(update, pretty: true, printable_limit: :infinity, limit: :infinity)
    handle_update(update)
    :ok
  end

  defp handle_update(%Update{message: message}) when not is_nil(message) do
    handle_message(message)
  end

  defp handle_message(%Message{from: user, chat: chat, text: "/start"} = message) do
    with {:ok, user} <- Bodhi.Users.create_or_update_user(user),
      {:ok, chat} <- save_chat(chat, user),
      {:ok, _message} <- save_message(message, chat, user),
      %Prompt{text: answer} <- get_start_message(user.language_code),
      {:ok, _answer_msg} = save_answer(answer, chat) do
      Telegex.send_message(chat.id, answer)
    end

  end

  defp handle_message(%Message{from: user, chat: chat, entities: [%MessageEntity{type: "bot_command"}]} = message) do
    IO.inspect(message, pretty: true, label: "Command")
  end

  defp handle_message(%Message{from: user, chat: chat, entities: [%MessageEntity{type: "bot_command"}]} = message) do
    IO.inspect(message, pretty: true, label: "Command")
  end
  defp handle_message(%Message{from: user, chat: chat} = message) do
    with {:ok, user} <- Bodhi.Users.create_or_update_user(user),
         {:ok, chat} <- save_chat(chat, user),
         {:ok, _message} <- save_message(message, chat, user),
         messages <- Bodhi.Chats.get_chat_messages(chat),
         {:ok, answer} = Bodhi.Gemini.ask_gemini(messages),
         {:ok, _answer_msg} = save_answer(answer, chat) do
      Telegex.send_message(chat.id, answer)
    end
  end

  defp save_chat(chat, user) do
    chat
    |> Map.put(:user_id, user.id)
    |> Bodhi.Chats.maybe_create_chat()
  end

  defp save_message(message, chat, user) do
    message
    |> Map.from_struct()
    |> Map.merge(%{user_id: user.id, chat_id: chat.id})
    |> Bodhi.Chats.create_message()
  end

  defp save_answer(text, chat) do
    {:ok, %User{id: bot_id}} = Telegex.get_me()

    %{text: text, user_id: bot_id, chat_id: chat.id}
    |> Bodhi.Chats.create_message()
  end

  defp get_start_message(lang) do
    case Bodhi.Prompts.get_start_message(lang) do
      nil ->
        Bodhi.Prompts.get_start_message("en")
      prompt ->
        prompt
    end
  end
end
