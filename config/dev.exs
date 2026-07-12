import Config

config :odyssie, Odyssie.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "odyssie_dev",
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10
