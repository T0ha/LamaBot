defmodule Bodhi.TgPollingHandler do
  @moduledoc """
  Telegram polling handler for dev/test environments.
  Delegates update processing to `Bodhi.TgUpdateHandler`.
  """
  use Telegex.Polling.GenHandler

  @impl true
  @spec on_boot :: Telegex.Polling.Config.t()
  def on_boot do
    %Telegex.Polling.Config{}
  end

  @impl true
  @spec on_update(Telegex.Type.Update.t()) :: :ok
  def on_update(update) do
    Bodhi.TgUpdateHandler.on_update(update)
  end
end
