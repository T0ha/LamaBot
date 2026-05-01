defmodule BodhiWeb.TelegramWebhookController do
  @moduledoc """
  Receives Telegram webhook updates via Phoenix routes.

  Validates the secret token from the
  `X-Telegram-Bot-Api-Secret-Token` header, parses the
  update, and delegates to `Bodhi.TgUpdateHandler`.
  """
  use BodhiWeb, :controller

  require Logger

  @secret_header "x-telegram-bot-api-secret-token"

  @spec webhook(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def webhook(conn, params) do
    config =
      Application.get_env(:bodhi, Bodhi.TgHookHandler, [])

    if authorized?(conn, config[:secret_token]) do
      update =
        Telegex.Helper.typedmap(
          params,
          Telegex.Type.Update
        )

      Task.start(fn ->
        Bodhi.TgUpdateHandler.on_update(update)
      end)
    else
      Logger.warning(
        "Unauthorized webhook request from " <>
          "`#{remote_ip(conn)}`"
      )
    end

    json(conn, %{})
  end

  defp authorized?(conn, secret_token) do
    case get_req_header(conn, @secret_header) do
      [] -> is_nil(secret_token)
      tokens -> List.last(tokens) == secret_token
    end
  end

  defp remote_ip(%{remote_ip: ip_tuple})
       when not is_nil(ip_tuple) do
    :inet.ntoa(ip_tuple)
  end

  defp remote_ip(_conn), do: "[unknown_ip]"
end
