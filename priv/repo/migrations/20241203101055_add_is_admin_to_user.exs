defmodule Bodhi.Repo.Migrations.AddIsAdminToUser do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add_if_not_exists :is_admin, :boolean, default: false
    end
  end
end
