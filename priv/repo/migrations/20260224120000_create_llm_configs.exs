defmodule Bodhi.Repo.Migrations.CreateLlmConfigs do
  use Ecto.Migration

  def change do
    create table(:llm_configs) do
      add :name, :string, null: false
      add :model, :string, null: false
      add :position, :integer, null: false, default: 0
      add :temperature, :float
      add :max_tokens, :integer
      add :active, :boolean, null: false, default: false

      timestamps()
    end

    create unique_index(:llm_configs, [:name])
    create index(:llm_configs, [:active, :position])
  end
end
