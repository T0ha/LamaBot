defmodule Bodhi.Telegram do
  @moduledoc """
  Adapter module for Telegram API operations.
  Delegates to the configured implementation (Telegex in prod, Mock in test).
  """

  @behaviour Bodhi.Behaviours.TelegramClient

  @doc """
  Sends a text message to a chat.
  """
  @impl true
  def send_message(chat_id, text) do
    impl().send_message(chat_id, text)
  end

  @doc """
  Gets information about the bot.
  """
  @impl true
  def get_me do
    impl().get_me()
  end

  defp impl do
    Application.get_env(:bodhi, :telegram_client, Bodhi.Telegram.TelegexAdapter)
  end
end
