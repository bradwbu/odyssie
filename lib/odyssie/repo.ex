defmodule Odyssie.Repo do
  use Ecto.Repo,
    otp_app: :odyssie,
    adapter: Ecto.Adapters.Postgres

  @doc """
  Dynamically loads the repository URL from the environment.
  """
  def init(_, config) do
    config =
      case System.fetch_env("DATABASE_URL") do
        {:ok, url} ->
          Keyword.put(config, :url, url)

        :error ->
          config
      end

    {:ok, config}
  end
end
