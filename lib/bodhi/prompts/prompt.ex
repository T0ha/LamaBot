defmodule Bodhi.Prompts.Prompt do
  use Ecto.Schema
  import Ecto.Changeset

  schema "prompts" do
    field :active, :boolean, default: false
    field :type, Ecto.Enum, values: [:context, :message]
    field :text, :string

    timestamps()
  end

  @doc false
  def changeset(prompt, attrs) do
    prompt
    |> cast(attrs, [:text, :type, :active])
    |> validate_required([:text, :type, :active])
  end
end
