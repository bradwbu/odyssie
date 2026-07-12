defmodule OdyssieWeb.Layouts do
  @moduledoc """
  Layout components for the Odyssie application.
  Provides the 3-column Twitter-style layout.
  """

  use Phoenix.Component
  use Phoenix.VerifiedRoutes, endpoint: OdyssieWeb.Endpoint, router: OdyssieWeb.Router, statics: OdyssieWeb.static_paths()
  import Phoenix.Controller, only: [get_csrf_token: 0]

  def root(assigns) do
    ~H"""
    <!DOCTYPE html>
    <html lang="en">
      <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <meta name="csrf-token" content={get_csrf_token()} />
        <title>Odyssie</title>
        <link phx-track-static rel="stylesheet" href={~p"/assets/app.css"} />
        <script defer phx-track-static type="text/javascript" src={~p"/assets/app.js"}>
        </script>
      </head>
      <body class="bg-white">
        <%= @inner_content %>
      </body>
    </html>
    """
  end

  def app(assigns) do
    ~H"""
    <div class="min-h-screen flex justify-center">
      <div class="flex w-full max-w-[1280px]">
        <%!-- Left Sidebar --%>
        <aside class="hidden md:flex flex-col items-end xl:items-start w-[88px] xl:w-[275px] flex-shrink-0">
          <div class="fixed top-0 h-screen flex flex-col justify-between py-3 px-2 xl:pr-6">
            <div>
              <%!-- Logo --%>
              <a href="/home" class="flex items-center justify-center xl:justify-start p-3 rounded-full hover:bg-blue-50 mb-1">
                <svg class="w-8 h-8 text-blue-500" viewBox="0 0 24 24" fill="currentColor">
                  <path d="M23.643 4.937c-.835.37-1.732.62-2.675.733.962-.576 1.7-1.49 2.048-2.578-.9.534-1.897.922-2.958 1.13-.85-.904-2.06-1.47-3.4-1.47-2.572 0-4.658 2.086-4.658 4.66 0 .364.042.718.12 1.06-3.873-.195-7.304-2.05-9.602-4.868-.4.69-.63 1.49-.63 2.342 0 1.616.823 3.043 2.072 3.878-.764-.025-1.482-.234-2.11-.583v.06c0 2.257 1.605 4.14 3.737 4.568-.392.106-.803.162-1.227.162-.3 0-.593-.028-.877-.082.593 1.85 2.313 3.198 4.352 3.234-1.595 1.25-3.604 1.995-5.786 1.995-.376 0-.747-.022-1.112-.065 2.062 1.323 4.51 2.093 7.14 2.093 8.57 0 13.255-7.098 13.255-13.254 0-.2-.005-.402-.014-.602.91-.658 1.7-1.477 2.323-2.41z"/>
                </svg>
              </a>

              <%!-- Nav Items --%>
              <nav class="space-y-1">
                <a href="/home" class="flex items-center justify-center xl:justify-start p-3 rounded-full hover:bg-gray-100 text-xl group">
                  <svg class="w-7 h-7" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6"/>
                  </svg>
                  <span class="hidden xl:block ml-5 text-xl">Home</span>
                </a>

                <a href="/explore" class="flex items-center justify-center xl:justify-start p-3 rounded-full hover:bg-gray-100 text-xl group">
                  <svg class="w-7 h-7" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"/>
                  </svg>
                  <span class="hidden xl:block ml-5 text-xl">Explore</span>
                </a>

                <a href="/notifications" class="flex items-center justify-center xl:justify-start p-3 rounded-full hover:bg-gray-100 text-xl group relative">
                  <svg class="w-7 h-7" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9"/>
                  </svg>
                  <span class="hidden xl:block ml-5 text-xl">Notifications</span>
                  <%= if @unread_notifications > 0 do %>
                    <span class="absolute -top-1 -right-1 xl:static xl:ml-1 bg-blue-500 text-white text-xs rounded-full w-5 h-5 flex items-center justify-center">
                      <%= min(@unread_notifications, 9) %><%= if @unread_notifications > 9, do: "+" %>
                    </span>
                  <% end %>
                </a>

                <a href="/messages" class="flex items-center justify-center xl:justify-start p-3 rounded-full hover:bg-gray-100 text-xl group relative">
                  <svg class="w-7 h-7" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"/>
                  </svg>
                  <span class="hidden xl:block ml-5 text-xl">Messages</span>
                  <%= if @unread_messages > 0 do %>
                    <span class="absolute -top-1 -right-1 xl:static xl:ml-1 bg-blue-500 text-white text-xs rounded-full w-5 h-5 flex items-center justify-center">
                      <%= min(@unread_messages, 9) %><%= if @unread_messages > 9, do: "+" %>
                    </span>
                  <% end %>
                </a>

                <a href={"/#{@current_user.username}"} class="flex items-center justify-center xl:justify-start p-3 rounded-full hover:bg-gray-100 text-xl group">
                  <svg class="w-7 h-7" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"/>
                  </svg>
                  <span class="hidden xl:block ml-5 text-xl">Profile</span>
                </a>
              </nav>
            </div>

            <%!-- Post Button --%>
            <button class="bg-blue-500 hover:bg-blue-600 text-white font-bold py-3 px-4 xl:px-8 rounded-full w-full mt-4 mb-24"
                    phx-click="open_compose">
              <span class="hidden xl:block">Post</span>
              <svg class="w-6 h-6 xl:hidden mx-auto" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/>
              </svg>
            </button>
          </div>
        </aside>

        <%!-- Main Content --%>
        <main class="flex-1 min-h-screen border-l border-r border-gray-200 max-w-[600px]">
          <%= @inner_content %>
        </main>

        <%!-- Right Sidebar --%>
        <aside class="hidden lg:block w-[350px] flex-shrink-0 pl-6 pr-2">
          <div class="fixed top-0 h-screen overflow-y-auto py-3 w-[350px]">
            <%!-- Search Bar --%>
            <div class="relative mb-4">
              <svg class="w-5 h-5 absolute left-3 top-3 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"/>
              </svg>
              <input type="text" placeholder="Search Odyssie"
                     class="w-full bg-gray-100 rounded-full py-3 pl-12 pr-4 text-sm border border-transparent focus:border-blue-500 focus:bg-white focus:outline-none" />
            </div>

            <%!-- Trending --%>
            <div class="bg-gray-50 rounded-2xl mb-4 overflow-hidden">
              <h2 class="text-xl font-extrabold px-4 py-3">What's happening</h2>
              <div class="space-y-0">
                <a href="#" class="block px-4 py-3 hover:bg-gray-100">
                  <div class="text-gray-500 text-xs">Trending in Technology</div>
                  <div class="font-bold text-sm">#ElixirLang</div>
                  <div class="text-gray-500 text-xs">42.1K Posts</div>
                </a>
                <a href="#" class="block px-4 py-3 hover:bg-gray-100">
                  <div class="text-gray-500 text-xs">Trending in Programming</div>
                  <div class="font-bold text-sm">#PhoenixFramework</div>
                  <div class="text-gray-500 text-xs">18.3K Posts</div>
                </a>
                <a href="#" class="block px-4 py-3 hover:bg-gray-100">
                  <div class="text-gray-500 text-xs">Technology · Trending</div>
                  <div class="font-bold text-sm">#LiveView</div>
                  <div class="text-gray-500 text-xs">12.8K Posts</div>
                </a>
              </div>
              <a href="#" class="block px-4 py-3 text-blue-500 hover:bg-gray-100 text-sm">Show more</a>
            </div>

            <%!-- Who to follow --%>
            <div class="bg-gray-50 rounded-2xl overflow-hidden">
              <h2 class="text-xl font-extrabold px-4 py-3">Who to follow</h2>
              <div class="space-y-0">
                <div class="flex items-center justify-between px-4 py-3 hover:bg-gray-100">
                  <div class="flex items-center space-x-3">
                    <img src="/images/default-avatar.png" class="w-10 h-10 rounded-full" />
                    <div>
                      <div class="font-bold text-sm">Elixir Community</div>
                      <div class="text-gray-500 text-sm">@elixirlang</div>
                    </div>
                  </div>
                  <button class="bg-gray-900 text-white text-sm font-bold py-1.5 px-4 rounded-full hover:bg-gray-700">
                    Follow
                  </button>
                </div>
              </div>
              <a href="#" class="block px-4 py-3 text-blue-500 hover:bg-gray-100 text-sm">Show more</a>
            </div>
          </div>
        </aside>
      </div>
    </div>
    """
  end
end
