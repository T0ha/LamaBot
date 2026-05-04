defmodule Bodhi.TgHookHandler do
  @moduledoc """
  Registers the Telegram webhook on application start.

  The webhook URL is derived from `BodhiWeb.Endpoint.url/0`
  combined with the Telegram webhook route. The secret
  token is read from application config. The actual HTTP
  handling is done by
  `BodhiWeb.TelegramWebhookController`.
  """
  use GenServer

  require Logger

  @webhook_path "/api/telegram/webhook"

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  @spec init(keyword()) ::
          {:ok, map()} | {:stop, {:webhook_setup_failed, term()}}
  def init(_opts) do
    config =
      Application.get_env(:bodhi, __MODULE__, [])

    webhook_url = BodhiWeb.Endpoint.url() <> @webhook_path

    with {:ok, true} <- Telegex.delete_webhook(),
         {:ok, true} <-
           Telegex.set_webhook(webhook_url,
             secret_token: config[:secret_token]
           ) do
      Logger.info("Telegram webhook registered: #{webhook_url}")

      {:ok, %{}}
    else
      error ->
        Logger.error(
          "Failed to configure Telegram webhook: " <>
            "#{inspect(error)}"
        )

        {:stop, {:webhook_setup_failed, error}}
    end
  end
end
