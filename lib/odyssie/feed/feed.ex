defmodule Odyssie.Feed do
  @moduledoc """
  The Feed context - handles posts, likes, reposts, and timeline assembly.
  """

  import Ecto.Query
  alias Odyssie.Repo
  alias Odyssie.Feed.{Post, Like, Repost}
  alias Odyssie.Accounts.User

  # ── Post CRUD ─────────────────────────────────────────────────────────

  def create_post(%User{} = author, attrs) do
    result =
      %Post{}
      |> Post.changeset(Map.put(attrs, :author_id, author.id))
      |> Repo.insert()

    case result do
      {:ok, post} ->
        post = post |> Repo.preload(:author)

        update_author_post_count(author.id)
        maybe_notify_reply(post)
        maybe_notify_mentions(post)
        broadcast_new_post(post)
        maybe_broadcast_to_timeline(author.id, post)

        {:ok, post}

      error ->
        error
    end
  end

  def get_post(id) do
    Post
    |> Repo.get(id)
    |> maybe_preload_author()
  end

  def get_post!(id), do: Repo.get!(Post, id) |> maybe_preload_author()

  def delete_post(%Post{} = post) do
    Repo.delete(post)
  end

  # ── Likes ────────────────────────────────────────────────────────────

  def like_post(%User{id: user_id}, %Post{id: post_id} = post) do
    result =
      %Like{}
      |> Like.changeset(%{user_id: user_id, post_id: post_id})
      |> Repo.insert()

    case result do
      {:ok, like} ->
        Post
        |> where([p], p.id == ^post_id)
        |> Repo.update_all(inc: [likes_count: 1])

        if post.author_id != user_id do
          Phoenix.PubSub.broadcast(
            Odyssie.PubSub,
            "user:#{post.author_id}:notifications",
            {:new_notification, :like, user_id, post_id}
          )
        end

        {:ok, like}

      {:error, %Ecto.Changeset{errors: [{_, {_, constraint}}]}} when constraint == :unique ->
        {:error, :already_liked}

      error ->
        error
    end
  end

  def unlike_post(%User{id: user_id}, %Post{id: post_id}) do
    result =
      Like
      |> where([l], l.user_id == ^user_id and l.post_id == ^post_id)
      |> Repo.delete_all()

    case result do
      {1, _} ->
        Post
        |> where([p], p.id == ^post_id)
        |> Repo.update_all(inc: [likes_count: -1])
        {:ok, :unliked}

      {0, _} ->
        {:error, :not_liked}
    end
  end

  def liked?(%User{id: user_id}, %Post{id: post_id}) do
    Like
    |> where([l], l.user_id == ^user_id and l.post_id == ^post_id)
    |> Repo.exists?()
  end

  # ── Reposts ──────────────────────────────────────────────────────────

  def repost(%User{id: user_id} = user, %Post{id: post_id} = original_post) do
    result =
      %Repost{}
      |> Repost.changeset(%{user_id: user_id, post_id: post_id})
      |> Repo.insert()

    case result do
      {:ok, repost} ->
        Post
        |> where([p], p.id == ^post_id)
        |> Repo.update_all(inc: [reposts_count: 1])

        create_post(user, %{
          content: "",
          post_type: :repost,
          source_post_id: post_id
        })

        {:ok, repost}

      {:error, %Ecto.Changeset{errors: [{_, {_, constraint}}]}} when constraint == :unique ->
        {:error, :already_reposted}

      error ->
        error
    end
  end

  def unrepost(%User{id: user_id}, %Post{id: post_id}) do
    result =
      Repost
      |> where([r], r.user_id == ^user_id and r.post_id == ^post_id)
      |> Repo.delete_all()

    case result do
      {1, _} ->
        Post
        |> where([p], p.id == ^post_id)
        |> Repo.update_all(inc: [reposts_count: -1])

        Post
        |> where([p], p.author_id == ^user_id and p.source_post_id == ^post_id)
        |> Repo.delete_all()

        {:ok, :unreposted}

      {0, _} ->
        {:error, :not_reposted}
    end
  end

  def reposted?(%User{id: user_id}, %Post{id: post_id}) do
    Repost
    |> where([r], r.user_id == ^user_id and r.post_id == ^post_id)
    |> Repo.exists?()
  end

  # ── Timelines ────────────────────────────────────────────────────────

  def home_timeline(%User{} = user, opts \\ []) do
    limit = Keyword.get(opts, :limit, 20)
    cursor = Keyword.get(opts, :cursor)

    following_ids = Odyssie.Accounts.following_ids(user)

    base_query =
      Post
      |> where([p], p.author_id in ^following_ids)
      |> where([p], p.post_type in [:post, :quote])
      |> preload([:author])

    query =
      if cursor do
        base_query
        |> where([p], p.inserted_at < ^cursor)
      else
        base_query
      end

    posts =
      query
      |> order_by([p], desc: p.inserted_at)
      |> limit(^(limit + 1))
      |> Repo.all()

    has_more = length(posts) > limit
    posts = Enum.take(posts, limit)

    posts =
      posts
      |> Enum.map(fn post ->
        post
        |> Map.put(:liked_by_me, liked?(user, post))
        |> Map.put(:reposted_by_me, reposted?(user, post))
      end)

    %{
      posts: posts,
      has_more: has_more,
      next_cursor: if(has_more, do: List.last(posts).inserted_at)
    }
  end

  def user_timeline(%User{} = viewing_user, %User{} = profile_user, tab, opts \\ []) do
    limit = Keyword.get(opts, :limit, 20)
    cursor = Keyword.get(opts, :cursor)
    is_self = viewing_user.id == profile_user.id
    is_following = is_self or following?(viewing_user, profile_user)

    base_query =
      case {tab, profile_user.is_private, is_following} do
        {:likes, _, _} ->
          Like
          |> where([l], l.user_id == ^profile_user.id)
          |> join(:inner, [l], p in assoc(l, :post), as: :post)
          |> select([l, post: p], p)
          |> preload([:author])

        {:media, true, false} ->
          Post
          |> where([p], false)
          |> preload([:author])

        {:media, _, _} ->
          Post
          |> where([p], p.author_id == ^profile_user.id and not is_nil(p.media_urls))
          |> preload([:author])

        {_, true, false} ->
          Post
          |> where([p], false)
          |> preload([:author])

        {:replies, _, _} ->
          Post
          |> where([p], p.author_id == ^profile_user.id and p.post_type == :reply)
          |> preload([:author])

        {:posts, _, _} ->
          Post
          |> where([p], p.author_id == ^profile_user.id and p.post_type in [:post, :quote])
          |> preload([:author])
      end

    query =
      if cursor do
        base_query
        |> where([p], p.inserted_at < ^cursor)
      else
        base_query
      end

    posts =
      query
      |> order_by([p], desc: p.inserted_at)
      |> limit(^(limit + 1))
      |> Repo.all()

    has_more = length(posts) > limit
    posts = Enum.take(posts, limit)

    posts =
      posts
      |> Enum.map(fn post ->
        post
        |> Map.put(:liked_by_me, liked?(viewing_user, post))
        |> Map.put(:reposted_by_me, reposted?(viewing_user, post))
      end)

    %{
      posts: posts,
      has_more: has_more,
      next_cursor: if(has_more, do: List.last(posts).inserted_at)
    }
  end

  defp following?(%User{id: user_id}, %User{id: target_id}) do
    Odyssie.Accounts.following?(%User{id: user_id}, %User{id: target_id})
  end

  # ── Thread View ──────────────────────────────────────────────────────

  def get_thread(%Post{} = post) do
    parents = get_parent_chain(post.id)
    children = get_replies_tree(post.id)

    %{
      post: post,
      parents: parents,
      replies: children
    }
  end

  defp get_parent_chain(post_id, acc \\ []) do
    case Post |> Repo.get(post_id) |> maybe_preload_author() do
      nil ->
        Enum.reverse(acc)

      post ->
        case post.parent_id do
          nil -> Enum.reverse([post | acc])
          parent_id -> get_parent_chain(parent_id, [post | acc])
        end
    end
  end

  defp get_replies_tree(parent_id) do
    Post
    |> where([p], p.parent_id == ^parent_id and p.post_type == :reply)
    |> order_by([p], asc: p.inserted_at)
    |> preload([:author])
    |> Repo.all()
  end

  # ── Trending / Search ────────────────────────────────────────────────

  def search_posts(query_string, opts \\ []) do
    limit = Keyword.get(opts, :limit, 20)

    Post
    |> where([p], ilike(p.content, ^"%#{query_string}%"))
    |> order_by([p], desc: p.inserted_at)
    |> limit(^limit)
    |> preload([:author])
    |> Repo.all()
  end

  def trending_hashtags do
    one_week_ago = DateTime.utc_now() |> DateTime.add(-7, :day)

    Post
    |> where([p], p.inserted_at > ^one_week_ago)
    |> select([p], p.content)
    |> Repo.all()
    |> Enum.flat_map(&extract_hashtags/1)
    |> Enum.frequencies()
    |> Enum.sort_by(fn {_, count} -> count end, :desc)
    |> Enum.take(10)
  end

  defp extract_hashtags(content) do
    content
    |> String.split(~r/#[\w]+/)
    |> Enum.filter(&String.starts_with?(&1, "#"))
    |> Enum.map(&String.downcase/1)
  end

  # ── Private Helpers ──────────────────────────────────────────────────

  defp maybe_preload_author(nil), do: nil
  defp maybe_preload_author(post), do: Repo.preload(post, :author)

  defp update_author_post_count(user_id) do
    User
    |> where([u], u.id == ^user_id)
    |> Repo.update_all(inc: [posts_count: 1])
  end

  defp maybe_notify_reply(%Post{post_type: :reply, parent_id: parent_id, author_id: author_id}) when not is_nil(parent_id) do
    %{author_id: original_author_id} = get_post!(parent_id)

    if original_author_id != author_id do
      Phoenix.PubSub.broadcast(
        Odyssie.PubSub,
        "user:#{original_author_id}:notifications",
        {:new_notification, :reply, author_id, parent_id}
      )
    end
  end

  defp maybe_notify_reply(_), do: :ok

  defp maybe_notify_mentions(%Post{content: content, author_id: author_id, id: post_id}) do
    content
    |> Post.parse_content()
    |> Enum.filter(&(&1.type == :mention))
    |> Enum.each(fn %{username: username} ->
      case Odyssie.Accounts.get_user_by_username(username) do
        nil -> :ok
        %User{id: mentioned_id} when mentioned_id != author_id ->
          Phoenix.PubSub.broadcast(
            Odyssie.PubSub,
            "user:#{mentioned_id}:notifications",
            {:new_notification, :mention, author_id, post_id}
          )
        _ -> :ok
      end
    end)
  end

  defp broadcast_new_post(%Post{author_id: author_id} = post) do
    Phoenix.PubSub.broadcast(
      Odyssie.PubSub,
      "timeline:#{author_id}",
      {:new_post, post}
    )
  end

  defp maybe_broadcast_to_timeline(author_id, post) do
    Odyssie.Accounts.followers_ids(%User{id: author_id})
    |> Enum.each(fn follower_id ->
      Phoenix.PubSub.broadcast(
        Odyssie.PubSub,
        "home_timeline:#{follower_id}",
        {:new_home_post, post}
      )
    end)
  end
end
