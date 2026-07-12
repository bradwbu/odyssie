defmodule OdyssieWeb.HomeLive.Index do
  @moduledoc """
  Home timeline LiveView - displays the chronological feed of posts from followed accounts.
  Handles real-time post injection via Phoenix PubSub.
  """

  use OdyssieWeb, :live_view
  alias Odyssie.Feed
  alias Odyssie.Timeline

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Odyssie.PubSub, Timeline.home_topic(socket.assigns.current_user.id))
    end

    timeline = Feed.home_timeline(socket.assigns.current_user)

    {:ok,
     socket
     |> assign(:timeline, timeline)
     |> assign(:new_posts_count, 0)
     |> assign(:pending_posts, [])
     |> assign(:composing, false)
     |> assign(:char_count, 0)
     |> assign(:tab, :home),
     temporary_assigns: [timeline: nil]}
  end

  @impl true
  def handle_params(%{"tab" => tab}, _uri, socket) do
    {:noreply, assign(socket, :tab, String.to_existing_atom(tab))}
  end

  def handle_params(_params, _uri, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("open_compose", _params, socket) do
    {:noreply, assign(socket, composing: true, char_count: 0)}
  end

  def handle_event("close_compose", _params, socket) do
    {:noreply, assign(socket, composing: false)}
  end

  def handle_event("update_char_count", %{"value" => value}, socket) do
    {:noreply, assign(socket, char_count: String.length(value))}
  end

  def handle_event("submit_post", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("show_new_posts", _params, socket) do
    new_timeline = Feed.home_timeline(socket.assigns.current_user)

    all_posts = socket.assigns.pending_posts ++ new_timeline.posts

    {:noreply,
     socket
     |> assign(:timeline, %{new_timeline | posts: all_posts})
     |> assign(:new_posts_count, 0)
     |> assign(:pending_posts, [])}
  end

  def handle_event("reply", %{"id" => post_id}, socket) do
    {:noreply, push_navigate(socket, to: "/post/#{post_id}")}
  end

  def handle_event("like", %{"id" => post_id}, socket) do
    post = Feed.get_post!(post_id)
    Feed.like_post(socket.assigns.current_user, post)

    timeline = refresh_timeline(socket)
    {:noreply, assign(socket, :timeline, timeline)}
  end

  def handle_event("unlike", %{"id" => post_id}, socket) do
    post = Feed.get_post!(post_id)
    Feed.unlike_post(socket.assigns.current_user, post)

    timeline = refresh_timeline(socket)
    {:noreply, assign(socket, :timeline, timeline)}
  end

  def handle_event("repost", %{"id" => post_id}, socket) do
    post = Feed.get_post!(post_id)
    Feed.repost(socket.assigns.current_user, post)

    timeline = refresh_timeline(socket)
    {:noreply, assign(socket, :timeline, timeline)}
  end

  def handle_event("navigate_post", %{"id" => post_id}, socket) do
    {:noreply, push_navigate(socket, to: "/post/#{post_id}")}
  end

  # ── PubSub Handlers ──────────────────────────────────────────────────

  @impl true
  def handle_info({:new_home_post, post}, socket) do
    new_post = post
    |> Map.put(:liked_by_me, Feed.liked?(socket.assigns.current_user, post))
    |> Map.put(:reposted_by_me, Feed.reposted?(socket.assigns.current_user, post))

    {:noreply,
     socket
     |> assign(:pending_posts, [new_post | socket.assigns.pending_posts])
     |> assign(:new_posts_count, socket.assigns.new_posts_count + 1)}
  end

  def handle_info(_, socket), do: {:noreply, socket}

  # ── Private Helpers ──────────────────────────────────────────────────

  defp refresh_timeline(socket) do
    Feed.home_timeline(socket.assigns.current_user)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-col min-h-screen">
      <%!-- Header --%>
      <header class="sticky top-0 bg-white bg-opacity-90 backdrop-blur-md z-40 border-b border-gray-200 px-4 py-3">
        <h1 class="text-xl font-bold">Home</h1>
        <div class="flex mt-3 -mx-4">
          <button class={"flex-1 text-center py-3 text-sm font-medium border-b-2 #{if @tab == :home, do: "border-blue-500 text-blue-500", else: "border-transparent text-gray-500 hover:bg-gray-50"}"}
                  phx-click="switch_tab" phx-value-tab="home">
            For you
          </button>
          <button class={"flex-1 text-center py-3 text-sm font-medium border-b-2 #{if @tab == :following, do: "border-blue-500 text-blue-500", else: "border-transparent text-gray-500 hover:bg-gray-50"}"}
                  phx-click="switch_tab" phx-value-tab="following">
            Following
          </button>
        </div>
      </header>

      <%!-- New Posts Indicator --%>
      <%= if @new_posts_count > 0 do %>
        <button class="w-full py-3 text-blue-500 text-sm font-medium hover:bg-blue-50 border-b border-gray-200 transition-colors"
                phx-click="show_new_posts">
          Show <%= @new_posts_count %> new post<%= if @new_posts_count > 1, do: "s" %>
        </button>
      <% end %>

      <%!-- Feed --%>
      <div id="timeline" phx-update="replace">
        <%= for post <- @timeline.posts do %>
          <.post_card post={post} />
        <% end %>
      </div>

      <%!-- Load More --%>
      <%= if @timeline.has_more do %>
        <button class="w-full py-4 text-blue-500 text-sm font-medium hover:bg-blue-50"
                phx-click="load_more" phx-disable-with="Loading...">
          Load more
        </button>
      <% end %>

      <%!-- Compose Modal --%>
      <%= if @composing do %>
        <.compose_post char_count={@char_count} />
      <% end %>
    </div>
    """
  end
end
