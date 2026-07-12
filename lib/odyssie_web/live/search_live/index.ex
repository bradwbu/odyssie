defmodule OdyssieWeb.SearchLive.Index do
  @moduledoc """
  Search/Explore page LiveView.
  Shows trending hashtags and allows searching posts and users.
  """

  use OdyssieWeb, :live_view
  alias Odyssie.Feed

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:query, "")
     |> assign(:results, %{posts: [], users: []})
     |> assign(:trending, Feed.trending_hashtags())
     |> assign(:searched, false)}
  end

  @impl true
  def handle_event("update_query", %{"value" => value}, socket) do
    {:noreply, assign(socket, query: value)}
  end

  def handle_event("search", _params, socket) do
    query = String.trim(socket.assigns.query)

    if query != "" do
      posts = Feed.search_posts(query)
      users = Odyssie.Accounts.search_users(query)

      {:noreply,
       socket
       |> assign(:results, %{posts: posts, users: users})
       |> assign(:searched, true)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("navigate_user", %{"username" => username}, socket) do
    {:noreply, push_navigate(socket, to: "/#{username}")}
  end

  def handle_event("navigate_post", %{"id" => post_id}, socket) do
    {:noreply, push_navigate(socket, to: "/post/#{post_id}")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-col min-h-screen">
      <header class="sticky top-0 bg-white bg-opacity-90 backdrop-blur-md z-40 border-b border-gray-200 px-4 py-2">
        <div class="relative">
          <svg class="w-5 h-5 absolute left-3 top-2.5 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"/>
          </svg>
          <form phx-submit="search">
            <input type="text"
                   name="query"
                   value={@query}
                   placeholder="Search Odyssie"
                   class="w-full bg-gray-100 rounded-full py-2.5 pl-12 pr-4 text-sm border border-transparent focus:border-blue-500 focus:bg-white focus:outline-none"
                   phx-keyup="update_query"
                   phx-key="keyup" />
          </form>
        </div>
      </header>

      <%= if @searched do %>
        <div>
          <%= if @results.users != [] do %>
            <div class="border-b border-gray-200">
              <h2 class="text-xl font-extrabold px-4 py-3">People</h2>
              <%= for user <- @results.users do %>
                <a href={"/#{user.username}"}
                   class="flex items-center px-4 py-3 hover:bg-gray-50 border-b border-gray-100"
                   phx-click="navigate_user"
                   phx-value-username={user.username}>
                  <img src={user.avatar_url || "/images/default-avatar.png"}
                       class="w-12 h-12 rounded-full" />
                  <div class="ml-3">
                    <div class="flex items-center">
                      <span class="font-bold text-sm"><%= user.display_name || user.username %></span>
                      <%= if user.is_verified do %>
                        <.verified_badge />
                      <% end %>
                    </div>
                    <span class="text-gray-500 text-sm">@<%= user.username %></span>
                    <%= if user.bio do %>
                      <p class="text-gray-600 text-sm mt-1 line-clamp-1"><%= user.bio %></p>
                    <% end %>
                  </div>
                </a>
              <% end %>
            </div>
          <% end %>

          <%= if @results.posts != [] do %>
            <div>
              <h2 class="text-xl font-extrabold px-4 py-3">Posts</h2>
              <%= for post <- @results.posts do %>
                <.post_card post={post} />
              <% end %>
            </div>
          <% end %>

          <%= if @results.posts == [] and @results.users == [] do %>
            <div class="p-8 text-center">
              <h2 class="text-2xl font-extrabold mb-2">No results for "<%= @query %>"</h2>
              <p class="text-gray-500">Try searching for something else.</p>
            </div>
          <% end %>
        </div>
      <% else %>
        <%!-- Trending --%>
        <div class="bg-gray-50 rounded-2xl m-4 overflow-hidden">
          <h2 class="text-xl font-extrabold px-4 py-3">Trends for you</h2>
          <div class="space-y-0">
            <%= for {tag, count} <- @trending do %>
              <a href="#" class="block px-4 py-3 hover:bg-gray-100">
                <div class="text-gray-500 text-xs">Trending</div>
                <div class="font-bold text-sm"><%= tag %></div>
                <div class="text-gray-500 text-xs"><%= count %> posts</div>
              </a>
            <% end %>

            <%= if @trending == [] do %>
              <div class="px-4 py-6 text-center text-gray-500">
                <p>No trending hashtags yet.</p>
              </div>
            <% end %>
          </div>
        </div>
      <% end %>
    </div>
    """
  end
end
