defmodule Bonfire.Articles do
  @moduledoc """
  Long-form Articles.

  Articles are a distinct, indexable type (`Bonfire.Articles.Article`, a
  `Needle.Virtual` with its own `table_id`) that reuse essentially all of
  `Bonfire.Posts`' logic — querying, publishing (same epic), reading, search,
  counts — by passing `schema: Article` through. Only what's genuinely unique to
  articles lives here: the schema and the ActivityPub `Article` federation.
  """
  use Arrows
  import Untangle
  use Bonfire.Common.Utils
  use Bonfire.Common.Repo
  alias Bonfire.Articles.Article
  alias Bonfire.Posts
  alias Bonfire.Common.Text

  @behaviour Bonfire.Common.QueryModule
  @behaviour Bonfire.Common.ContextModule
  def schema_module, do: Article
  def query_module, do: __MODULE__

  defp with_schema(opts), do: Keyword.put(to_options(opts), :schema, Article)

  @doc "Publishes an article (see `Bonfire.Posts.publish/1`)."
  def publish(opts), do: Posts.publish(with_schema(opts))
  def publish(article_attrs, opts), do: Posts.publish(article_attrs, with_schema(opts))

  @doc "Fetch an article by id, if permitted (see `Bonfire.Posts.read/2`)."
  def read(id, opts \\ []) when is_binary(id), do: Posts.read(id, with_schema(opts))

  def query(filters \\ [], opts \\ nil), do: Posts.query(filters, with_schema(opts || []))

  def query_paginated(filters \\ [], opts \\ []),
    do: Posts.query_paginated(filters, with_schema(opts))

  def list_paginated(filters, opts \\ []), do: Posts.list_paginated(filters, with_schema(opts))

  def list_by(by_user, opts \\ []), do: Posts.list_by(by_user, with_schema(opts))

  def search(search, opts \\ []), do: Posts.search(search, with_schema(opts))

  def delete(object, opts \\ []), do: Posts.delete(object, opts)

  def count_total(), do: repo().one(select(Article, [u], count(u.id)))

  # ActivityPub federation — Articles use the AP `Article` type, but otherwise reuse
  # the entire `Bonfire.Posts` federation pipeline.

  @behaviour Bonfire.Federate.ActivityPub.FederationModules
  def federation_module,
    do: [
      "Article",
      {"Create", "Article"},
      {"Update", "Article"}
    ]

  @doc "Federate an Article out as an AP `Article` (see `Bonfire.Posts.ap_publish_activity/4`)."
  def ap_publish_activity(subject, verb, article, opts \\ []) do
    Posts.ap_publish_activity(
      subject,
      verb,
      article,
      Keyword.put(opts, :ap_object_transform, &to_ap_article/2)
    )
  end

  @doc """
  Reshapes the AP object built by `Bonfire.Posts` (a `Note`) into an `Article`: sets
  `type`, derives a `summary`, embeds a Mastodon-compatible `preview` Note, and adds
  a `url`. Wired into the post federation pipeline via the `:ap_object_transform` hook.
  """
  def to_ap_article(object, url) do
    name = object["name"]
    content = object["content"]

    summary =
      object["summary"] ||
        Text.sentence_truncate(Text.text_only(Text.maybe_markdown_to_html(content || "")), 500)

    # simplified preview Note (for platforms like Mastodon that render the preview)
    preview =
      %{
        "type" => "Note",
        "name" => name,
        "summary" => summary,
        "content" => content
      }
      |> Enum.filter(fn {_, v} -> not is_nil(v) end)
      |> Enum.into(%{})

    object
    |> Map.put("type", "Article")
    |> Map.put("summary", summary)
    |> Map.put("content", content)
    |> Map.put("url", url)
    |> Map.put("preview", preview)
  end

  @doc "Receive an incoming AP `Article` and create a local Article (see `Bonfire.Posts.ap_receive_activity/4`)."
  def ap_receive_activity(creator, activity, object, opts \\ []) do
    Posts.ap_receive_activity(creator, activity, object, Keyword.put(opts, :schema, Article))
  end
end
