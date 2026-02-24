defmodule Bodhi.Repo.Migrations.CreateLlmResponsesAndLinkMessages do
  use Ecto.Migration

  def change do
    create table(:llm_responses) do
      add :ai_model, :string
      add :prompt_tokens, :integer
      add :completion_tokens, :integer
      timestamps()
    end

    alter table(:messages) do
      add :llm_response_id,
          references(:llm_responses, on_delete: :nilify_all)
    end

    create index(:messages, [:llm_response_id])
  end
end
