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

  alias Bonfire.Articles.PostsToArticlesMigration

  # what `use DataMigration` sets, which is not used here so that `up/0` can hand the runner this migration's repo
  @behaviour DataMigration
  @disable_ddl_transaction true
  @disable_migration_lock true

  # the migration's own repo, so the flip acts on the database being migrated
  def up, do: DataMigration.Runner.run(__MODULE__, repo: repo())

  def down, do: :ok

  @impl DataMigration
  def base_query, do: PostsToArticlesMigration.base_query()

  @impl DataMigration
  def config do
    %DataMigration.Config{batch_size: 200, throttle_ms: 100, repo: Bonfire.Common.Repo}
  end

  @impl DataMigration
  def migrate(rows, opts), do: PostsToArticlesMigration.migrate(rows, opts)
end
