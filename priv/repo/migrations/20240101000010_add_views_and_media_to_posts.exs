defmodule Odyssie.Repo.Migrations.AddViewsAndMediaToPosts do
  use Ecto.Migration

  def change do
    alter table(:posts) do
      add :views_count, :integer, default: 0, null: false
      add :media_urls, {:array, :string}, default: []
    end
  end
end
