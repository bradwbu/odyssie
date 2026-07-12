defmodule Odyssie.Notifications.Notification do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "notifications" do
    field :type, Ecto.Enum, values: [:like, :repost, :follow, :mention, :reply]
    field :read_at, :utc_datetime

    belongs_to :actor, Odyssie.Accounts.User
    belongs_to :recipient, Odyssie.Accounts.User
    belongs_to :post, Odyssie.Feed.Post

    timestamps(type: :utc_datetime)
  end

  @required [:type, :actor_id, :recipient_id]

  def changeset(notification, attrs) do
    notification
    |> cast(attrs, @required ++ [:post_id])
    |> validate_required(@required)
    |> foreign_key_constraint(:actor_id)
    |> foreign_key_constraint(:recipient_id)
    |> foreign_key_constraint(:post_id)
  end
end
