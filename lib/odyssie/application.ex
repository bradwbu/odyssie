defmodule Odyssie.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      OdyssieWeb.Telemetry,
      Odyssie.Repo,
      {DNSCluster, query: Application.get_env(:odyssie, :dns_query) || :ignore},
      {Phoenix.PubSub, name: Odyssie.PubSub},
      {Finch, name: Odyssie.Finch},
      Odyssie.Accounts.Presence,
      Odyssie.Chat.DMSubscriber,
      {Task.Supervisor, name: Odyssie.TaskSupervisor},
      OdyssieWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: Odyssie.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
