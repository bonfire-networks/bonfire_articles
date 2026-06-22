defmodule Bonfire.Articles.Article do
  @moduledoc """
  A long-form Article. A `Needle.Virtual` (a DB view over the shared pointers
  table, filtered by `table_id`) that reuses the same `PostContent` mixin as
  `Bonfire.Data.Social.Post` — so an Article carries a title (`name`), `summary`
  and `html_body` exactly like a Post, but is a distinct, indexable type.

  Its associations (`:post_content`, `:activity`, `:created`, `:replied`, …) are
  injected via `config :bonfire_articles, Bonfire.Articles.Article, code: …` in
  `config/bonfire_data.exs`, mirroring `Bonfire.Data.Social.Post`.
  """
  use Needle.Virtual,
    otp_app: :bonfire_articles,
    table_id: "7ARTC1ESF0RB0NF1REP0STS000",
    source: "bonfire_data_social_article"

  alias Bonfire.Articles.Article
  alias Needle.Changesets

  virtual_schema do
  end

  def changeset(article \\ %Article{}, params), do: Changesets.cast(article, params, [])
end

defmodule Bonfire.Articles.Article.Migration do
  @moduledoc false
  import Needle.Migration
  alias Bonfire.Articles.Article

  def migrate_article(), do: migrate_virtual(Article)
end
