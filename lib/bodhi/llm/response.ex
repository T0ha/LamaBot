defmodule Bodhi.LLM.Response do
  @moduledoc """
  Plain struct representing an LLM provider's return value.

  Contains the response content along with optional metadata
  about the model used and token consumption.
  """

  @enforce_keys [:content]
  defstruct [:content, :ai_model, :prompt_tokens, :completion_tokens]

  @type t() :: %__MODULE__{
          content: String.t(),
          ai_model: String.t() | nil,
          prompt_tokens: non_neg_integer() | nil,
          completion_tokens: non_neg_integer() | nil
        }
end
