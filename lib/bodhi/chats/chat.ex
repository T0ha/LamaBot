defmodule Bodhi.Chats.Chat do
  use Ecto.Schema
  import Ecto.Changeset

  alias Bodhi.Users.User

  @allowed_attrs ~w(id type title)a
  @required_attrs ~w(id type)a

  schema "chats" do
    field :title, :string
    field :type, :string

    belongs_to :user, User

    timestamps()
  end

  @doc false
  def changeset(chat, %Telegex.Type.Chat{} = data), do:
      data
      |> Map.from_struct()
      |> then(&changeset(chat, &1))

  def changeset(chat, attrs) do
    chat
    |> cast(attrs, @allowed_attrs)
    |> validate_required(@required_attrs)
  end
end
