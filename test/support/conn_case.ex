defmodule BodhiWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common data structures and query the data layer.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use BodhiWeb.ConnCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate

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
      # The default endpoint for testing
      @endpoint BodhiWeb.Endpoint

      use BodhiWeb, :verified_routes

      # Import conveniences for testing with connections
      import Plug.Conn
      import Phoenix.ConnTest
      import BodhiWeb.ConnCase
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
         get_updates: fn _ -> {:ok, []} end,
         get_me: fn -> {:ok, @bot_user} end
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
    # setup tags do
    Bodhi.DataCase.setup_sandbox(tags)
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end
end
