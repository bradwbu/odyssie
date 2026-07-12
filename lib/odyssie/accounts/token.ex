defmodule Odyssie.Accounts.Token do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "tokens" do
    field :token, :binary, redact: true
    field :context, :string
    field :sent_to, :string
    field :expires_at, :utc_datetime

    belongs_to :user, Odyssie.Accounts.User

    timestamps(type: :utc_datetime)
  end

  def changeset(token, attrs) do
    token
    |> cast(attrs, [:token, :context, :sent_to, :expires_at, :user_id])
    |> validate_required([:token, :context, :user_id])
    |> foreign_key_constraint(:user_id)
  end
end
