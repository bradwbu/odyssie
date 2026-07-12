defmodule Odyssie.Chat do
  @moduledoc """
  The Chat context - handles DMs and conversations.
  """

  import Ecto.Query
  alias Odyssie.Repo
  alias Odyssie.Chat.Message
  alias Odyssie.Accounts.User

  # ── Sending Messages ─────────────────────────────────────────────────

  def send_message(%User{id: sender_id}, %User{id: recipient_id}, body) do
    if sender_id == recipient_id do
      {:error, :cannot_message_self}
    else
      result =
        %Message{}
        |> Message.changeset(%{
          sender_id: sender_id,
          recipient_id: recipient_id,
          body: body
        })
        |> Repo.insert()

      case result do
        {:ok, message} ->
          message = Repo.preload(message, [:sender, :recipient])

          broadcast_new_message(message)
          {:ok, message}

        error ->
          error
      end
    end
  end

  # ── Conversations ────────────────────────────────────────────────────

  def list_conversations(%User{id: user_id}) do
    # Get distinct conversation partners ordered by most recent message
    Message
    |> where([m], m.sender_id == ^user_id or m.recipient_id == ^user_id)
    |> order_by([m], desc: m.inserted_at)
    |> distinct([m],
      fragment(
        "CASE WHEN ? = ? THEN ? ELSE ? END",
        m.sender_id,
        ^user_id,
        m.recipient_id,
        m.sender_id
      )
    )
    |> select([m], %{
      user_id:
        fragment(
          "CASE WHEN ? = ? THEN ? ELSE ? END",
          m.sender_id,
          ^user_id,
          m.recipient_id,
          m.sender_id
        ),
      last_message_at: max(m.inserted_at),
      last_message_body: fragment(
        "(SELECT body FROM messages WHERE ((sender_id = ? AND recipient_id = ?) OR (sender_id = ? AND recipient_id = ?)) ORDER BY inserted_at DESC LIMIT 1)",
        m.sender_id,
        m.recipient_id,
        m.recipient_id,
        m.sender_id
      ),
      unread_count: fragment(
        "COUNT(CASE WHEN ? = ? AND ? IS NULL THEN 1 END)",
        m.recipient_id,
        ^user_id,
        m.read_at
      )
    })
    |> group_by([m],
      fragment(
        "CASE WHEN ? = ? THEN ? ELSE ? END",
        m.sender_id,
        ^user_id,
        m.recipient_id,
        m.sender_id
      )
    )
    |> order_by([m], desc: max(m.inserted_at))
    |> Repo.all()
    |> Enum.map(fn conv ->
      user = Repo.get!(User, conv.user_id)

      %{
        user: user,
        last_message: %{
          body: conv.last_message_body,
          inserted_at: conv.last_message_at
        },
        unread_count: conv.unread_count
      }
    end)
  end

  # ── Conversation Thread ──────────────────────────────────────────────

  def get_conversation(%User{id: user_id}, other_user_id, opts \\ []) do
    limit = Keyword.get(opts, :limit, 50)
    before_cursor = Keyword.get(opts, :before])

    query =
      Message
      |> where([m],
        (m.sender_id == ^user_id and m.recipient_id == ^other_user_id) or
          (m.sender_id == ^other_user_id and m.recipient_id == ^user_id)
      )

    query =
      if before_cursor do
        query |> where([m], m.inserted_at < ^before_cursor)
      else
        query
      end

    messages =
      query
      |> order_by([m], desc: m.inserted_at)
      |> limit(^limit)
      |> preload([:sender, :recipient])
      |> Repo.all()
      |> Enum.reverse()

    has_more = length(messages) >= limit

    %{
      messages: messages,
      has_more: has_more,
      next_cursor: if(has_more, do: List.first(messages).inserted_at)
    }
  end

  # ── Mark as Read ─────────────────────────────────────────────────────

  def mark_as_read(%User{id: user_id}, other_user_id) do
    now = DateTime.utc_now()

    Message
    |> where([m],
      m.sender_id == ^other_user_id and
        m.recipient_id == ^user_id and
        is_nil(m.read_at)
    )
    |> Repo.update_all(set: [read_at: now])
  end

  def unread_count(%User{id: user_id}) do
    Message
    |> where([m], m.recipient_id == ^user_id and is_nil(m.read_at))
    |> select([m], count(m.id))
    |> Repo.one()
  end

  def unread_count_with(%User{id: user_id}, other_user_id) do
    Message
    |> where([m],
      m.sender_id == ^other_user_id and
        m.recipient_id == ^user_id and
        is_nil(m.read_at)
    )
    |> select([m], count(m.id))
    |> Repo.one()
  end

  # ── PubSub Broadcast ─────────────────────────────────────────────────

  defp broadcast_new_message(%Message{sender_id: sender_id, recipient_id: recipient_id} = message) do
    channel = dm_channel(sender_id, recipient_id)

    Phoenix.PubSub.broadcast(
      Odyssie.PubSub,
      channel,
      {:new_dm, message}
    )

    Phoenix.PubSub.broadcast(
      Odyssie.PubSub,
      "user:#{recipient_id}:dm_inbox",
      {:dm_inbox_update, message}
    )
  end

  def dm_channel(user_a, user_b) do
    [first, second] = Enum.sort([user_a, user_b])
    "dm:#{first}:#{second}"
  end
end
