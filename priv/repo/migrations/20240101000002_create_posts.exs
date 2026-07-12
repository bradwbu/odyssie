defmodule Odyssie.Repo.Migrations.CreatePosts do
  use Ecto.Migration

  def change do
    create table(:posts, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :content, :string, size: 280, null: false
      add :post_type, :string, null: false, default: "post"
      add :likes_count, :integer, default: 0, null: false
      add :reposts_count, :integer, default: 0, null: false
      add :replies_count, :integer, default: 0, null: false
      add :author_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :parent_id, references(:posts, type: :binary_id, on_delete: :nilify_all)
      add :source_post_id, references(:posts, type: :binary_id, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    create index(:posts, [:author_id])
    create index(:posts, [:parent_id])
    create index(:posts, [:source_post_id])
    create index(:posts, [:post_type])
    create index(:posts, [:inserted_at])
    create index(:posts, [:author_id, :inserted_at])
    create index(:posts, [:likes_count])
  end
end
