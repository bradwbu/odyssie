defmodule Odyssie.Repo.Migrations.CreateReposts do
  use Ecto.Migration

  def change do
    create table(:reposts, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :post_id, references(:posts, type: :binary_id, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:reposts, [:user_id])
    create index(:reposts, [:post_id])
    create unique_index(:reposts, [:user_id, :post_id])
  end
end
