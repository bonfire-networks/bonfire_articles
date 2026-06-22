defmodule Bonfire.Articles.PostsToArticlesMigration do
  @moduledoc """
  Logic for the one-off backfill that converts existing long-form Posts into the
  Article type (by flipping their pointer `table_id`). Kept in `lib/` (rather than
  inline in the migration file) so it's unit-testable. The migration file delegates
  here.

  Qualifying = currently a Post, has a title (`name` length > 2), a body longer than
  the (now-retired) article character threshold, and is not a reply.
  """
  import Ecto.Query

  @article_char_threshold 888
  @post_table_id "30NF1REP0STTAB1ENVMBER0NEE"
  @article_table_id "7ARTC1ESF0RB0NF1REP0STS000"

  @doc "Selects the ids of Posts that qualify to become Articles."
  def base_query do
    from(pp in "pointers_pointer",
      join: pc in "bonfire_data_social_post_content",
      on: pp.id == pc.id,
      left_join: r in "bonfire_data_social_replied",
      on: pp.id == r.id,
      where: pp.table_id == ^Needle.ULID.dump!(@post_table_id),
      where: fragment("length(?)", pc.name) > 2,
      where: fragment("char_length(?)", pc.html_body) > ^@article_char_threshold,
      where: is_nil(r.reply_to_id),
      select: %{id: pp.id}
    )
  end

  @doc "Flips the given pointer rows' `table_id` from Post to Article."
  def migrate(rows) do
    ids = Enum.map(rows, & &1.id)

    Bonfire.Common.Repo.update_all(
      from(pp in "pointers_pointer", where: pp.id in ^ids),
      set: [table_id: Needle.ULID.dump!(@article_table_id)]
    )
  end
end
