defmodule Bodhi.ObanCase do
  @moduledoc """
  This module defines the setup for tests requiring
  access to the application's data layer.

  You may define functions here to be used as helpers in
  your tests.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use Bodhi.ObanCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate

  import Mock

  using do
    quote do
      use Oban.Testing, repo: Bodhi.Repo
      import Mock

      alias Bodhi.Repo

      import Ecto
      import Ecto.Changeset
      import Ecto.Query

      import Bodhi.Factory
    end
  end

  setup_with_mocks([
    {Telegex, [:passthrough], [send_message: fn _, _ -> :ok end]},
    {Posthog, [], [capture: fn _, _ -> :ok end]}
  ],
    tags) do
    pid = Ecto.Adapters.SQL.Sandbox.start_owner!(Bodhi.Repo, shared: not tags[:async])
    on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)
    :ok
  end
end
