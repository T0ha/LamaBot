defmodule Bodhi.TgHookHandlerTest do
  use ExUnit.Case, async: false

  import Mox

  alias Bodhi.TgHookHandler

  setup :set_mox_global
  setup :verify_on_exit!

  describe "init/1" do
    test "registers the webhook and starts successfully" do
      expect(Bodhi.TelegramMock, :delete_webhook, fn -> {:ok, true} end)

      expect(Bodhi.TelegramMock, :set_webhook, fn _url, _opts ->
        {:ok, true}
      end)

      pid = start_supervised!(TgHookHandler)

      assert %{} = :sys.get_state(pid)
    end

    test "stops when delete_webhook fails" do
      expect(Bodhi.TelegramMock, :delete_webhook, fn ->
        {:error, %Telegex.Error{error_code: 500, description: "boom"}}
      end)

      assert {:error, {:webhook_setup_failed, _reason}} =
               start_supervised(TgHookHandler)
    end

    test "stops when set_webhook fails" do
      expect(Bodhi.TelegramMock, :delete_webhook, fn -> {:ok, true} end)

      expect(Bodhi.TelegramMock, :set_webhook, fn _url, _opts ->
        {:error, %Telegex.Error{error_code: 500, description: "boom"}}
      end)

      assert {:error, {:webhook_setup_failed, _reason}} =
               start_supervised(TgHookHandler)
    end
  end
end
