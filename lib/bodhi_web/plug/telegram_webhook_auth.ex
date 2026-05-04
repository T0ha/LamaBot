defmodule BodhiWeb.Plugs.TelegramWebhookAuth do
  @moduledoc """
  Validates the secret token on Telegram webhook requests.

  Compares the value of the
  `X-Telegram-Bot-Api-Secret-Token` header against the
  `:secret_token` configured for `Bodhi.TgHookHandler`.

  When the token does not match, the request is halted with
  a 401 response and a warning is logged.
  """
  import Plug.Conn

  require Logger

  @secret_header "x-telegram-bot-api-secret-token"

  @spec init(Keyword.t()) :: Keyword.t()
  def init(opts), do: opts

  @spec call(Plug.Conn.t(), Keyword.t()) :: Plug.Conn.t()
  def call(conn, _opts) do
    if authorized?(conn, expected_token()) do
      conn
    else
      Logger.warning(
        "Unauthorized Telegram webhook request from " <>
          "`#{remote_ip(conn)}`"
      )

      conn
      |> send_resp(:unauthorized, "")
      |> halt()
    end
  end

  defp expected_token do
    :bodhi
    |> Application.get_env(Bodhi.TgHookHandler, [])
    |> Keyword.get(:secret_token)
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
