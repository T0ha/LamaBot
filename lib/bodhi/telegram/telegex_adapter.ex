defmodule Bodhi.Telegram.TelegexAdapter do
  @moduledoc """
  Real implementation of TelegramClient using Telegex library.
  """

  @behaviour Bodhi.Behaviours.TelegramClient

  @impl true
  def send_message(chat_id, text) do
    Telegex.send_message(chat_id, text)
  end

  @impl true
  def get_me do
    Telegex.get_me()
  end
end
