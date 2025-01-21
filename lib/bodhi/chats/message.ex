defmodule Bodhi.Chats.Message do
  use Ecto.Schema
  import Ecto.Changeset

  alias Bodhi.Chats.Chat
  alias Bodhi.Users.User

  @alloowed_attrs ~w(date text caption user_id chat_id)a
  # @required_attrs ~w(text)a

  schema "messages" do
    field :caption, :string
    field :date, :integer
    field :text, :string

    belongs_to :chat, Chat, on_replace: :delete
    belongs_to :from, User, foreign_key: :user_id

    timestamps()
  end

  @doc false
  def changeset(message, %Telegex.Type.Message{} = data),
    do:
      data
      |> Map.from_struct()
      |> then(&changeset(message, &1))

  def changeset(message, attrs) do
    message
    |> cast(attrs, @alloowed_attrs)
  end
end
