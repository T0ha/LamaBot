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
  import Mox

  using do
    quote do
      use Oban.Testing, repo: Bodhi.Repo
      import Mox

      alias Bodhi.Repo

      import Ecto
      import Ecto.Changeset
      import Ecto.Query

      import Bodhi.Factory

      setup :verify_on_exit!
    end
  end

  setup :verify_on_exit!

  setup tags do
    pid = Ecto.Adapters.SQL.Sandbox.start_owner!(Bodhi.Repo, shared: not tags[:async])

    # Create bot user with consistent ID
    bot_user = %Telegex.Type.User{
      id: Faker.random_between(1, 1000),
      first_name: Faker.Person.first_name(),
      last_name: Faker.Person.last_name(),
      username: Faker.Internet.user_name(),
      is_bot: true
    }

    # Create the bot user in the database
    {:ok, db_bot_user} = Bodhi.Users.create_or_update_user(bot_user)

    # Set up default stubs for Telegram mock - use the DB user's ID
    Bodhi.TelegramMock
    |> stub(:send_message, fn chat_id, text ->
      {:ok,
       %Telegex.Type.Message{
         from: %Telegex.Type.User{
           id: db_bot_user.id,
           first_name: db_bot_user.first_name,
           last_name: db_bot_user.last_name,
           username: db_bot_user.username,
           is_bot: true
         },
         chat: %Telegex.Type.Chat{
           id: chat_id,
           type: "private"
         },
         date: DateTime.utc_now() |> DateTime.to_unix(),
         message_id: Faker.random_between(1, 1000),
         text: text
       }}
    end)
    |> stub(:get_me, fn ->
      {:ok,
       %Telegex.Type.User{
         id: db_bot_user.id,
         first_name: db_bot_user.first_name,
         last_name: db_bot_user.last_name,
         username: db_bot_user.username,
         is_bot: true
       }}
    end)

    # Set up default stub for Gemini mock
    Bodhi.GeminiMock
    |> stub(:ask_gemini, fn _ ->
      {:ok, Faker.Lorem.paragraph()}
    end)

    chat = insert(:chat)

    on_exit(fn ->
      Ecto.Adapters.SQL.Sandbox.stop_owner(pid)
    end)

    {:ok, %{chat: chat, bot_user: db_bot_user}}
  end
end
