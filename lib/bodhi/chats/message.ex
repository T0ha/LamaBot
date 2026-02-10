defmodule Bodhi.Chats.Message do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  alias Bodhi.Chats.Chat
  alias Bodhi.Users.User

  @alloowed_attrs ~w(date text caption user_id chat_id)a
  @required_attrs ~w(user_id chat_id)a

  @type t() :: %__MODULE__{
          id: non_neg_integer() | nil,
          caption: String.t() | nil,
          date: non_neg_integer() | nil,
          text: String.t() | nil,
          chat_id: integer() | nil,
          user_id: integer() | nil,
          chat: Chat.t() | Ecto.Association.t() | nil,
          from: User.t() | Ecto.Association.t() | nil
        }

  schema "messages" do
    field :caption, :string
    field :date, :integer
    field :text, :string

    belongs_to :chat, Chat, on_replace: :delete
    belongs_to :from, User, foreign_key: :user_id

    timestamps()
  end

  @doc false
  @spec changeset(t(), Telegex.Type.Message.t() | map()) :: Ecto.Changeset.t()
  def changeset(message, %Telegex.Type.Message{} = data),
    do:
      data
      |> Map.from_struct()
      |> then(&changeset(message, &1))

  def changeset(message, attrs) do
    message
    |> cast(attrs, @alloowed_attrs)
    |> validate_required(@required_attrs)
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:chat_id)
  end
end
