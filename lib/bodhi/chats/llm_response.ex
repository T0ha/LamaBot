defmodule Bodhi.Chats.LlmResponse do
  @moduledoc """
  Schema for persisted LLM response metadata.

  Stores which model handled the request and token usage
  for cost tracking and observability.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Bodhi.Chats.Message

  @allowed_attrs ~w(ai_model prompt_tokens completion_tokens)a

  @type t() :: %__MODULE__{
          id: non_neg_integer() | nil,
          ai_model: String.t() | nil,
          prompt_tokens: non_neg_integer() | nil,
          completion_tokens: non_neg_integer() | nil,
          message: Message.t() | Ecto.Association.NotLoaded.t() | nil
        }

  schema "llm_responses" do
    field :ai_model, :string
    field :prompt_tokens, :integer
    field :completion_tokens, :integer
    has_one :message, Message
    timestamps()
  end

  @doc false
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(llm_response, attrs) do
    llm_response
    |> cast(attrs, @allowed_attrs)
  end
end
