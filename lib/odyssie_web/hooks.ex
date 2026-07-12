defmodule OdyssieWeb.Hooks do
  @moduledoc """
  LiveView on_mount hooks for authentication and session management.
  """

  import Phoenix.LiveView
  import Phoenix.Component

  def on_mount(:require_user, _params, %{"user_token" => token}, socket) do
    case Odyssie.Accounts.get_user_for_session(token) do
      nil ->
        {:halt, redirect(socket, to: "/login")}

      user ->
        socket =
          socket
          |> assign(:current_user, user)
          |> assign(:unread_messages, Odyssie.Chat.unread_count(user))
          |> assign(:unread_notifications, Odyssie.Notifications.unread_count(user))

        {:cont, socket}
    end
  end

  def on_mount(:require_user, _params, _session, socket) do
    {:halt, redirect(socket, to: "/login")}
  end

  def on_mount(:require_no_user, _params, %{"user_token" => token}, socket) do
    case Odyssie.Accounts.get_user_for_session(token) do
      nil ->
        {:cont, socket}

      _user ->
        {:halt, redirect(socket, to: "/home")}
    end
  end

  def on_mount(:require_no_user, _params, _session, socket) do
    {:cont, socket}
  end
end
