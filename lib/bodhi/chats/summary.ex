defmodule Bodhi.Chats.Summary do
  @moduledoc """
  Schema for daily message summaries.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Bodhi.Chats.Chat

  @allowed_attrs ~w(chat_id summary_text summary_date message_count start_time end_time ai_model)a
  @required_attrs ~w(chat_id summary_text summary_date)a

  @type t() :: %__MODULE__{
          id: non_neg_integer() | nil,
          chat_id: non_neg_integer() | nil,
          summary_text: String.t() | nil,
          summary_date: Date.t() | nil,
          message_count: non_neg_integer() | nil,
          start_time: NaiveDateTime.t() | nil,
          end_time: NaiveDateTime.t() | nil,
          ai_model: String.t() | nil,
          chat: Chat.t() | Ecto.Association.NotLoaded.t() | nil,
          inserted_at: NaiveDateTime.t() | nil,
          updated_at: NaiveDateTime.t() | nil
        }

  schema "message_summaries" do
    field :summary_text, :string
    field :summary_date, :date
    field :message_count, :integer, default: 0
    field :start_time, :naive_datetime
    field :end_time, :naive_datetime
    field :ai_model, :string

    belongs_to :chat, Chat

    timestamps()
  end

  @doc false
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(summary, attrs) do
    summary
    |> cast(attrs, @allowed_attrs)
    |> validate_required(@required_attrs)
    |> validate_length(:summary_text, min: 1, max: 10_000)
    |> validate_number(:message_count, greater_than_or_equal_to: 0)
    |> foreign_key_constraint(:chat_id)
    |> unique_constraint([:chat_id, :summary_date],
      name: :message_summaries_chat_id_summary_date_index
    )
  end
end
