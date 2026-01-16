{:ok, _} = Application.ensure_all_started(:ex_machina)

# Define Mox mocks
Mox.defmock(Bodhi.TelegramMock, for: Bodhi.Behaviours.TelegramClient)
Mox.defmock(Bodhi.GeminiMock, for: Bodhi.Behaviours.AIClient)
Mox.defmock(Bodhi.OpenRouterMock, for: Bodhi.Behaviours.AIClient)

Ecto.Adapters.SQL.Sandbox.mode(Bodhi.Repo, :manual)
ExUnit.start()
