defmodule Bodhi.Chats.Chat do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  alias Bodhi.Users.User

  @allowed_attrs ~w(id type title)a
  @required_attrs ~w(id type)a

  @type t() :: %__MODULE__{
          id: non_neg_integer() | nil,
          type: String.t() | nil,
          title: String.t() | nil,
          user_id: non_neg_integer() | nil,
          inserted_at: NaiveDateTime.t() | nil,
          updated_at: NaiveDateTime.t() | nil,
          user: User.t() | Ecto.Association.t() | nil,
          messages: Ecto.Association.NotLoaded.t() | [Bodhi.Chats.Message.t()]
        }

  schema "chats" do
    field :title, :string
    field :type, :string

    belongs_to :user, User
    has_many :messages, Bodhi.Chats.Message

    timestamps()
  end

  @doc false
  @spec changeset(t(), Telegex.Type.Chat.t() | map()) :: Ecto.Changeset.t()
  def changeset(chat, %Telegex.Type.Chat{} = data),
    do:
      data
      |> Map.from_struct()
      |> then(&changeset(chat, &1))

  def changeset(chat, attrs) do
    chat
    |> cast(attrs, @allowed_attrs)
    |> validate_required(@required_attrs)
  end
end
