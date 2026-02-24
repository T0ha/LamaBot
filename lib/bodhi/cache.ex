defmodule Bodhi.Cache do
  @moduledoc """
  Local in-memory cache powered by Nebulex.

  Used for caching LLM configurations and other
  frequently accessed, rarely changing data.
  """
  use Nebulex.Cache,
    otp_app: :bodhi,
    adapter: Nebulex.Adapters.Local
end
