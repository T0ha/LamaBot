defmodule Bodhi.AI do
  @moduledoc """
  Adapter module for AI client operations.
  Delegates to the configured implementation (Bodhi.Gemini in prod, Mock in test).
  """

  @behaviour Bodhi.Behaviours.AIClient

  @doc """
  Asks the AI to generate a response based on message history.
  """
  @impl true
  def ask_llm(messages) do
    impl().ask_llm(messages)
  end

  defp impl do
    Application.get_env(:bodhi, :ai_client, Bodhi.Gemini)
  end
end
