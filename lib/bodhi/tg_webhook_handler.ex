defmodule Bodhi.TgWebhookHandler do
  use Telegex.Polling.GenHandler
  alias Ecto.Query.Builder.Update
  alias Telegex.Type.{Message, Update, User, MessageEntity}
  alias Bodhi.Prompts.Prompt

  @impl true
  def on_boot() do
    # env_config = Application.get_env(:bodhi, __MODULE__)
    # delete the webhook and set it again
    {:ok, true} = Telegex.delete_webhook()
    #{:ok, bot_user} = Telegex.get_me()
    #Bodhi.Users.create_or_update_user(bot_user)
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

  defp handle_message(%Message{text: "/login", entities: _entities, from: user, chat: chat}) do
    with db_user <- Bodhi.Users.get_user!(user.id),
      true <- db_user.is_admin,
      token <- Phoenix.Token.sign(BodhiWeb.Endpoint, "user auth", db_user.id),
      url <- BodhiWeb.Router.Helpers.auth_url(BodhiWeb.Endpoint, :login, [token: token]) 
    do
      Telegex.send_message(chat.id, url)
    else
      _ ->
        :ok
    end
  end

  defp handle_message(%Message{text: "/" <> _, entities: entities} = message) when entities != [] do
    handle_message(%{message | entities: []})
  end

  defp handle_message(%Message{ entities: [%MessageEntity{type: "bot_command"}]} = message) do
    IO.inspect(message, pretty: true, label: "Command")
  end

  defp handle_message(%Message{from: user, chat: chat} = message) do
    with {:ok, user} <- Bodhi.Users.create_or_update_user(user),
         {:ok, chat} <- save_chat(chat, user),
         {:ok, message} <- save_message(message, chat.id, user),
         {:ok, answer} = get_answer(message, user.language_code),
         {:ok, _answer_msg} = send_message(chat.id, answer) do
      Bodhi.PeriodicMessages.create_for_new_user(:followup, {1, :days}, chat.id)
      Posthog.capture("message_handled", 
        distinct_id: user.id,
        properties: %{
          locale: user.language_code,
          host: BodhiWeb.Endpoint.host()
        })
      :ok
    end
  end

  def send_message(chat_id, text) do
    with {:ok, message} <- Telegex.send_message(chat_id, text),
      {:ok, msg} <- save_message(message, chat_id, message.from) do
      {:ok, msg}
    end
  end

  defp save_chat(chat, user) do
    chat
    |> Map.put(:user_id, user.id)
    |> Bodhi.Chats.maybe_create_chat()
  end

  defp save_message(message, chat_id, user) do
    message
    |> Map.from_struct()
    |> Map.merge(%{user_id: user.id, chat_id: chat_id})
    |> Bodhi.Chats.create_message()
  end

  defp get_answer(%_{chat_id: _chat_id, text: "/start"}, lang) do
    %Prompt{text: answer} = get_start_message(lang)
    {:ok, answer}
  end

  defp get_answer(%_{chat_id: chat_id}, _) do
    messages = Bodhi.Chats.get_chat_messages(chat_id)
    {:ok, _answer} = Bodhi.Gemini.ask_gemini(messages)
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
