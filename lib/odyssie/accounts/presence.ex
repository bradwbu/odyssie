defmodule Odyssie.Accounts.Presence do
  @moduledoc """
  Tracks which users are currently online for real-time features.
  """
  use Phoenix.Presence,
    otp_app: :odyssie,
    pubsub_server: Odyssie.PubSub
end
