defmodule OdyssieWeb.CoreComponents do
  @moduledoc """
  Shared UI components for the Odyssie application.
  """

  use Phoenix.Component
  import Phoenix.LiveView.JS

  alias Odyssie.Feed.Post

  @doc """
  Renders the classic Odyssie blue checkmark for verified users.
  """
  def verified_badge(assigns) do
    ~H"""
    <svg class="inline-block w-5 h-5 text-blue-500 ml-1" viewBox="0 0 24 24" fill="currentColor">
      <path d="M22.5 12.5c0-1.58-.875-2.95-2.148-3.6.154-.435.238-.905.238-1.4 0-2.21-1.71-3.998-3.818-3.998-.47 0-.92.084-1.336.25C14.818 2.415 13.51 1.5 12 1.5s-2.816.917-3.437 2.25c-.415-.165-.866-.25-1.336-.25-2.11 0-3.818 1.79-3.818 4 0 .494.083.964.237 1.4-1.272.65-2.147 2.018-2.147 3.6 0 1.495.782 2.798 1.942 3.486-.02.17-.032.34-.032.514 0 2.21 1.708 4 3.818 4 .47 0 .92-.086 1.335-.25.62 1.334 1.926 2.25 3.437 2.25 1.512 0 2.818-.916 3.437-2.25.415.163.865.248 1.336.248 2.11 0 3.818-1.79 3.818-4 0-.174-.012-.344-.033-.513 1.158-.687 1.943-1.99 1.943-3.484zm-6.616-3.334l-4.334 6.5c-.145.217-.382.334-.625.334-.143 0-.288-.04-.416-.126l-.115-.094-2.415-2.415c-.293-.293-.293-.768 0-1.06s.768-.294 1.06 0l1.77 1.767 3.825-5.74c.23-.345.696-.436 1.04-.207.346.23.44.696.21 1.04z"/>
    </svg>
    """
  end

  @doc """
  Renders a post component with the classic 2021 Twitter layout.
  """
  def post_card(assigns) do
    assigns =
      assigns
      |> Map.put_new(:show_thread, false)

    ~H"""
    <div class="post-card border-b border-gray-200 px-4 py-3 hover:bg-gray-50 cursor-pointer"
         phx-click="navigate_post" phx-value-id={@post.id}>
      <div class="flex space-x-3">
        <div class="flex-shrink-0">
          <img src={@post.author.avatar_url || "/images/default-avatar.png"}
               class="w-10 h-10 rounded-full"
               alt={@post.author.username} />
        </div>
        <div class="flex-1 min-w-0">
          <div class="flex items-center space-x-1">
            <span class="font-bold text-gray-900 text-sm truncate">
              <%= @post.author.display_name || @post.author.username %>
            </span>
            <span class="text-gray-500 text-sm truncate">
              @<%= @post.author.username %>
            </span>
            <span class="text-gray-400 text-sm">·</span>
            <time class="text-gray-500 text-sm" datetime={@post.inserted_at}>
              <%= format_time(@post.inserted_at) %>
            </time>
            <%= if @post.author.is_verified do %>
              <.verified_badge />
            <% end %>
          </div>
          <div class="mt-1 text-gray-900 text-sm leading-relaxed whitespace-pre-wrap">
            <%= for segment <- @post.parsed_content || Post.parse_content(@post.content) do %>
              <%= case segment do %>
                <% %{type: :mention, text: text, username: username} -> %>
                  <a href={"/#{username}"} class="text-blue-500 hover:underline"
                     phx-click="stop_propagation"><%= text %></a>
                <% %{type: :hashtag, text: text} -> %>
                  <a href={"/explore?q=#{text}"} class="text-blue-500 hover:underline"
                     phx-click="stop_propagation"><%= text %></a>
                <% %{type: :text, text: text} -> %>
                  <%= text %>
              <% end %>
            <% end %>
          </div>

          <div class="mt-3 flex items-center space-x-12 text-gray-500">
            <button class="flex items-center space-x-1 hover:text-blue-500 group"
                    phx-click={JS.push("reply") |> JS.stopPropagation()}
                    phx-value-id={@post.id}>
              <svg class="w-5 h-5 group-hover:text-blue-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5"
                      d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z"/>
              </svg>
              <span class="text-xs"><%= @post.replies_count || 0 %></span>
            </button>

            <button class="flex items-center space-x-1 hover:text-green-500 group"
                    phx-click={JS.push("repost") |> JS.stopPropagation()}
                    phx-value-id={@post.id}>
              <svg class="w-5 h-5 group-hover:text-green-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5"
                      d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"/>
              </svg>
              <span class={"text-xs #{if @post.reposted_by_me, do: "text-green-500"}"}>
                <%= @post.reposts_count || 0 %>
              </span>
            </button>

            <button class="flex items-center space-x-1 hover:text-red-500 group"
                    phx-click={JS.push(if(@post.liked_by_me, do: "unlike", else: "like")) |> JS.stopPropagation()}
                    phx-value-id={@post.id}>
              <svg class={"w-5 h-5 #{if @post.liked_by_me, do: "text-red-500 fill-red-500", else: "group-hover:text-red-500"}"}
                   fill={if @post.liked_by_me, do: "currentColor", else: "none"}
                   viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5"
                      d="M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z"/>
              </svg>
              <span class={"text-xs #{if @post.liked_by_me, do: "text-red-500"}"}>
                <%= @post.likes_count || 0 %>
              </span>
            </button>

            <button class="flex items-center hover:text-blue-500 group">
              <svg class="w-5 h-5 group-hover:text-blue-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5"
                      d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-8l-4-4m0 0L8 8m4-4v12"/>
              </svg>
            </button>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Formats a DateTime to a human-readable relative time string.
  """
  def format_time(%DateTime{} = datetime) do
    now = DateTime.utc_now()
    diff = DateTime.diff(now, datetime, :second)

    cond do
      diff < 60 ->
        "#{diff}s"

      diff < 3600 ->
        "#{div(diff, 60)}m"

      diff < 86400 ->
        "#{div(diff, 3600)}h"

      diff < 604800 ->
        "#{div(diff, 86400)}d"

      true ->
        Calendar.strftime(datetime, "%b %d")
    end
  end

  @doc """
  Renders the compose tweet modal.
  """
  def compose_post(assigns) do
    ~H"""
    <div class="compose-modal fixed inset-0 bg-black bg-opacity-50 z-50 flex items-start justify-center pt-12"
         phx-click="close_compose">
      <div class="bg-white rounded-2xl w-full max-w-lg shadow-xl" phx-click={JS.stopPropagation()}>
        <div class="flex items-center p-3">
          <button class="text-gray-500 hover:text-gray-700 p-2" phx-click={JS.push("close_compose") |> JS.stopPropagation()}>
            <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
            </svg>
          </button>
        </div>
        <.form for={%{}} phx-submit="submit_post" class="p-4">
          <textarea
            class="w-full resize-none border-none outline-none text-lg placeholder-gray-500 min-h-[120px]"
            placeholder="What's happening?"
            maxlength="280"
            phx-change="update_char_count"
            name="post[content]"
          />
          <div class="flex items-center justify-between mt-3 pt-3 border-t border-gray-100">
            <div class="flex items-center space-x-3 text-blue-500">
              <button type="button" class="hover:bg-blue-50 p-2 rounded-full">
                <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5"
                        d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z"/>
                </svg>
              </button>
            </div>
            <div class="flex items-center space-x-3">
              <span class={"text-sm #{if (@char_count || 0) > 260, do: "text-red-500", else: "text-gray-500"}"}>
                <%= @char_count || 0 %>/280
              </span>
              <button type="submit"
                      class="bg-blue-500 hover:bg-blue-600 text-white font-bold py-2 px-6 rounded-full text-sm disabled:opacity-50"
                      disabled={(@char_count || 0) > 280 or (@char_count || 0) == 0}>
                Post
              </button>
            </div>
          </div>
        </.form>
      </div>
    </div>
    """
  end
end
