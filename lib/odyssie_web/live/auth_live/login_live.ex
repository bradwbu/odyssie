defmodule OdyssieWeb.AuthLive.LoginLive do
  @moduledoc """
  Login page LiveView.
  """

  use OdyssieWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:email, "")
     |> assign(:password, "")
     |> assign(:error, nil)
     |> assign(:loading, false)}
  end

  @impl true
  def handle_event("update", %{"email" => email, "password" => password}, socket) do
    {:noreply,
     socket
     |> assign(:email, email)
     |> assign(:password, password)}
  end

  def handle_event("update", %{"email" => email}, socket) do
    {:noreply, assign(socket, :email, email)}
  end

  def handle_event("update", %{"password" => password}, socket) do
    {:noreply, assign(socket, :password, password)}
  end

  def handle_event("login", %{"email" => email, "password" => password}, socket) do
    case Odyssie.Accounts.authenticate_by_email_password(email, password) do
      {:ok, user} ->
        {:ok, token} = Odyssie.Accounts.generate_session_token(user)

        {:noreply,
         socket
         |> redirect(to: "/session/set/#{token}")}

      {:error, reason} ->
        {:noreply,
         socket
         |> assign(:error, format_error(reason))
         |> assign(:email, email)
         |> assign(:password, "")
         |> assign(:loading, false)}
    end
  end

  defp format_error(:invalid_password), do: "Invalid email or password"
  defp format_error(:not_found), do: "No account found with that email"
  defp format_error(_), do: "Something went wrong"

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen flex flex-col items-center justify-center px-4">
      <div class="w-full max-w-sm">
        <div class="text-center mb-8">
          <svg class="w-12 h-12 text-blue-500 mx-auto mb-4" viewBox="0 0 24 24" fill="currentColor">
            <path d="M23.643 4.937c-.835.37-1.732.62-2.675.733.962-.576 1.7-1.49 2.048-2.578-.9.534-1.897.922-2.958 1.13-.85-.904-2.06-1.47-3.4-1.47-2.572 0-4.658 2.086-4.658 4.66 0 .364.042.718.12 1.06-3.873-.195-7.304-2.05-9.602-4.868-.4.69-.63 1.49-.63 2.342 0 1.616.823 3.043 2.072 3.878-.764-.025-1.482-.234-2.11-.583v.06c0 2.257 1.605 4.14 3.737 4.568-.392.106-.803.162-1.227.162-.3 0-.593-.028-.877-.082.593 1.85 2.313 3.198 4.352 3.234-1.595 1.25-3.604 1.995-5.786 1.995-.376 0-.747-.022-1.112-.065 2.062 1.323 4.51 2.093 7.14 2.093 8.57 0 13.255-7.098 13.255-13.254 0-.2-.005-.402-.014-.602.91-.658 1.7-1.477 2.323-2.41z"/>
          </svg>
          <h1 class="text-3xl font-extrabold">Sign in to Odyssie</h1>
        </div>

        <%= if @error do %>
          <div class="bg-red-50 border border-red-200 text-red-600 px-4 py-3 rounded-lg mb-4 text-sm">
            <%= @error %>
          </div>
        <% end %>

        <form phx-submit="login" phx-change="update" class="space-y-4">
          <div>
            <input type="email"
                   name="email"
                   value={@email}
                   placeholder="Email address"
                   class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:outline-none focus:border-blue-500 text-sm"
                   required="true" />
          </div>

          <div>
            <input type="password"
                   name="password"
                   value={@password}
                   placeholder="Password"
                   class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:outline-none focus:border-blue-500 text-sm"
                   required="true" />
          </div>

          <button type="submit"
                  class="w-full bg-gray-900 hover:bg-gray-800 text-white font-bold py-3 rounded-full text-sm disabled:opacity-50"
                  disabled={@email == "" or @password == ""}>
            Sign in
          </button>
        </form>

        <div class="mt-6 text-center">
          <p class="text-gray-500 text-sm">
            Don't have an account?
            <a href="/signup" class="text-blue-500 hover:underline">Sign up</a>
          </p>
        </div>
      </div>
    </div>
    """
  end
end
