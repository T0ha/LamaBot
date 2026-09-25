defmodule Bodhi.Repo.Migrations.EnforceSingleActiveLlmConfig do
  use Ecto.Migration

  def up do
    execute """
    UPDATE llm_configs
    SET active = false
    WHERE active = true
      AND id NOT IN (
        SELECT id FROM llm_configs
        WHERE active = true
        ORDER BY position ASC, id ASC
        LIMIT 1
      )
    """

    create unique_index(:llm_configs, [:active],
             where: "active = true",
             name: :llm_configs_one_active_index
           )
  end

  def down do
    drop_if_exists index(:llm_configs, [:active], name: :llm_configs_one_active_index)
  end
end
