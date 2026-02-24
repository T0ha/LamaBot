defmodule Bodhi.Behaviours.LLMProvider do
  @moduledoc """
  Behaviour for LLM provider operations.
  """

  alias Bodhi.Chats.Message
  alias Bodhi.LLM.Response

  @doc """
  Asks the LLM to generate a response based on message
  history.
  """
  @callback ask_llm([Message.t()]) ::
              {:ok, Response.t()} | {:error, String.t()}

  @doc """
  Fetches available models from the provider's API.
  """
  @callback fetch_models() ::
              {:ok, [map()]} | {:error, String.t()}
end
