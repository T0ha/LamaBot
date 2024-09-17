defmodule Bodhi.Repo.Migrations.PromptsAddLang do
  use Ecto.Migration

  def change do
    alter table(:prompts) do
      add :lang, :string
    end
  end
end
