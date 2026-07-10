defmodule BodhiWeb.TelegramWebhookController do
  @moduledoc """
  Receives Telegram webhook updates via Phoenix routes.

  Authentication is performed by
  `BodhiWeb.Plugs.TelegramWebhookAuth` in the router.
  This action parses the update and delegates to
  `Bodhi.TgUpdateHandler`.
  """
  use BodhiWeb, :controller

  @spec webhook(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def webhook(conn, params) do
    update =
      Telegex.Helper.typedmap(params, Telegex.Type.Update)

    Bodhi.TgUpdateHandler.on_update(update)

    json(conn, %{})
  end
end
