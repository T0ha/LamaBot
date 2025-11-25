defmodule Bodhi.Behaviours.TelegramClient do
  @moduledoc """
  Behaviour for Telegram API client operations.
  """

  @doc """
  Sends a text message to a chat.
  """
  @callback send_message(chat_id :: integer(), text :: String.t()) ::
              {:ok, Telegex.Type.Message.t()} | {:error, Telegex.Type.error()}

  @doc """
  Gets information about the bot.
  """
  @callback get_me() :: {:ok, Telegex.Type.User.t()} | {:error, Telegex.Type.error()}
end
