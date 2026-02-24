defmodule Bodhi.LlmConfigs.LlmConfig do
  @moduledoc """
  Schema for LLM model configurations.

  Each config represents a model that can be used via
  OpenRouter. Multiple configs can be active simultaneously
  -- their `position` determines fallback order (lower =
  higher priority). Active configs are sent as OpenRouter's
  `models` array with `route: "fallback"`.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @allowed_fields ~w(
    name model position temperature max_tokens active
  )a

  @required_fields ~w(name model position)a

  @type t() :: %__MODULE__{
          id: non_neg_integer() | nil,
          name: String.t() | nil,
          model: String.t() | nil,
          position: non_neg_integer(),
          temperature: float() | nil,
          max_tokens: non_neg_integer() | nil,
          active: boolean(),
          inserted_at: NaiveDateTime.t() | nil,
          updated_at: NaiveDateTime.t() | nil
        }

  schema "llm_configs" do
    field :name, :string
    field :model, :string
    field :position, :integer, default: 0
    field :temperature, :float
    field :max_tokens, :integer
    field :active, :boolean, default: false

    timestamps()
  end

  @doc false
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(llm_config, attrs) do
    llm_config
    |> cast(attrs, @allowed_fields)
    |> validate_required(@required_fields)
    |> validate_number(:temperature,
      greater_than_or_equal_to: 0.0,
      less_than_or_equal_to: 2.0
    )
    |> validate_number(:max_tokens,
      greater_than_or_equal_to: 1,
      less_than_or_equal_to: 128_000
    )
    |> unique_constraint(:name)
    |> unique_constraint(:model)
  end
end
