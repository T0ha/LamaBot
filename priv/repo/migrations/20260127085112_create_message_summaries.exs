defmodule Bodhi.Repo.Migrations.CreateMessageSummaries do
  use Ecto.Migration

  def change do
    create table(:message_summaries) do
      add :chat_id, references(:chats, on_delete: :delete_all), null: false
      add :summary_text, :text, null: false
      add :summary_date, :date, null: false
      add :message_count, :integer, null: false, default: 0
      add :start_time, :naive_datetime
      add :end_time, :naive_datetime
      add :ai_model, :string

      timestamps()
    end

    create unique_index(:message_summaries, [:chat_id, :summary_date])
    create index(:message_summaries, [:chat_id])
    create index(:message_summaries, [:summary_date])
  end
end
