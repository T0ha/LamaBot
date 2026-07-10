defmodule BodhiWeb.Plugs.TelegramWebhookAuthTest do
  use ExUnit.Case, async: false

  import Plug.Conn
  import Plug.Test

  alias BodhiWeb.Plugs.TelegramWebhookAuth

  @secret_header "x-telegram-bot-api-secret-token"

  setup do
    previous = Application.get_env(:bodhi, Bodhi.TgHookHandler, [])

    on_exit(fn ->
      Application.put_env(:bodhi, Bodhi.TgHookHandler, previous)
    end)

    :ok
  end

  test "passes through when the secret token matches" do
    Application.put_env(:bodhi, Bodhi.TgHookHandler, secret_token: "s3cr3t")

    conn =
      :post
      |> conn("/api/telegram/webhook", "{}")
      |> put_req_header(@secret_header, "s3cr3t")
      |> TelegramWebhookAuth.call(TelegramWebhookAuth.init([]))

    refute conn.halted
  end

  test "halts with 401 when the secret token does not match" do
    Application.put_env(:bodhi, Bodhi.TgHookHandler, secret_token: "s3cr3t")

    conn =
      :post
      |> conn("/api/telegram/webhook", "{}")
      |> put_req_header(@secret_header, "wrong")
      |> TelegramWebhookAuth.call(TelegramWebhookAuth.init([]))

    assert conn.halted
    assert conn.status == 401
  end

  test "passes through when no token is configured and none is sent" do
    Application.put_env(:bodhi, Bodhi.TgHookHandler, [])

    conn =
      :post
      |> conn("/api/telegram/webhook", "{}")
      |> TelegramWebhookAuth.call(TelegramWebhookAuth.init([]))

    refute conn.halted
  end
end
