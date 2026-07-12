defmodule Odyssie.Feed.Post do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "posts" do
    field :content, :string
    field :likes_count, :integer, default: 0
    field :reposts_count, :integer, default: 0
    field :replies_count, :integer, default: 0

    field :post_type, Ecto.Enum,
      values: [:post, :reply, :repost, :quote],
      default: :post

    belongs_to :author, Odyssie.Accounts.User
    belongs_to :parent, Odyssie.Feed.Post
    belongs_to :source_post, Odyssie.Feed.Post

    has_many :replies, Odyssie.Feed.Post, foreign_key: :parent_id
    has_many :likes, Odyssie.Feed.Like
    has_many :reposts, Odyssie.Feed.Repost

    field :liked_by_me, :boolean, virtual: true, default: false
    field :reposted_by_me, :boolean, virtual: true, default: false
    field :author_followed, :boolean, virtual: true, default: false

    field :parsed_content, {:array, :map}, virtual: true

    timestamps(type: :utc_datetime)
  end

  @required [:content, :author_id]
  @optional [:parent_id, :source_post_id, :post_type]

  def changeset(post, attrs) do
    post
    |> cast(attrs, @required ++ @optional)
    |> validate_required(@required)
    |> validate_length(:content, max: 280)
    |> foreign_key_constraint(:author_id)
    |> foreign_key_constraint(:parent_id)
    |> foreign_key_constraint(:source_post_id)
  end

  @doc """
  Parses content for @mentions and #hashtags, returning tokenized segments.
  """
  def parse_content(nil), do: []
  def parse_content(content) when content == "", do: []

  def parse_content(content) do
    content
    |> String.split(~r/([@#][\w]+)/, include_captures: true, trim: true)
    |> Enum.map(fn
      <<"@" <> rest>> ->
        mention = "@" <> rest
        %{type: :mention, text: mention, username: String.downcase(rest)}

      <<"#" <> rest>> ->
        hashtag = "#" <> rest
        %{type: :hashtag, text: hashtag, tag: String.downcase(rest)}

      text ->
        %{type: :text, text: text}
    end)
  end
end
