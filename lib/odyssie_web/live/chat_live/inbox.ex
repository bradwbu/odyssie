defmodule OdyssieWeb.ChatLive.Inbox do
  @moduledoc """
  DM Inbox LiveView - lists all active conversations with unread badges.
  Subscribes to PubSub for real-time inbox updates.
  """

  use OdyssieWeb, :live_view
  alias Odyssie.Chat

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Chat.DMSubscriber.subscribe_to_dm_inbox(socket.assigns.current_user.id)
    end

    conversations = Chat.list_conversations(socket.assigns.current_user)

    {:ok,
     socket
     |> assign(:conversations, conversations)}
  end

  @impl true
  def handle_event("open_conversation", %{"user_id" => user_id}, socket) do
    {:noreply, push_navigate(socket, to: "/messages/#{user_id}")}
  end

  # ── PubSub ───────────────────────────────────────────────────────────

  @impl true
  def handle_info({:dm_inbox_update, message}, socket) do
    conversations = Chat.list_conversations(socket.assigns.current_user)

    {:noreply,
     socket
     |> assign(:conversations, conversations)
     |> assign(:unread_messages, Chat.unread_count(socket.assigns.current_user))}
  end

  def handle_info(_, socket), do: {:noreply, socket}

  # ── Render ───────────────────────────────────────────────────────────

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-col min-h-screen">
      <header class="sticky top-0 bg-white bg-opacity-90 backdrop-blur-md z-40 border-b border-gray-200 px-4 py-3">
        <div class="flex items-center justify-between">
          <h1 class="text-xl font-bold">Messages</h1>
          <button class="p-2 hover:bg-gray-100 rounded-full text-gray-500">
            <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"/>
            </svg>
          </button>
        </div>
      </header>

      <%!-- Search --%>
      <div class="px-4 py-2 border-b border-gray-200">
        <div class="relative">
          <svg class="w-4 h-4 absolute left-3 top-3 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"/>
          </svg>
          <input type="text" placeholder="Search Direct Messages"
                 class="w-full bg-gray-100 rounded-full py-2 pl-10 pr-4 text-sm border border-transparent focus:border-blue-500 focus:bg-white focus:outline-none" />
        </div>
      </div>

      <%!-- Conversations List --%>
      <div class="flex-1 overflow-y-auto">
        <%= if @conversations == [] do %>
          <div class="p-8 text-center">
            <h2 class="text-2xl font-extrabold mb-2">Welcome to your inbox!</h2>
            <p class="text-gray-500 mb-4">
              Drop a line, share posts and more with private conversations between you and others on Odyssie.
            </p>
            <button class="bg-blue-500 hover:bg-blue-600 text-white font-bold py-3 px-6 rounded-full">
              Write a message
            </button>
          </div>
        <% else %>
          <%= for conv <- @conversations do %>
            <button class="w-full flex items-center p-4 hover:bg-gray-50 border-b border-gray-100 text-left"
                    phx-click="open_conversation"
                    phx-value-id={conv.user.id}>
              <div class="relative flex-shrink-0">
                <img src={conv.user.avatar_url || "/images/default-avatar.png"}
                     class="w-12 h-12 rounded-full" />
              </div>
              <div class="ml-3 flex-1 min-w-0">
                <div class="flex items-center justify-between">
                  <div class="flex items-center space-x-1 min-w-0">
                    <span class="font-bold text-sm truncate">
                      <%= conv.user.display_name || conv.user.username %>
                    </span>
                    <%= if conv.user.is_verified do %>
                      <.verified_badge />
                    <% end %>
                    <span class="text-gray-500 text-sm truncate">@<%= conv.user.username %></span>
                  </div>
                  <span class="text-gray-500 text-xs flex-shrink-0 ml-2">
                    <%= OdyssieWeb.CoreComponents.format_time(conv.last_message.inserted_at) %>
                  </span>
                </div>
                <div class="flex items-center justify-between mt-1">
                  <p class="text-gray-500 text-sm truncate">
                    <%= conv.last_message.body %>
                  </p>
                  <%= if conv.unread_count > 0 do %>
                    <span class="bg-blue-500 text-white text-xs rounded-full w-5 h-5 flex items-center justify-center flex-shrink-0 ml-2">
                      <%= conv.unread_count %>
                    </span>
                  <% end %>
                </div>
              </div>
            </button>
          <% end %>
        <% end %>
      </div>
    </div>
    """
  end
end
