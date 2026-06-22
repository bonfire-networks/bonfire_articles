defmodule Bonfire.Articles.Repo.Migrations.Articles do
  @moduledoc false
  use Ecto.Migration

  import Bonfire.Articles.Migrations

  def up, do: migrate_articles(:up)
  def down, do: migrate_articles(:down)
end
