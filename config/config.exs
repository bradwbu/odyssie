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

config :swoosh, :api_client, Swoosh.ApiClient.Finch

config :esbuild,
  version: "0.17.18",
  default: [
    args: ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

config :tailwind,
  version: "3.4.4",
  default: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

import_config "#{config_env()}.exs"
