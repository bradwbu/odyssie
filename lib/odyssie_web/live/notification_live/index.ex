defmodule OdyssieWeb.NotificationLive.Index do
  @moduledoc """
  Notifications timeline LiveView with All/Mentions tabs.
  Handles real-time notification delivery via PubSub.
  """

  use OdyssieWeb, :live_view
  alias Odyssie.Notifications

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(
        Odyssie.PubSub,
        "user:#{socket.assigns.current_user.id}:notifications"
      )
    end

    notifications = Notifications.list_notifications(socket.assigns.current_user, tab: :all)

    {:ok,
     socket
     |> assign(:notifications, notifications)
     |> assign(:active_tab, :all)
     |> assign(:unread_notifications, Notifications.unread_count(socket.assigns.current_user)),
     temporary_assigns: [notifications: []]}
  end

  @impl true
  def handle_params(%{"tab" => tab}, _uri, socket) do
    tab = String.to_existing_atom(tab)

    notifications = Notifications.list_notifications(socket.assigns.current_user, tab: tab)

    {:noreply,
     socket
     |> assign(:active_tab, tab)
     |> assign(:notifications, notifications)}
  end

  def handle_params(_params, _uri, socket) do
    {:noreply, socket}
  end

  # ── Events ───────────────────────────────────────────────────────────

  @impl true
  def handle_event("switch_tab", %{"tab" => tab}, socket) do
    tab = String.to_existing_atom(tab)

    notifications = Notifications.list_notifications(socket.assigns.current_user, tab: tab)

    {:noreply,
     socket
     |> assign(:active_tab, tab)
     |> assign(:notifications, notifications)}
  end

  def handle_event("mark_all_read", _params, socket) do
    Notifications.mark_as_read(socket.assigns.current_user)

    {:noreply,
     socket
     |> assign(:unread_notifications, 0)}
  end

  def handle_event("navigate_user", %{"username" => username}, socket) do
    {:noreply, push_navigate(socket, to: "/#{username}")}
  end

  def handle_event("navigate_post", %{"id" => post_id}, socket) do
    {:noreply, push_navigate(socket, to: "/post/#{post_id}")}
  end

  # ── PubSub ───────────────────────────────────────────────────────────

  @impl true
  def handle_info({:new_notification, _type, _actor_id, _post_id}, socket) do
    notifications = Notifications.list_notifications(socket.assigns.current_user, tab: socket.assigns.active_tab)

    {:noreply,
     socket
     |> assign(:notifications, notifications)
     |> assign(:unread_notifications, Notifications.unread_count(socket.assigns.current_user))}
  end

  def handle_info(_, socket), do: {:noreply, socket}

  # ── Helpers ──────────────────────────────────────────────────────────

  defp notification_icon(:like), do: "❤️"
  defp notification_icon(:repost), do: "🔁"
  defp notification_icon(:follow), do: "👤"
  defp notification_icon(:mention), do: "@"
  defp notification_icon(:reply), do: "💬"

  defp notification_text(:like, actor), do: "#{actor.display_name || actor.username} liked your post"
  defp notification_text(:repost, actor), do: "#{actor.display_name || actor.username} reposted your post"
  defp notification_text(:follow, actor), do: "#{actor.display_name || actor.username} followed you"
  defp notification_text(:mention, actor), do: "#{actor.display_name || actor.username} mentioned you"
  defp notification_text(:reply, actor), do: "#{actor.display_name || actor.username} replied to your post"

  # ── Render ───────────────────────────────────────────────────────────

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-col min-h-screen">
      <header class="sticky top-0 bg-white bg-opacity-90 backdrop-blur-md z-40 border-b border-gray-200">
        <div class="flex items-center justify-between px-4 py-3">
          <h1 class="text-xl font-bold">Notifications</h1>
          <%= if @unread_notifications > 0 do %>
            <button class="text-blue-500 text-sm hover:underline"
                    phx-click="mark_all_read">
              Mark all as read
            </button>
          <% end %>
        </div>

        <div class="flex">
          <button class={"flex-1 text-center py-3 text-sm font-medium border-b-2 #{if @active_tab == :all, do: "border-blue-500 text-blue-500", else: "border-transparent text-gray-500 hover:bg-gray-50"}"}
                  phx-click="switch_tab" phx-value-tab="all">
            All
          </button>
          <button class={"flex-1 text-center py-3 text-sm font-medium border-b-2 #{if @active_tab == :mentions, do: "border-blue-500 text-blue-500", else: "border-transparent text-gray-500 hover:bg-gray-50"}"}
                  phx-click="switch_tab" phx-value-tab="mentions">
            Mentions
          </button>
        </div>
      </header>

      <div id="notifications-list">
        <%= if @notifications.notifications == [] do %>
          <div class="p-8 text-center">
            <h2 class="text-2xl font-extrabold mb-2">Nothing to see here — yet</h2>
            <p class="text-gray-500">
              <%= if @active_tab == :all do %>
                From likes to reposts and a whole lot more, this is where all the action happens.
              <% else %>
                When someone mentions you, you'll find it here.
              <% end %>
            </p>
          </div>
        <% else %>
          <%= for notification <- @notifications.notifications do %>
            <div class={"flex px-4 py-3 border-b border-gray-100 hover:bg-gray-50 cursor-pointer #{if is_nil(notification.read_at), do: "bg-blue-50"}"}
                 phx-click="navigate_post"
                 phx-value-id={notification.post_id || ""}>
              <div class="mr-3 mt-1 text-lg">
                <%= notification_icon(notification.type) %>
              </div>
              <div class="flex-1">
                <div class="flex items-center mb-1">
                  <img src={notification.actor.avatar_url || "/images/default-avatar.png"}
                       class="w-8 h-8 rounded-full mr-2"
                       phx-click="navigate_user"
                       phx-value-username={notification.actor.username} />
                  <%= if notification.actor.is_verified do %>
                    <.verified_badge />
                  <% end %>
                </div>
                <p class="text-gray-900 text-sm">
                  <span class="font-bold"
                        phx-click="navigate_user"
                        phx-value-username={notification.actor.username}>
                    <%= notification.actor.display_name || notification.actor.username %>
                  </span>
                  <%= notification_text(notification.type, notification.actor) %>
                </p>
                <%= if notification.post do %>
                  <p class="text-gray-500 text-sm mt-1 line-clamp-2">
                    <%= notification.post.content %>
                  </p>
                <% end %>
                <p class="text-gray-400 text-xs mt-1">
                  <%= OdyssieWeb.CoreComponents.format_time(notification.inserted_at) %>
                </p>
              </div>
            </div>
          <% end %>
        <% end %>
      </div>
    </div>
    """
  end
end
