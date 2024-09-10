defmodule Bodhi.Repo.Migrations.CreatePrompts do
  use Ecto.Migration

  def change do
    create table(:prompts) do
      add :text, :text
      add :type, :string
      add :active, :boolean, default: false, null: false

      timestamps()
    end
  end
end
