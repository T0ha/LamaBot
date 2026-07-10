defmodule BodhiWeb.TelegramWebhookControllerTest do
  use BodhiWeb.ConnCase

  @secret_header "x-telegram-bot-api-secret-token"

  setup do
    previous = Application.get_env(:bodhi, Bodhi.TgHookHandler, [])
    Application.put_env(:bodhi, Bodhi.TgHookHandler, secret_token: "s3cr3t")

    on_exit(fn ->
      Application.put_env(:bodhi, Bodhi.TgHookHandler, previous)
    end)

    :ok
  end

  test "POST /api/telegram/webhook with a valid secret returns 200", %{
    conn: conn
  } do
    conn =
      conn
      |> put_req_header(@secret_header, "s3cr3t")
      |> post("/api/telegram/webhook", %{"update_id" => 1})

    assert json_response(conn, 200) == %{}
  end

  test "POST /api/telegram/webhook with an invalid secret returns 401", %{
    conn: conn
  } do
    conn =
      conn
      |> put_req_header(@secret_header, "wrong")
      |> post("/api/telegram/webhook", %{"update_id" => 1})

    assert conn.status == 401
  end

  test "POST /api/telegram/webhook without a secret returns 401", %{
    conn: conn
  } do
    conn = post(conn, "/api/telegram/webhook", %{"update_id" => 1})

    assert conn.status == 401
  end
end
