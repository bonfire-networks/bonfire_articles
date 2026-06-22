defmodule Bonfire.Articles.Repo.Migrations.PostsToArticles do
  @moduledoc """
  Backfill: convert existing long-form Posts into the new Article type by flipping
  their pointer `table_id`. Selection + flip logic lives in (and is tested via)
  `Bonfire.Articles.PostsToArticlesMigration`.

  Only `table_id` changes — the shared `bonfire_data_social_post_content`, activity,
  boundaries, etc. are keyed on the pointer id and preserved.
  """
  use Ecto.Migration
  alias EctoSparkles.DataMigration
  use DataMigration

  alias Bonfire.Articles.PostsToArticlesMigration

  @impl DataMigration
  def base_query, do: PostsToArticlesMigration.base_query()

  @impl DataMigration
  def config do
    %DataMigration.Config{batch_size: 200, throttle_ms: 100, repo: Bonfire.Common.Repo}
  end

  @impl DataMigration
  def migrate(rows), do: PostsToArticlesMigration.migrate(rows)
end
