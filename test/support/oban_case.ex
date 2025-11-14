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

  import Bodhi.Factory
  import Mock

  @bot_user %Telegex.Type.User{
    id: Faker.random_between(1, 1000),
    first_name: Faker.Person.first_name(),
    last_name: Faker.Person.last_name(),
    username: Faker.Internet.user_name(),
    is_bot: true
  }
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

  setup_with_mocks(
    [
      {Telegex, [],
       [
         send_message: fn chat_id, text ->
           {:ok,
            %Telegex.Type.Message{
              from: @bot_user,
              chat: %Telegex.Type.Chat{
                id: chat_id,
                type: "private"
              },
              date: DateTime.utc_now() |> DateTime.to_unix(),
              message_id: Faker.random_between(1, 1000),
              text: text
            }}
         end,
         get_updates: fn _ -> {:ok, []} end
       ]},
      {PostHog, [], [capture: fn _, _ -> :ok end]},
      {Bodhi.Gemini, [],
       [
         ask_gemini: fn _ ->
           {:ok, Faker.Lorem.paragraph()}
         end
       ]}
    ],
    tags
  ) do
    pid =
      Ecto.Adapters.SQL.Sandbox.start_owner!(Bodhi.Repo, shared: not tags[:async])

    Bodhi.Users.create_or_update_user(@bot_user)
    chat = insert(:chat)

    on_exit(fn ->
      Ecto.Adapters.SQL.Sandbox.stop_owner(pid)
    end)

    {:ok, %{chat: chat}}
  end
end
