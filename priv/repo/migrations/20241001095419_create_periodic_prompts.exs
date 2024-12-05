defmodule Bodhi.Repo.Migrations.CreatePeriodicPrompts do
  use Ecto.Migration

  def change do
    create table(:periodic_prompts) do
      add :prompt_type, :string
      add :date, :date
      add :time, :time
      add :timezone, :integer
      add :active, :boolean, default: false, null: false

      timestamps()
    end
  end
end
