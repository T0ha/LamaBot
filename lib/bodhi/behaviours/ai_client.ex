defmodule Bodhi.Behaviours.AIClient do
  @moduledoc """
  Behaviour for AI client operations.
  """

  alias Bodhi.Chats.Message

  @doc """
  Asks the AI to generate a response based on message history.
  """
  @callback ask_llm([Message.t()]) :: {:ok, String.t()} | {:error, String.t()}
end
