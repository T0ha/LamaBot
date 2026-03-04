defmodule Bodhi.Repo.Migrations.AddUniqueIndexContextPrompt do
  use Ecto.Migration

  def change do
    create unique_index(:prompts, [:type],
             where: "type = 'context'",
             name: :prompts_unique_context_type_index
           )
  end
end
