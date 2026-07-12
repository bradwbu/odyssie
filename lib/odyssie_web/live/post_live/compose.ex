defmodule OdyssieWeb.PostLive.Compose do
  @moduledoc """
  Dedicated compose post page LiveView.
  """

  use OdyssieWeb, :live_view
  alias Odyssie.Feed

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:content, "")
     |> assign(:char_count, 0)}
  end

  @impl true
  def handle_event("update_content", %{"value" => value}, socket) do
    {:noreply, assign(socket, content: value, char_count: String.length(value))}
  end

  def handle_event("submit_post", _params, socket) do
    if String.trim(socket.assigns.content) != "" and socket.assigns.char_count <= 280 do
      case Feed.create_post(socket.assigns.current_user, %{content: String.trim(socket.assigns.content)}) do
        {:ok, post} ->
          {:noreply, push_navigate(socket, to: "/post/#{post.id}")}

        {:error, _} ->
          {:noreply, socket}
      end
    else
      {:noreply, socket}
    end
  end

  def handle_event("go_back", _params, socket) do
    {:noreply, push_navigate(socket, to: "/home")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-col min-h-screen">
      <header class="sticky top-0 bg-white bg-opacity-90 backdrop-blur-md z-40 border-b border-gray-200 px-4 py-2">
        <div class="flex items-center justify-between">
          <div class="flex items-center">
            <button class="p-2 hover:bg-gray-100 rounded-full" phx-click="go_back">
              <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
              </svg>
            </button>
          </div>
          <button class="bg-blue-500 hover:bg-blue-600 text-white font-bold py-1.5 px-5 rounded-full text-sm disabled:opacity-50"
                  disabled={@char_count > 280 or @char_count == 0}
                  phx-click="submit_post">
            Post
          </button>
        </div>
      </header>

      <div class="p-4">
        <div class="flex space-x-3">
          <img src={@current_user.avatar_url || "/images/default-avatar.png"}
               class="w-10 h-10 rounded-full flex-shrink-0" />
          <div class="flex-1">
            <textarea
              class="w-full resize-none border-none outline-none text-lg placeholder-gray-500 min-h-[200px]"
              placeholder="What's happening?"
              maxlength="280"
              phx-keyup="update_content"
              phx-key="keyup"
              autofocus="true"
            />
            <div class="flex items-center justify-between mt-4 pt-4 border-t border-gray-100">
              <div class="flex items-center space-x-3 text-blue-500">
                <button class="hover:bg-blue-50 p-2 rounded-full">
                  <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5"
                          d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z"/>
                  </svg>
                </button>
              </div>
              <span class={"text-sm #{if @char_count > 260, do: "text-red-500", else: "text-gray-500"}"}>
                <%= @char_count %>/280
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
