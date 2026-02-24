defmodule Bodhi.Repo.Migrations.AddUniqueModelIndex do
  use Ecto.Migration

  def change do
    create unique_index(:llm_configs, [:model])
  end
end
