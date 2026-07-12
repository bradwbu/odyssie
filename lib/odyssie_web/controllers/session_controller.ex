defmodule OdyssieWeb.SessionController do
  use OdyssieWeb, :controller

  def create(conn, %{"email" => email, "password" => password}) do
    case Odyssie.Accounts.authenticate_by_email_password(email, password) do
      {:ok, user} ->
        {:ok, token} = Odyssie.Accounts.generate_session_token(user)

        conn
        |> put_session(:user_token, token)
        |> put_resp_header("location", "/")
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{status: "ok"}))

      {:error, _reason} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(401, Jason.encode!(%{error: "Invalid email or password"}))
    end
  end

  def delete(conn, _params) do
    token = get_session(conn, :user_token)

    if token do
      Odyssie.Accounts.delete_session_token(token)
    end

    conn
    |> configure_session(drop: true)
    |> put_resp_header("location", "/login")
    |> send_resp(302, "")
  end
end
