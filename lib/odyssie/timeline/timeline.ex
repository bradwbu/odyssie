defmodule Odyssie.Timeline do
  @moduledoc """
  Aggregates timeline logic - primarily used by LiveView processes
  that subscribe to PubSub topics for real-time feed updates.
  """

  def home_topic(user_id), do: "home_timeline:#{user_id}"
  def notification_topic(user_id), do: "user:#{user_id}:notifications"
  def dm_inbox_topic(user_id), do: "user:#{user_id}:dm_inbox"
end
