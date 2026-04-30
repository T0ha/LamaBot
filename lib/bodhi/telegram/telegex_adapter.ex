defmodule Bodhi.Telegram.TelegexAdapter do
  @moduledoc """
  Real implementation of TelegramClient using Telegex library.
  """

  @behaviour Bodhi.Behaviours.TelegramClient

  @impl true
  def send_message(chat_id, text, opts) do
    Telegex.send_message(chat_id, text, opts)
  end

  @impl true
  def get_me do
    Telegex.get_me()
  end

  @impl true
  def send_chat_action(chat_id, action) do
    Telegex.send_chat_action(chat_id, action)
  end
end
