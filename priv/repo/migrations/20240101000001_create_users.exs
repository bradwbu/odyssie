defmodule Odyssie.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :username, :string, null: false
      add :display_name, :string
      add :email, :string, null: false
      add :password_hash, :string, null: false
      add :bio, :string, size: 160
      add :location, :string
      add :website, :string
      add :avatar_url, :string
      add :header_url, :string
      add :is_verified, :boolean, default: false, null: false
      add :is_private, :boolean, default: false, null: false
      add :followers_count, :integer, default: 0, null: false
      add :following_count, :integer, default: 0, null: false
      add :posts_count, :integer, default: 0, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:users, [:username])
    create unique_index(:users, [:email])
    create index(:users, [:followers_count])
    create index(:users, [:posts_count])
  end
end
