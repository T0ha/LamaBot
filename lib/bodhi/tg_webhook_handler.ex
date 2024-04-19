defmodule Bodhi.TgWebhookHandler do
  use Telegex.Polling.GenHandler
  alias Expo.Message
  alias Ecto.Query.Builder.Update
  alias Telegex.Type.{Message, Update}

  @impl true
  def on_boot() do
    #env_config = Application.get_env(:bodhi, __MODULE__)
    # delete the webhook and set it again
    {:ok, true} = Telegex.delete_webhook()
    # set the webhook (url is required)
    #{:ok, true} = Telegex.set_webhook(env_config[:webhook_url])
    # specify port for web server
    # port has a default value of 4000, but it may change with library upgrades
    #%Telegex.Hook.Config{server_port: env_config[:server_port]}
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

  defp handle_message(%Message{text: text, chat: chat}) do
    Telegex.send_message(chat.id, "Привет")
  end
end
