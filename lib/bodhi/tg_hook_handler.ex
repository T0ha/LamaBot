defmodule Bodhi.TgHookHandler do
  @moduledoc """
  Registers the Telegram webhook on application start.

  Reads webhook URL and secret token from application
  config, deletes any existing webhook, then sets a new
  one pointing to the Phoenix endpoint. The actual HTTP
  handling is done by
  `BodhiWeb.TelegramWebhookController`.
  """
  use GenServer

  require Logger

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

    with {:ok, true} <- Telegex.delete_webhook(),
         {:ok, true} <-
           Telegex.set_webhook(config[:webhook_url],
             secret_token: config[:secret_token]
           ) do
      Logger.info(
        "Telegram webhook registered: " <>
          "#{config[:webhook_url]}"
      )

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
