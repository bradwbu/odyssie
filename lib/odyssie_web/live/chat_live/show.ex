defmodule OdyssieWeb.ChatLive.Show do
  @moduledoc """
  Individual DM conversation LiveView.
  Handles real-time message delivery, auto-scrolling, and message composition.
  Uses Phoenix PubSub for instant message delivery.
  """

  use OdyssieWeb, :live_view
  alias Odyssie.{Chat, Accounts}

  @impl true
  def mount(%{"user_id" => other_user_id}, _session, socket) do
    if connected?(socket) do
      current_user = socket.assigns.current_user
      Chat.DMSubscriber.subscribe_to_dm(current_user.id, other_user_id)
      Chat.mark_as_read(current_user, other_user_id)
    end

    case Accounts.get_user(other_user_id) do
      nil ->
        {:noreply, push_navigate(socket, to: "/messages")}

      other_user ->
        conversation = Chat.get_conversation(
          socket.assigns.current_user,
          other_user.id,
          limit: 50
        )

        Chat.mark_as_read(socket.assigns.current_user, other_user.id)

        {:ok,
         socket
         |> assign(:other_user, other_user)
         |> assign(:messages, conversation.messages)
         |> assign(:has_more, conversation.has_more)
         |> assign(:next_cursor, conversation.next_cursor)
         |> assign(:message_input, "")
         |> assign(:typing, false)
         |> temporary_assigns([messages: [])}
    end
  end

  @impl true
  def handle_params(%{"user_id" => other_user_id}, _uri, socket) do
    if Map.get(socket.assigns, :other_user) && socket.assigns.other_user.id != other_user_id do
      {:noreply, push_navigate(socket, to: "/messages/#{other_user_id}")}
    else
      {:noreply, socket}
    end
  end

  def handle_params(_params, _uri, socket) do
    {:noreply, socket}
  end

  # ── Events ───────────────────────────────────────────────────────────

  @impl true
  def handle_event("send_message", %{"body" => body}, socket) do
    if String.trim(body) != "" do
      case Chat.send_message(
             socket.assigns.current_user,
             socket.assigns.other_user,
             String.trim(body)
           ) do
        {:ok, message} ->
          {:noreply,
           socket
           |> assign(:message_input, "")
           |> assign(:messages, [message])}

        {:error, _reason} ->
          {:noreply, socket}
      end
    else
      {:noreply, socket}
    end
  end

  def handle_event("update_input", %{"value" => value}, socket) do
    {:noreply, assign(socket, :message_input, value)}
  end

  def handle_event("load_more", _params, socket) do
    if socket.assigns.has_more do
      conversation = Chat.get_conversation(
        socket.assigns.current_user,
        socket.assigns.other_user.id,
        limit: 50,
        before: socket.assigns.next_cursor
      )

      {:noreply,
       socket
       |> assign(:messages, conversation.messages ++ socket.assigns.messages)
       |> assign(:has_more, conversation.has_more)
       |> assign(:next_cursor, conversation.next_cursor)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("go_back", _params, socket) do
    {:noreply, push_navigate(socket, to: "/messages")}
  end

  # ── PubSub ───────────────────────────────────────────────────────────

  @impl true
  def handle_info({:new_dm, message}, socket) do
    Chat.mark_as_read(socket.assigns.current_user, message.sender_id)

    {:noreply,
     socket
     |> assign(:messages, [message])
     |> assign(:unread_messages, Chat.unread_count(socket.assigns.current_user))}
  end

  def handle_info(_, socket), do: {:noreply, socket}

  # ── Render ───────────────────────────────────────────────────────────

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-col h-screen">
      <%!-- Header --%>
      <header class="sticky top-0 bg-white bg-opacity-90 backdrop-blur-md z-40 border-b border-gray-200 px-4 py-2">
        <div class="flex items-center">
          <button class="p-2 hover:bg-gray-100 rounded-full mr-2 md:hidden"
                  phx-click="go_back">
            <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 19l-7-7m0 0l7-7m-7 7h18"/>
            </svg>
          </button>
          <img src={@other_user.avatar_url || "/images/default-avatar.png"}
               class="w-8 h-8 rounded-full" />
          <div class="ml-3 flex-1">
            <div class="flex items-center">
              <span class="font-bold text-sm">
                <%= @other_user.display_name || @other_user.username %>
              </span>
              <%= if @other_user.is_verified do %>
                <.verified_badge />
              <% end %>
            </div>
            <p class="text-gray-500 text-xs">@<%= @other_user.username %></p>
          </div>
          <button class="p-2 hover:bg-gray-100 rounded-full text-gray-500">
            <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M12 5v.01M12 12v.01M12 19v.01M12 6a1 1 0 110-2 1 1 0 010 2zm0 7a1 1 0 110-2 1 1 0 010 2zm0 7a1 1 0 110-2 1 1 0 010 2z"/>
            </svg>
          </button>
        </div>
      </header>

      <%!-- Messages Area --%>
      <div id="messages-container" class="flex-1 overflow-y-auto px-4 py-4 space-y-4"
           phx-update="append">
        <%= if @has_more do %>
          <button class="w-full text-center py-2 text-blue-500 text-sm hover:bg-blue-50 rounded-lg"
                  phx-click="load_more">
            Load older messages
          </button>
        <% end %>

        <%= for message <- @messages do %>
          <div class={"flex #{if message.sender_id == @current_user.id, do: "justify-end", else: "justify-start"}"}>
            <div class={"max-w-[80%] #{if message.sender_id == @current_user.id, do: "bg-blue-500 text-white rounded-2xl rounded-br-sm", else: "bg-gray-100 text-gray-900 rounded-2xl rounded-bl-sm"} px-4 py-2"}>
              <p class="text-sm leading-relaxed whitespace-pre-wrap"><%= message.body %></p>
              <p class={"text-xs mt-1 #{if message.sender_id == @current_user.id, do: "text-blue-100", else: "text-gray-400"}"}>
                <%= Calendar.strftime(message.inserted_at, "%I:%M %p") %>
              </p>
            </div>
          </div>
        <% end %>
      </div>

      <%!-- Message Input --%>
      <div class="border-t border-gray-200 p-4 bg-white">
        <form phx-submit="send_message" class="flex items-center space-x-3">
          <button type="button" class="p-2 hover:bg-gray-100 rounded-full text-blue-500">
            <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M15.172 7l-6.586 6.586a2 2 0 102.828 2.828l6.414-6.586a4 4 0 00-5.656-5.656l-6.415 6.585a6 6 0 108.486 8.486L20.5 13"/>
            </svg>
          </button>
          <input type="text"
                 name="body"
                 value={@message_input}
                 placeholder="Start a new message"
                 class="flex-1 bg-gray-100 rounded-full py-2 px-4 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500 focus:bg-white"
                 phx-keyup="update_input"
                 phx-key="keyup"
                 autocomplete="off" />
          <button type="submit"
                  class="p-2 hover:bg-gray-100 rounded-full text-blue-500 disabled:opacity-50"
                  disabled={String.trim(@message_input) == ""}>
            <svg class="w-5 h-5" fill="currentColor" viewBox="0 0 24 24">
              <path d="M2.01 21L23 12 2.01 3 2 10l15 2-15 2z"/>
            </svg>
          </button>
        </form>
      </div>
    </div>

    <script>
      // Auto-scroll to bottom when new messages arrive
      const container = document.getElementById('messages-container');
      if (container) {
        requestAnimationFrame(() => {
          container.scrollTop = container.scrollHeight;
        });
      }
    </script>
    """
  end
end
