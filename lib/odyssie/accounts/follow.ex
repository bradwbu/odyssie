defmodule Odyssie.Accounts.Follow do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "follows" do
    field :follower_id, :binary_id
    field :following_id, :binary_id

    timestamps(type: :utc_datetime)
  end

  def changeset(follow, attrs) do
    follow
    |> cast(attrs, [:follower_id, :following_id])
    |> validate_required([:follower_id, :following_id])
    |> unique_constraint([:follower_id, :following_id],
      name: :follows_follower_id_following_id_index
    )
    |> foreign_key_constraint(:follower_id)
    |> foreign_key_constraint(:following_id)
  end
end
