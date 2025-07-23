defmodule Bodhi.Users.User do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  alias Bodhi.Chats.{Chat, Message}

  @allowed_attrs ~w(id first_name last_name username language_code is_admin)a
  @required_attrs ~w(id username)a

  @type t() :: %__MODULE__{
          id: non_neg_integer() | nil,
          first_name: String.t() | nil,
          last_name: String.t() | nil,
          username: String.t() | nil,
          language_code: String.t() | nil,
          is_admin: boolean(),
          chat: Chat.t() | Ecto.Association.NotLoaded.t() | nil,
          messages: [Message.t()] | Ecto.Association.NotLoaded.t(),
          inserted_at: NaiveDateTime.t() | nil,
          updated_at: NaiveDateTime.t() | nil
        }
  schema "users" do
    field :first_name, :string
    field :language_code, :string
    field :last_name, :string
    field :username, :string
    field :is_admin, :boolean, default: false

    has_one :chat, Chat
    has_many(:messages, Message)

    timestamps()
  end

  @doc false
  @spec changeset(t(), Telegex.Type.User.t() | map()) :: Ecto.Changeset.t()
  def changeset(message, %Telegex.Type.User{} = data),
    do:
      data
      |> Map.from_struct()
      |> then(&changeset(message, &1))

  def changeset(user, attrs) do
    user
    |> cast(attrs, @allowed_attrs)
    |> validate_required(@required_attrs)
  end
end
