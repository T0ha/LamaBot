defmodule Bodhi.Repo.Migrations.CreatePages do
  use Ecto.Migration

  def change do
    create table(:pages) do
      add :slug, :string
      add :header, :boolean, default: false, null: false
      add :title, :string
      add :description, :string
      add :format, :string
      add :content, :text
      add :template, :string, default: "page", null: false

      timestamps()
    end

    create unique_index(:pages, [:slug])
  end
end
