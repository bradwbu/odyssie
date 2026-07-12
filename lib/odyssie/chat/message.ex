defmodule Odyssie.Chat.Message do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "messages" do
    field :body, :string
    field :read_at, :utc_datetime

    belongs_to :sender, Odyssie.Accounts.User
    belongs_to :recipient, Odyssie.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @required [:body, :sender_id, :recipient_id]

  def changeset(message, attrs) do
    message
    |> cast(attrs, @required)
    |> validate_required(@required)
    |> validate_length(:body, max: 10_000)
    |> foreign_key_constraint(:sender_id)
    |> foreign_key_constraint(:recipient_id)
  end
end
