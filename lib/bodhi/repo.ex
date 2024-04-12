defmodule Bodhi.Repo do
  use Ecto.Repo,
    otp_app: :bodhi,
    adapter: Ecto.Adapters.Postgres
end
