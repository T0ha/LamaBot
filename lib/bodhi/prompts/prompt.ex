defmodule Bodhi.Prompts.Prompt do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset
  @allowed_fields ~w(text type active lang)a
  @required_fields ~w(text type active lang)a

  @type type() :: :context | :start_message | :followup

  @type t() :: %__MODULE__{
          id: non_neg_integer() | nil,
          active: boolean(),
          type: type() | nil,
          text: String.t() | nil,
          lang: String.t(),
          inserted_at: NaiveDateTime.t() | nil,
          updated_at: NaiveDateTime.t() | nil
        }

  schema "prompts" do
    field :active, :boolean, default: true
    field :type, Ecto.Enum, values: [:context, :start_message, :followup]
    field :text, :string
    field :lang, :string, default: "en"

    timestamps()
  end

  @doc false
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(prompt, attrs) do
    prompt
    |> cast(attrs, @allowed_fields)
    |> validate_required(@required_fields)
  end
end
