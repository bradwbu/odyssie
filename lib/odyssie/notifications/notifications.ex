defmodule Odyssie.Notifications do
  @moduledoc """
  The Notifications context - handles creating, querying, and managing notifications.
  """

  import Ecto.Query
  alias Odyssie.Repo
  alias Odyssie.Notifications.Notification

  def list_notifications(%User{id: user_id}, opts \\ []) do
    limit = Keyword.get(opts, :limit, 20)
    cursor = Keyword.get(opts, :cursor)
    tab = Keyword.get(opts, :tab, :all)

    base_query =
      Notification
      |> where([n], n.recipient_id == ^user_id)
      |> preload([:actor, :post])

    query =
      case tab do
        :mentions ->
          base_query |> where([n], n.type in [:mention, :reply])

        _ ->
          base_query
      end

    query =
      if cursor do
        query |> where([n], n.inserted_at < ^cursor)
      else
        query
      end

    notifications =
      query
      |> order_by([n], desc: n.inserted_at)
      |> limit(^(limit + 1))
      |> Repo.all()

    has_more = length(notifications) > limit
    notifications = Enum.take(notifications, limit)

    %{
      notifications: notifications,
      has_more: has_more,
      next_cursor: if(has_more, do: List.last(notifications).inserted_at)
    }
  end

  def mark_as_read(%User{id: user_id}) do
    now = DateTime.utc_now()

    Notification
    |> where([n], n.recipient_id == ^user_id and is_nil(n.read_at))
    |> Repo.update_all(set: [read_at: now])
  end

  def mark_notification_as_read(notification_id) do
    now = DateTime.utc_now()

    Notification
    |> where([n], n.id == ^notification_id and is_nil(n.read_at))
    |> Repo.update_all(set: [read_at: now])
  end

  def unread_count(%User{id: user_id}) do
    Notification
    |> where([n], n.recipient_id == ^user_id and is_nil(n.read_at))
    |> select([n], count(n.id))
    |> Repo.one()
  end
end
