defmodule OdyssieWeb.ProfileLive.Index do
  @moduledoc """
  Profile page LiveView with tab switching for Posts, Replies, Media, and Likes.
  Handles real-time follower count updates and profile interactions.
  """

  use OdyssieWeb, :live_view
  alias Odyssie.{Accounts, Feed}

  @impl true
  def mount(%{"username" => username}, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Odyssie.PubSub, "timeline:#{socket.assigns.current_user.id}")
    end

    case Accounts.get_user_by_username(username) do
      nil ->
        {:noreply, push_navigate(socket, to: "/")}

      %Accounts.User{} = user ->
        is_following = Accounts.following?(socket.assigns.current_user, user)

        timeline = Feed.user_timeline(
          socket.assigns.current_user,
          user,
          :posts
        )

        {:ok,
         socket
         |> assign(:profile_user, user)
         |> assign(:is_following, is_following)
         |> assign(:active_tab, :posts)
         |> assign(:timeline, timeline)
         |> assign(:composing, false)
         |> assign(:char_count, 0)}
    end
  end

  @impl true
  def handle_params(%{"username" => username}, _uri, socket) do
    if socket.assigns.profile_user.username != username do
      case Accounts.get_user_by_username(username) do
        nil ->
          {:noreply, push_navigate(socket, to: "/")}

        user ->
          is_following = Accounts.following?(socket.assigns.current_user, user)
          tab = detect_tab_from_uri(_uri)

          timeline = Feed.user_timeline(
            socket.assigns.current_user,
            user,
            tab
          )

          {:noreply,
           socket
           |> assign(:profile_user, user)
           |> assign(:is_following, is_following)
           |> assign(:active_tab, tab)
           |> assign(:timeline, timeline)}
      end
    else
      tab = detect_tab_from_uri(_uri)

      timeline = Feed.user_timeline(
        socket.assigns.current_user,
        socket.assigns.profile_user,
        tab
      )

      {:noreply,
       socket
       |> assign(:active_tab, tab)
       |> assign(:timeline, timeline)}
    end
  end

  def handle_params(_params, _uri, socket) do
    {:noreply, socket}
  end

  # ── Events ───────────────────────────────────────────────────────────

  @impl true
  def handle_event("follow", _params, socket) do
    %Accounts.User{} = profile_user = socket.assigns.profile_user

    case Accounts.follow(socket.assigns.current_user, profile_user) do
      {:ok, _} ->
        updated_user = %{profile_user | followers_count: profile_user.followers_count + 1}

        {:noreply,
         socket
         |> assign(:profile_user, updated_user)
         |> assign(:is_following, true)}

      {:error, _reason} ->
        {:noreply, socket}
    end
  end

  def handle_event("unfollow", _params, socket) do
    %Accounts.User{} = profile_user = socket.assigns.profile_user

    case Accounts.unfollow(socket.assigns.current_user, profile_user) do
      {:ok, _} ->
        updated_user = %{profile_user | followers_count: profile_user.followers_count - 1}

        {:noreply,
         socket
         |> assign(:profile_user, updated_user)
         |> assign(:is_following, false)}

      {:error, _reason} ->
        {:noreply, socket}
    end
  end

  def handle_event("switch_tab", %{"tab" => tab}, socket) do
    tab = String.to_existing_atom(tab)

    timeline = Feed.user_timeline(
      socket.assigns.current_user,
      socket.assigns.profile_user,
      tab
    )

    {:noreply,
     socket
     |> assign(:active_tab, tab)
     |> assign(:timeline, timeline)}
  end

  def handle_event("open_compose", _params, socket) do
    {:noreply, assign(socket, composing: true, char_count: 0)}
  end

  def handle_event("close_compose", _params, socket) do
    {:noreply, assign(socket, composing: false)}
  end

  def handle_event("like", %{"id" => post_id}, socket) do
    post = Feed.get_post!(post_id)
    Feed.like_post(socket.assigns.current_user, post)
    refresh_tab(socket)
  end

  def handle_event("unlike", %{"id" => post_id}, socket) do
    post = Feed.get_post!(post_id)
    Feed.unlike_post(socket.assigns.current_user, post)
    refresh_tab(socket)
  end

  def handle_event("repost", %{"id" => post_id}, socket) do
    post = Feed.get_post!(post_id)
    Feed.repost(socket.assigns.current_user, post)
    refresh_tab(socket)
  end

  def handle_event("navigate_post", %{"id" => post_id}, socket) do
    {:noreply, push_navigate(socket, to: "/post/#{post_id}")}
  end

  # ── PubSub ───────────────────────────────────────────────────────────

  @impl true
  def handle_info({:new_post, _post}, socket) do
    # Refresh current tab if the profile user posted something
    refresh_tab(socket)
  end

  def handle_info(_, socket), do: {:noreply, socket}

  # ── Helpers ──────────────────────────────────────────────────────────

  defp refresh_tab(socket) do
    timeline = Feed.user_timeline(
      socket.assigns.current_user,
      socket.assigns.profile_user,
      socket.assigns.active_tab
    )

    {:noreply, assign(socket, :timeline, timeline)}
  end

  defp detect_tab_from_uri(uri) do
    cond do
      String.contains?(uri, "/with_replies") -> :replies
      String.contains?(uri, "/likes") -> :likes
      String.contains?(uri, "/media") -> :media
      true -> :posts
    end
  end

  # ── Render ───────────────────────────────────────────────────────────

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-col min-h-screen">
      <%!-- Back Header --%>
      <header class="sticky top-0 bg-white bg-opacity-90 backdrop-blur-md z-40 border-b border-gray-200">
        <div class="flex items-center px-4 py-1">
          <button class="p-2 hover:bg-gray-100 rounded-full" phx-click="go_back">
            <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 19l-7-7m0 0l7-7m-7 7h18"/>
            </svg>
          </button>
          <div class="ml-6">
            <h1 class="text-xl font-bold"><%= @profile_user.display_name || @profile_user.username %></h1>
            <p class="text-gray-500 text-sm"><%= @profile_user.posts_count %> posts</p>
          </div>
        </div>
      </header>

      <%!-- Header Image --%>
      <div class="h-48 bg-gray-300">
        <%= if @profile_user.header_url do %>
          <img src={@profile_user.header_url} class="w-full h-full object-cover" />
        <% end %>
      </div>

      <%!-- Profile Info --%>
      <div class="px-4 pb-4">
        <div class="flex justify-between items-end -mt-16 mb-3">
          <img src={@profile_user.avatar_url || "/images/default-avatar.png"}
               class="w-32 h-32 rounded-full border-4 border-white bg-white" />
          <div class="flex space-x-2">
            <%= if @profile_user.id != @current_user.id do %>
              <button class="border border-gray-300 text-gray-700 font-bold py-2 px-5 rounded-full hover:bg-gray-50 text-sm"
                      phx-click="message_user" phx-value-id={@profile_user.id}>
                Message
              </button>
              <%= if @is_following do %>
                <button class="border border-gray-300 text-gray-700 font-bold py-2 px-5 rounded-full hover:border-red-300 hover:text-red-500 text-sm"
                        phx-click="unfollow">
                  Following
                </button>
              <% else %>
                <button class="bg-gray-900 text-white font-bold py-2 px-5 rounded-full hover:bg-gray-700 text-sm"
                        phx-click="follow">
                  Follow
                </button>
              <% end %>
            <% else %>
              <a href="/settings/profile" class="border border-gray-300 text-gray-700 font-bold py-2 px-5 rounded-full hover:bg-gray-50 text-sm">
                Edit profile
              </a>
            <% end %>
          </div>
        </div>

        <div>
          <div class="flex items-center">
            <h2 class="text-xl font-extrabold"><%= @profile_user.display_name || @profile_user.username %></h2>
            <%= if @profile_user.is_verified do %>
              <.verified_badge />
            <% end %>
          </div>
          <p class="text-gray-500 text-sm">@<%= @profile_user.username %></p>
        </div>

        <%= if @profile_user.bio do %>
          <p class="mt-3 text-gray-900"><%= @profile_user.bio %></p>
        <% end %>

        <div class="flex flex-wrap items-center mt-3 text-gray-500 text-sm space-x-3">
          <%= if @profile_user.location do %>
            <span class="flex items-center">
              <svg class="w-4 h-4 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z"/>
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z"/>
              </svg>
              <%= @profile_user.location %>
            </span>
          <% end %>

          <%= if @profile_user.website do %>
            <a href={@profile_user.website} target="_blank" class="flex items-center text-blue-500 hover:underline">
              <svg class="w-4 h-4 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M13.828 10.172a4 4 0 00-5.656 0l-4 4a4 4 0 105.656 5.656l1.102-1.101m-.758-4.899a4 4 0 005.656 0l4-4a4 4 0 00-5.656-5.656l-1.1 1.1"/>
              </svg>
              <%= String.replace_leading(@profile_user.website, "https://", "") %>
            </a>
          <% end %>

          <span class="flex items-center">
            <svg class="w-4 h-4 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"/>
            </svg>
            Joined <%= Calendar.strftime(@profile_user.inserted_at, "%B %Y") %>
          </span>
        </div>

        <div class="flex space-x-4 mt-3 text-sm">
          <a href={"/#{@profile_user.username}/following"} class="hover:underline">
            <span class="font-bold text-gray-900"><%= @profile_user.following_count %></span>
            <span class="text-gray-500">Following</span>
          </a>
          <a href={"/#{@profile_user.username}/followers"} class="hover:underline">
            <span class="font-bold text-gray-900"><%= @profile_user.followers_count %></span>
            <span class="text-gray-500">Followers</span>
          </a>
        </div>
      </div>

      <%!-- Profile Tabs --%>
      <div class="flex border-b border-gray-200">
        <a href={"/#{@profile_user.username}"}
           class={"flex-1 text-center py-3 text-sm font-medium border-b-2 #{if @active_tab == :posts, do: "border-blue-500 text-blue-500", else: "border-transparent text-gray-500 hover:bg-gray-50"}"}>
          Posts
        </a>
        <a href={"/#{@profile_user.username}/with_replies"}
           class={"flex-1 text-center py-3 text-sm font-medium border-b-2 #{if @active_tab == :replies, do: "border-blue-500 text-blue-500", else: "border-transparent text-gray-500 hover:bg-gray-50"}"}>
          Posts & Replies
        </a>
        <a href={"/#{@profile_user.username}/media"}
           class={"flex-1 text-center py-3 text-sm font-medium border-b-2 #{if @active_tab == :media, do: "border-blue-500 text-blue-500", else: "border-transparent text-gray-500 hover:bg-gray-50"}"}>
          Media
        </a>
        <a href={"/#{@profile_user.username}/likes"}
           class={"flex-1 text-center py-3 text-sm font-medium border-b-2 #{if @active_tab == :likes, do: "border-blue-500 text-blue-500", else: "border-transparent text-gray-500 hover:bg-gray-50"}"}>
          Likes
        </a>
      </div>

      <%!-- Profile Posts --%>
      <div id="profile-posts">
        <%= if @timeline.posts == [] do %>
          <div class="p-8 text-center">
            <%= if @active_tab == :posts do %>
              <h2 class="text-2xl font-extrabold mb-2">No posts yet</h2>
              <p class="text-gray-500">When they post, it'll show up here.</p>
            <% else %>
              <h2 class="text-2xl font-extrabold mb-2">No <%= @active_tab %> yet</h2>
              <p class="text-gray-500">Try another tab.</p>
            <% end %>
          </div>
        <% else %>
          <%= for post <- @timeline.posts do %>
            <.post_card post={post} />
          <% end %>
        <% end %>
      </div>
    </div>

    <%= if @composing do %>
      <.compose_post char_count={@char_count} />
    <% end %>
    """
  end
end
