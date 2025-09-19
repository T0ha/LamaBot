# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :bodhi,
  ecto_repos: [Bodhi.Repo]

# Configures the endpoint
config :bodhi, BodhiWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: BodhiWeb.ErrorHTML, json: BodhiWeb.ErrorJSON],
    accepts: ~w(html json),
    layout: false
  ],
  pubsub_server: Bodhi.PubSub,
  live_view: [signing_salt: "+SFVCX2q"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :bodhi, Bodhi.Mailer, adapter: Swoosh.Adapters.Local

# Swoosh API client is needed for adapters other than SMTP.
config :swoosh, :api_client, false

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.25.4",
  bodhi: [
    args:
      ~w(js/app.js --bundle --target=es2022 --outdir=../priv/static/assets/js --external:/fonts/* --external:/images/* --alias:@=.),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => [Path.expand("../deps", __DIR__), Mix.Project.build_path()]}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "4.1.7",
  bodhi: [
    args: ~w(
      --input=assets/css/app.css
      --output=priv/static/assets/css/app.css
    ),
    cd: Path.expand("..", __DIR__)
  ]


# Configures Elixir's Logger
config :logger, :console,
  format: "$metadata[$level] $time $message\n",
  metadata: [:request_id, :level]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.

config :telegex,
  caller_adapter: Finch,
  hook_adapter: Bandit

config :bodhi, Oban,
  engine: Oban.Engines.Basic,
  queues: [default: 10, messages: 10],
  repo: Bodhi.Repo

config :posthog,
  api_url: "https://eu.i.posthog.com"

import_config "#{config_env()}.exs"
