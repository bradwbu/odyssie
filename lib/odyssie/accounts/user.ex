defmodule Odyssie.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "users" do
    field :username, :string
    field :display_name, :string
    field :email, :string
    field :password_hash, :string, redact: true
    field :password, :string, virtual: true, redact: true
    field :bio, :string
    field :location, :string
    field :website, :string
    field :avatar_url, :string
    field :header_url, :string
    field :is_verified, :boolean, default: false
    field :is_private, :boolean, default: false
    field :followers_count, :integer, default: 0
    field :following_count, :integer, default: 0
    field :posts_count, :integer, default: 0

    has_many :posts, Odyssie.Feed.Post, foreign_key: :author_id
    has_many :likes, Odyssie.Feed.Like
    has_many :reposts, Odyssie.Feed.Repost
    has_many :sent_messages, Odyssie.Chat.Message, foreign_key: :sender_id
    has_many :received_messages, Odyssie.Chat.Message, foreign_key: :recipient_id
    has_many :notifications, Odyssie.Notifications.Notification, foreign_key: :recipient_id

    field :following?, :boolean, virtual: true, default: false
    field :followed_by?, :boolean, virtual: true, default: false

    timestamps(type: :utc_datetime)
  end

  @required [:username, :email, :password]
  @optional [
    :display_name, :bio, :location, :website,
    :avatar_url, :header_url, :is_private
  ]

  def changeset(user, attrs) do
    user
    |> cast(attrs, @required ++ @optional)
    |> validate_required(@required)
    |> validate_username()
    |> validate_email()
    |> validate_password()
    |> validate_length(:bio, max: 160)
    |> validate_length(:display_name, max: 50)
    |> unique_constraint(:username)
    |> unique_constraint(:email)
  end

  def registration_changeset(user, attrs) do
    user
    |> changeset(attrs)
    |> hash_password()
  end

  def profile_changeset(user, attrs) do
    user
    |> cast(attrs, [:display_name, :bio, :location, :website, :avatar_url, :header_url, :is_private])
    |> validate_length(:bio, max: 160)
    |> validate_length(:display_name, max: 50)
  end

  defp validate_username(changeset) do
    changeset
    |> validate_format(:username, ~r/^[a-zA-Z0-9_]{1,15}$/,
      message: "must be 1-15 alphanumeric characters or underscores"
    )
  end

  defp validate_email(changeset) do
    changeset
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/,
      message: "must have the @ sign and no spaces"
    )
    |> validate_length(:email, max: 160)
  end

  defp validate_password(changeset) do
    changeset
    |> validate_length(:password, min: 8, max: 72)
  end

  defp hash_password(changeset) do
    case get_change(changeset, :password) do
      nil ->
        changeset

      password ->
        changeset
        |> put_change(:password_hash, Bcrypt.hash_pwd_salt(password))
        |> delete_change(:password)
    end
  end
end
