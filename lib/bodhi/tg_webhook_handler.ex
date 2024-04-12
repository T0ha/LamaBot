defmodule Bodhi.TgWebhookHandler do
  use Telegex.Polling.GenHandler

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
  def on_update(data) do
    IO.inspect(data)
    :ok
  end
end
