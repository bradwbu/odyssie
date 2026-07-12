import Config

config :odyssie,
  ecto_repos: [Odyssie.Repo],
  generators: [timestamp_type: :utc_datetime, binary_id: true]

config :odyssie, OdyssieWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Phoenix.Endpoint.Cowboy2Adapter,
  render_errors: [
    formats: [html: OdyssieWeb.ErrorHTML, json: OdyssieWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Odyssie.PubSub,
  live_view: [signing_salt: "oN3zG2pM"]

config :odyssie, :pow,
  user: Odyssie.Accounts.User,
  repo: Odyssie.Repo

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :phoenix, :json_library, Jason

import_config "#{config_env()}.exs"
