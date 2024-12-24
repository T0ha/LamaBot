defmodule Bodhi.Prompts.Prompt do
  use Ecto.Schema
  import Ecto.Changeset
  @allowed_fields ~w(text type active lang)a
  @required_fields ~w(text type active lang)a

  schema "prompts" do
    field :active, :boolean, default: true
    field :type, Ecto.Enum, values: [:context, :start_message, :followup]
    field :text, :string
    field :lang, :string, default: "en"

    timestamps()
  end

  @doc false
  def changeset(prompt, attrs) do
    prompt
    |> cast(attrs, @allowed_fields)
    |> validate_required(@required_fields)
  end
end
