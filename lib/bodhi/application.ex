defmodule Bodhi.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  @spec start(atom(), any()) :: Supervisor.on_start()
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      BodhiWeb.Telemetry,
      # Start the Ecto repository
      Bodhi.Repo,
      {DNSCluster, query: Application.get_env(:bodhi, :dns_cluster_query) || :ignore},
      # Start the PubSub system
      {Phoenix.PubSub, name: Bodhi.PubSub},
      # Start the Endpoint (http/https)
      BodhiWeb.Endpoint,
      Bodhi.TgWebhookHandler,
      {Finch,
       name: LLM,
       pools: %{
         :default => [size: 10]
       }},
      {Oban, Application.fetch_env!(:bodhi, Oban)}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Bodhi.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @spec config_change(
          keyword(),
          keyword(),
          keyword()
        ) :: :ok
  @impl true
  def config_change(changed, _new, removed) do
    BodhiWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
