defmodule Odyssie.Feed.Like do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "likes" do
    belongs_to :user, Odyssie.Accounts.User
    belongs_to :post, Odyssie.Feed.Post

    timestamps(type: :utc_datetime)
  end

  def changeset(like, attrs) do
    like
    |> cast(attrs, [:user_id, :post_id])
    |> validate_required([:user_id, :post_id])
    |> unique_constraint([:user_id, :post_id],
      name: :likes_user_id_post_id_index
    )
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:post_id)
  end
end
