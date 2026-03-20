defmodule Bodhi.Prompts.PromptVersion do
  @moduledoc """
  Read-only schema for prompt history entries created by
  the PostgreSQL temporal_tables versioning trigger.
  """

  use Ecto.Schema

  @primary_key false

  @type t() :: %__MODULE__{
          id: non_neg_integer(),
          text: String.t() | nil,
          type: :context | :start_message | :followup | nil,
          active: boolean(),
          lang: String.t(),
          version: pos_integer(),
          changed_by: non_neg_integer() | nil,
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t(),
          valid_from: DateTime.t() | nil,
          valid_to: DateTime.t() | nil
        }

  schema "prompts_history" do
    field :id, :integer
    field :text, :string
    field :type, Ecto.Enum, values: [:context, :start_message, :followup]
    field :active, :boolean
    field :lang, :string
    field :version, :integer
    field :changed_by, :integer

    field :valid_from, :utc_datetime, virtual: true
    field :valid_to, :utc_datetime, virtual: true

    timestamps()
  end
end
