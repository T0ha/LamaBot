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

  @doc """
  Sends a chat action to a chat.

  Valid actions: "typing", "upload_photo", "record_video",
  "upload_video", "record_voice", "upload_voice",
  "upload_document", "choose_sticker",
  "find_location", "record_video_note",
  "upload_video_note".
  """
  @callback send_chat_action(
              chat_id :: integer(),
              action :: String.t()
            ) :: {:ok, boolean()} | {:error, Telegex.Type.error()}
end
