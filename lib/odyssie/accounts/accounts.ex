defmodule Odyssie.Accounts do
  @moduledoc """
  The Accounts context - handles users, authentication, and the social graph.
  """

  import Ecto.Query
  alias Odyssie.Repo
  alias Odyssie.Accounts.{User, Follow, Token}

  # ── User Lookups ──────────────────────────────────────────────────────

  def get_user(id), do: Repo.get(User, id)
  def get_user!(id), do: Repo.get!(User, id)

  def get_user_by_username(username) do
    User
    |> where([u], u.username == ^username)
    |> Repo.one()
  end

  def get_user_by_email(email) do
    User
    |> where([u], ilike(u.email, ^email))
    |> Repo.one()
  end

  def get_user_for_session(encoded_token) do
    case Base.url_decode64(encoded_token, padding: false) do
      {:ok, token} ->
        now = DateTime.utc_now()

        Token
        |> join(:inner, [t], u in assoc(t, :user), as: :user)
        |> where([t, user: u], t.token == ^token and t.expires_at > ^now)
        |> select([t, user: u], u)
        |> Repo.one()

      :error ->
        nil
    end
  end

  # ── Registration ──────────────────────────────────────────────────────

  def register_user(attrs) do
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
  end

  # ── Profile Updates ──────────────────────────────────────────────────

  def update_profile(%User{} = user, attrs) do
    user
    |> User.profile_changeset(attrs)
    |> Repo.update()
  end

  # ── Password ─────────────────────────────────────────────────────────

  def authenticate_by_email_password(email, password) do
    user = get_user_by_email(email)

    cond do
      user && Bcrypt.verify_pass(password, user.password_hash) ->
        {:ok, user}

      user ->
        {:error, :invalid_password}

      true ->
        Bcrypt.no_user_verify()
        {:error, :not_found}
    end
  end

  # ── Tokens ───────────────────────────────────────────────────────────

  def generate_session_token(user) do
    token = :crypto.strong_rand_bytes(64)

    changeset =
      Token.changeset(%Token{}, %{
        token: token,
        context: "session",
        user_id: user.id,
        expires_at: DateTime.add(DateTime.utc_now(), 60 * 24 * 7, :second)
      })

    case Repo.insert(changeset) do
      {:ok, _} -> {:ok, Base.url_encode64(token, padding: false)}
      error -> error
    end
  end

  def delete_session_token(encoded_token) do
    case Base.url_decode64(encoded_token, padding: false) do
      {:ok, token} ->
        Token
        |> where([t], t.token == ^token)
        |> Repo.delete_all()

      :error ->
        {0, nil}
    end
  end

  # ── Social Graph ─────────────────────────────────────────────────────

  def follow(%User{id: follower_id}, %User{id: following_id}) do
    if follower_id == following_id do
      {:error, :cannot_follow_self}
    else
      result =
        %Follow{}
        |> Follow.changeset(%{follower_id: follower_id, following_id: following_id})
        |> Repo.insert()

      case result do
        {:ok, follow} ->
          increment_counts(follower_id, :following)
          increment_counts(following_id, :followers)
          broadcast_follow(follower_id, following_id)
          {:ok, follow}

        {:error, %Ecto.Changeset{errors: [{_, {_, constraint}}]}} when constraint == :unique ->
          {:error, :already_following}

        error ->
          error
      end
    end
  end

  def unfollow(%User{id: follower_id}, %User{id: following_id}) do
    result =
      Follow
      |> where([f], f.follower_id == ^follower_id and f.following_id == ^following_id)
      |> Repo.delete_all()

    case result do
      {1, _} ->
        decrement_counts(follower_id, :following)
        decrement_counts(following_id, :followers)
        {:ok, :unfollowed}

      {0, _} ->
        {:error, :not_following}
    end
  end

  def following?(%User{id: follower_id}, %User{id: following_id}) do
    Follow
    |> where([f], f.follower_id == ^follower_id and f.following_id == ^following_id)
    |> Repo.exists?()
  end

  def followers_ids(%User{id: user_id}) do
    Follow
    |> where([f], f.following_id == ^user_id)
    |> select([f], f.follower_id)
    |> Repo.all()
  end

  def following_ids(%User{id: user_id}) do
    Follow
    |> where([f], f.follower_id == ^user_id)
    |> select([f], f.following_id)
    |> Repo.all()
  end

  def get_follower_count(user_id) do
    User
    |> where([u], u.id == ^user_id)
    |> select([u], u.followers_count)
    |> Repo.one()
  end

  def get_following_count(user_id) do
    User
    |> where([u], u.id == ^user_id)
    |> select([u], u.following_count)
    |> Repo.one()
  end

  def followers(%User{id: user_id}, opts \\ []) do
    limit = Keyword.get(opts, :limit, 20)
    offset = Keyword.get(opts, :offset, 0)

    Follow
    |> where([f], f.following_id == ^user_id)
    |> order_by([f], desc: f.inserted_at)
    |> limit(^limit)
    |> offset(^offset)
    |> join(:inner, [f], u in assoc(f, :follower), as: :user)
    |> select([f, user: u], u)
    |> Repo.all()
  end

  def following(%User{id: user_id}, opts \\ []) do
    limit = Keyword.get(opts, :limit, 20)
    offset = Keyword.get(opts, :offset, 0)

    Follow
    |> where([f], f.follower_id == ^user_id)
    |> order_by([f], desc: f.inserted_at)
    |> limit(^limit)
    |> offset(^offset)
    |> join(:inner, [f], u in assoc(f, :following), as: :user)
    |> select([f, user: u], u)
    |> Repo.all()
  end

  # ── Private Helpers ──────────────────────────────────────────────────

  defp increment_counts(user_id, field) do
    User
    |> where([u], u.id == ^user_id)
    |> Repo.update_all(inc: [{field, 1}])
  end

  defp decrement_counts(user_id, field) do
    User
    |> where([u], u.id == ^user_id)
    |> Repo.update_all(inc: [{field, -1}])
  end

  def search_users(query_string, opts \\ []) do
    limit = Keyword.get(opts, :limit, 20)

    User
    |> where([u],
      ilike(u.username, ^"%#{query_string}%") or
        ilike(u.display_name, ^"%#{query_string}%")
    )
    |> limit(^limit)
    |> Repo.all()
  end

  defp broadcast_follow(follower_id, following_id) do
    Phoenix.PubSub.broadcast(
      Odyssie.PubSub,
      "user:#{following_id}:notifications",
      {:new_notification, :follow, follower_id, nil}
    )
  end
end
