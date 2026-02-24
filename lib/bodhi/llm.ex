defmodule Bodhi.LLM do
  @moduledoc """
  Adapter module for LLM provider operations.

  Delegates to the configured implementation
  (Bodhi.OpenRouter in prod, Mock in test).
  """

  @behaviour Bodhi.Behaviours.LLMProvider

  @doc """
  Asks the LLM to generate a response based on message
  history.
  """
  @impl true
  def ask_llm(messages) do
    impl().ask_llm(messages)
  end

  @doc """
  Fetches available models from the provider's API.
  """
  @impl true
  def fetch_models do
    impl().fetch_models()
  end

  defp impl do
    Application.get_env(:bodhi, :llm_provider, Bodhi.OpenRouter)
  end
end
