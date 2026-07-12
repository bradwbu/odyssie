defmodule Odyssie.Chat.DMSubscriber do
  @moduledoc """
  GenServer that manages real-time DM subscriptions for users.
  Handles subscribing/unsubscribing to DM channels when users open/close chat windows.
  """

  use GenServer
  require Logger

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  def subscribe_to_dm(user_a_id, user_b_id) do
    channel = Odyssie.Chat.dm_channel(user_a_id, user_b_id)
    Phoenix.PubSub.subscribe(Odyssie.PubSub, channel)
    Logger.info("Subscribed to DM channel: #{channel}")
    :ok
  end

  def unsubscribe_from_dm(user_a_id, user_b_id) do
    channel = Odyssie.Chat.dm_channel(user_a_id, user_b_id)
    Phoenix.PubSub.unsubscribe(Odyssie.PubSub, channel)
    Logger.info("Unsubscribed from DM channel: #{channel}")
    :ok
  end

  def subscribe_to_dm_inbox(user_id) do
    Phoenix.PubSub.subscribe(Odyssie.PubSub, "user:#{user_id}:dm_inbox")
    :ok
  end

  @impl true
  def handle_info({:new_dm, message}, state) do
    Logger.info("DMSubscriber received new message: #{message.id}")
    {:noreply, state}
  end

  @impl true
  def handle_info(msg, state) do
    Logger.warning("DMSubscriber received unexpected message: #{inspect(msg)}")
    {:noreply, state}
  end
end
