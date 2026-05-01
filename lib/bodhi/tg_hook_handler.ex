defmodule Bodhi.TgHookHandler do
  @moduledoc """
  Telegram webhook handler for production.
  Delegates update processing to `Bodhi.TgUpdateHandler`.
  """
  use Telegex.Hook.GenHandler

  @impl true
  @spec on_boot :: Telegex.Hook.Config.t()
  def on_boot do
    env_config =
      Application.get_env(:bodhi, __MODULE__, [])

    {:ok, true} = Telegex.delete_webhook()

    {:ok, true} =
      Telegex.set_webhook(env_config[:webhook_url],
        secret_token: env_config[:secret_token]
      )

    %Telegex.Hook.Config{
      server_port: env_config[:server_port]
    }
  end

  @impl true
  @spec on_update(Telegex.Type.Update.t()) :: :ok
  def on_update(update) do
    Bodhi.TgUpdateHandler.on_update(update)
  end
end
