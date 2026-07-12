defmodule OdyssieWeb.PostLive.Show do
  @moduledoc """
  Single post/thread view LiveView.
  Shows the post with its parent chain (thread context) and nested replies.
  """

  use OdyssieWeb, :live_view
  alias Odyssie.Feed

  @impl true
  def mount(%{"id" => post_id}, _session, socket) do
    case Feed.get_post(post_id) do
      nil ->
        {:noreply, push_navigate(socket, to: "/")}

      post ->
        post = post |> Odyssie.Repo.preload([:author, :parent, :source_post])
        thread = Feed.get_thread(post)

        post =
          post
          |> Map.put(:liked_by_me, Feed.liked?(socket.assigns.current_user, post))
          |> Map.put(:reposted_by_me, Feed.reposted?(socket.assigns.current_user, post))

        replies =
          thread.replies
          |> Enum.map(fn reply ->
            reply
            |> Map.put(:liked_by_me, Feed.liked?(socket.assigns.current_user, reply))
            |> Map.put(:reposted_by_me, Feed.reposted?(socket.assigns.current_user, reply))
          end)

        {:ok,
         socket
         |> assign(:post, post)
         |> assign(:parents, thread.parents)
         |> assign(:replies, replies)
         |> assign(:replying_to, false)
         |> assign(:reply_content, "")
         |> assign(:char_count, 0)}
    end
  end

  @impl true
  def handle_event("like", _params, socket) do
    post = socket.assigns.post
    Feed.like_post(socket.assigns.current_user, post)

    updated_post = %{post | liked_by_me: true, likes_count: post.likes_count + 1}
    {:noreply, assign(socket, :post, updated_post)}
  end

  def handle_event("unlike", _params, socket) do
    post = socket.assigns.post
    Feed.unlike_post(socket.assigns.current_user, post)

    updated_post = %{post | liked_by_me: false, likes_count: post.likes_count - 1}
    {:noreply, assign(socket, :post, updated_post)}
  end

  def handle_event("repost", _params, socket) do
    post = socket.assigns.post
    Feed.repost(socket.assigns.current_user, post)

    updated_post = %{post | reposted_by_me: true, reposts_count: post.reposts_count + 1}
    {:noreply, assign(socket, :post, updated_post)}
  end

  def handle_event("open_reply", _params, socket) do
    {:noreply, assign(socket, replying_to: true, char_count: 0)}
  end

  def handle_event("close_reply", _params, socket) do
    {:noreply, assign(socket, replying_to: false)}
  end

  def handle_event("submit_reply", %{"content" => content}, socket) do
    if String.trim(content) != "" do
      case Feed.create_post(socket.assigns.current_user, %{
             content: String.trim(content),
             post_type: :reply,
             parent_id: socket.assigns.post.id
           }) do
        {:ok, reply} ->
          reply =
            reply
            |> Map.put(:liked_by_me, false)
            |> Map.put(:reposted_by_me, false)

          updated_post = %{socket.assigns.post | replies_count: socket.assigns.post.replies_count + 1}

          {:noreply,
           socket
           |> assign(:post, updated_post)
           |> assign(:replies, socket.assigns.replies ++ [reply])
           |> assign(:replying_to, false)
           |> assign(:reply_content, "")
           |> assign(:char_count, 0)}

        {:error, _} ->
          {:noreply, socket}
      end
    else
      {:noreply, socket}
    end
  end

  def handle_event("update_reply", %{"content" => value}, socket) do
    {:noreply, assign(socket, reply_content: value, char_count: String.length(value))}
  end

  def handle_event("navigate_user", %{"username" => username}, socket) do
    {:noreply, push_navigate(socket, to: "/#{username}")}
  end

  def handle_event("navigate_post", %{"id" => post_id}, socket) do
    {:noreply, push_navigate(socket, to: "/post/#{post_id}")}
  end

  def handle_event("go_back", _params, socket) do
    {:noreply, push_navigate(socket, to: "/home")}
  end

  # ── Render ───────────────────────────────────────────────────────────

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-col min-h-screen">
      <%!-- Header --%>
      <header class="sticky top-0 bg-white bg-opacity-90 backdrop-blur-md z-40 border-b border-gray-200 px-4 py-2">
        <div class="flex items-center">
          <button class="p-2 hover:bg-gray-100 rounded-full" phx-click="go_back">
            <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 19l-7-7m0 0l7-7m-7 7h18"/>
            </svg>
          </button>
          <h1 class="ml-6 text-xl font-bold">Post</h1>
        </div>
      </header>

      <%!-- Parent Chain (Thread Context) --%>
      <%= for parent <- @parents do %>
        <div class="post-card border-b border-gray-200 px-4 py-3">
          <div class="flex space-x-3">
            <div class="flex-shrink-0">
              <img src={parent.author.avatar_url || "/images/default-avatar.png"}
                   class="w-10 h-10 rounded-full"
                   alt={parent.author.username} />
            </div>
            <div class="flex-1 min-w-0">
              <div class="flex items-center space-x-1">
                <span class="font-bold text-gray-900 text-sm">
                  <%= parent.author.display_name || parent.author.username %>
                </span>
                <span class="text-gray-500 text-sm">@<%= parent.author.username %></span>
                <%= if parent.author.is_verified do %>
                  <.verified_badge />
                <% end %>
              </div>
              <div class="mt-1 text-gray-900 text-sm">
                <%= parent.content %>
              </div>
            </div>
          </div>
        </div>
      <% end %>

      <%!-- Main Post --%>
      <div class="border-b border-gray-200 px-4 py-4">
        <div class="flex items-center space-x-2 mb-3">
          <img src={@post.author.avatar_url || "/images/default-avatar.png"}
               class="w-12 h-12 rounded-full"
               alt={@post.author.username}
               phx-click="navigate_user"
               phx-value-username={@post.author.username} />
          <div>
            <div class="flex items-center">
              <span class="font-bold text-gray-900"
                    phx-click="navigate_user"
                    phx-value-username={@post.author.username}>
                <%= @post.author.display_name || @post.author.username %>
              </span>
              <%= if @post.author.is_verified do %>
                <.verified_badge />
              <% end %>
            </div>
            <span class="text-gray-500 text-sm">@<%= @post.author.username %></span>
          </div>
        </div>

        <div class="text-gray-900 text-lg leading-relaxed whitespace-pre-wrap mb-4">
          <%= @post.content %>
        </div>

        <div class="flex items-center text-gray-500 text-sm border-t border-gray-100 pt-3 mt-3">
          <time datetime={@post.inserted_at}>
            <%= Calendar.strftime(@post.inserted_at, "%I:%M %p · %b %d, %Y") %>
          </time>
          <span class="mx-1">·</span>
          <span class="font-bold text-gray-900"><%= @post.views_count || 0 %></span>
          <span>Views</span>
        </div>

        <div class="flex items-center space-x-8 border-t border-gray-100 py-3 mt-3 text-sm">
          <div class="flex items-center space-x-1">
            <span class="font-bold text-gray-900"><%= @post.reposts_count || 0 %></span>
            <span class="text-gray-500">Reposts</span>
          </div>
          <div class="flex items-center space-x-1">
            <span class="font-bold text-gray-900"><%= @post.likes_count || 0 %></span>
            <span class="text-gray-500">Likes</span>
          </div>
          <div class="flex items-center space-x-1">
            <span class="font-bold text-gray-900"><%= @post.replies_count || 0 %></span>
            <span class="text-gray-500">Replies</span>
          </div>
        </div>

        <div class="flex items-center justify-around border-t border-gray-100 py-2">
          <button class="p-2 hover:bg-gray-100 rounded-full text-gray-500 hover:text-blue-500">
            <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-8l-4-4m0 0L8 8m4-4v12"/>
            </svg>
          </button>
          <button class="p-2 hover:bg-green-50 rounded-full text-gray-500 hover:text-green-500"
                  phx-click="repost">
            <svg class="w-5 h-5" fill={if @post.reposted_by_me, do: "currentColor", else: "none"}
                 viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5"
                    d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"/>
            </svg>
          </button>
          <button class="p-2 hover:bg-red-50 rounded-full text-gray-500 hover:text-red-500"
                  phx-click={if @post.liked_by_me, do: "unlike", else: "like"}>
            <svg class="w-5 h-5" fill={if @post.liked_by_me, do: "currentColor", else: "none"}
                 viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5"
                    d="M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z"/>
            </svg>
          </button>
        </div>
      </div>

      <%!-- Reply Composer --%>
      <div class="border-b border-gray-200 px-4 py-3 bg-gray-50">
        <div class="flex space-x-3">
          <img src={@current_user.avatar_url || "/images/default-avatar.png"}
               class="w-10 h-10 rounded-full flex-shrink-0" />
          <div class="flex-1">
            <p class="text-gray-500 text-sm mb-2">
              Replying to <span class="text-blue-500">@<%= @post.author.username %></span>
            </p>
            <form phx-submit="submit_reply">
              <textarea name="content"
                        value={@reply_content}
                        placeholder="Post your reply"
                        class="w-full resize-none border-none outline-none text-sm bg-transparent min-h-[60px]"
                        maxlength="280"
                        phx-change="update_reply" />
              <div class="flex items-center justify-between mt-2 pt-2 border-t border-gray-200">
                <span class={"text-xs #{if @char_count > 260, do: "text-red-500", else: "text-gray-400"}"}>
                  <%= @char_count %>/280
                </span>
                <button type="submit"
                        class="bg-blue-500 hover:bg-blue-600 text-white font-bold py-1.5 px-5 rounded-full text-sm disabled:opacity-50"
                        disabled={@char_count > 280 or @char_count == 0}>
                  Reply
                </button>
              </div>
            </form>
          </div>
        </div>
      </div>

      <%!-- Replies Thread --%>
      <div id="replies">
        <%= for reply <- @replies do %>
          <.post_card post={reply} />
        <% end %>
      </div>
    </div>
    """
  end
end
