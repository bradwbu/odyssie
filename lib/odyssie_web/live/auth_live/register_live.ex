defmodule OdyssieWeb.AuthLive.RegisterLive do
  @moduledoc """
  Registration page LiveView.
  """

  use OdyssieWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:form, %{name: "", email: "", username: "", password: ""})
     |> assign(:errors, %{})
     |> assign(:loading, false)}
  end

  @impl true
  def handle_event("update_field", %{"field" => field, "value" => value}, socket) do
    form = Map.put(socket.assigns.form, field, value)
    {:noreply, assign(socket, form: form)}
  end

  def handle_event("register", _params, socket) do
    %{name: name, email: email, username: username, password: password} = socket.assigns.form

    attrs = %{
      display_name: name,
      email: email,
      username: username,
      password: password
    }

    case Odyssie.Accounts.register_user(attrs) do
      {:ok, user} ->
        {:ok, token} = Odyssie.Accounts.generate_session_token(user)

        {:noreply,
         socket
         |> redirect(to: "/session/set/#{token}")}

      {:error, changeset} ->
        errors =
          Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
            Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
              opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
            end)
          end)

        {:noreply,
         socket
         |> assign(:errors, errors)
         |> assign(:loading, false)}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen flex flex-col items-center justify-center px-4">
      <div class="w-full max-w-sm">
        <div class="text-center mb-8">
          <svg class="w-12 h-12 text-blue-500 mx-auto mb-4" viewBox="0 0 24 24" fill="currentColor">
            <path d="M23.643 4.937c-.835.37-1.732.62-2.675.733.962-.576 1.7-1.49 2.048-2.578-.9.534-1.897.922-2.958 1.13-.85-.904-2.06-1.47-3.4-1.47-2.572 0-4.658 2.086-4.658 4.66 0 .364.042.718.12 1.06-3.873-.195-7.304-2.05-9.602-4.868-.4.69-.63 1.49-.63 2.342 0 1.616.823 3.043 2.072 3.878-.764-.025-1.482-.234-2.11-.583v.06c0 2.257 1.605 4.14 3.737 4.568-.392.106-.803.162-1.227.162-.3 0-.593-.028-.877-.082.593 1.85 2.313 3.198 4.352 3.234-1.595 1.25-3.604 1.995-5.786 1.995-.376 0-.747-.022-1.112-.065 2.062 1.323 4.51 2.093 7.14 2.093 8.57 0 13.255-7.098 13.255-13.254 0-.2-.005-.402-.014-.602.91-.658 1.7-1.477 2.323-2.41z"/>
          </svg>
          <h1 class="text-3xl font-extrabold">Create your account</h1>
        </div>

        <form phx-submit="register" class="space-y-4">
          <div>
            <input type="text"
                   name="name"
                   value={@form.name}
                   placeholder="Name"
                   class={"w-full px-4 py-3 border rounded-lg focus:outline-none text-sm #{if @errors[:display_name], do: "border-red-500", else: "border-gray-300 focus:border-blue-500"}"}
                   phx-keyup="update_field"
                   phx-key="keyup"
                   phx-value-field="name"
                   required="true" />
            <%= if @errors[:display_name] do %>
              <p class="text-red-500 text-xs mt-1"><%= hd(@errors[:display_name]) %></p>
            <% end %>
          </div>

          <div>
            <input type="email"
                   name="email"
                   value={@form.email}
                   placeholder="Email"
                   class={"w-full px-4 py-3 border rounded-lg focus:outline-none text-sm #{if @errors[:email], do: "border-red-500", else: "border-gray-300 focus:border-blue-500"}"}
                   phx-keyup="update_field"
                   phx-key="keyup"
                   phx-value-field="email"
                   required="true" />
            <%= if @errors[:email] do %>
              <p class="text-red-500 text-xs mt-1"><%= hd(@errors[:email]) %></p>
            <% end %>
          </div>

          <div>
            <input type="text"
                   name="username"
                   value={@form.username}
                   placeholder="Username"
                   class={"w-full px-4 py-3 border rounded-lg focus:outline-none text-sm #{if @errors[:username], do: "border-red-500", else: "border-gray-300 focus:border-blue-500"}"}
                   phx-keyup="update_field"
                   phx-key="keyup"
                   phx-value-field="username"
                   required="true" />
            <%= if @errors[:username] do %>
              <p class="text-red-500 text-xs mt-1"><%= hd(@errors[:username]) %></p>
            <% end %>
          </div>

          <div>
            <input type="password"
                   name="password"
                   value={@form.password}
                   placeholder="Password (min 8 characters)"
                   class={"w-full px-4 py-3 border rounded-lg focus:outline-none text-sm #{if @errors[:password], do: "border-red-500", else: "border-gray-300 focus:border-blue-500"}"}
                   phx-keyup="update_field"
                   phx-key="keyup"
                   phx-value-field="password"
                   required="true" />
            <%= if @errors[:password] do %>
              <p class="text-red-500 text-xs mt-1"><%= hd(@errors[:password]) %></p>
            <% end %>
          </div>

          <button type="submit"
                  class="w-full bg-gray-900 hover:bg-gray-800 text-white font-bold py-3 rounded-full text-sm disabled:opacity-50 mt-6"
                  disabled={@form.email == "" or @form.password == "" or @form.username == "" or @form.name == ""}>
            Create account
          </button>
        </form>

        <div class="mt-6 text-center">
          <p class="text-gray-500 text-sm">
            Already have an account?
            <a href="/login" class="text-blue-500 hover:underline">Sign in</a>
          </p>
        </div>
      </div>
    </div>
    """
  end
end
