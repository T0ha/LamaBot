defmodule Bodhi.TgPollingHandlerTest do
  use ExUnit.Case, async: true

  alias Bodhi.TgPollingHandler
  alias Telegex.Type.Update

  describe "on_boot/0" do
    test "returns a polling config" do
      assert %Telegex.Polling.Config{} = TgPollingHandler.on_boot()
    end
  end

  describe "on_update/1" do
    test "delegates to Bodhi.TgUpdateHandler" do
      update = %Update{update_id: Faker.random_bytes(100)}

      assert :ok == TgPollingHandler.on_update(update)
    end
  end
end
