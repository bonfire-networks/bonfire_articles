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

  @doc """
  Formats an article for the search index. Reuses `Bonfire.Posts.indexing_object_format/1` (articles share the `PostContent` mixin) but stamps the Article `index_type` so articles are classified correctly. Dispatched to by `Bonfire.Search.Indexer.prepare_indexable_object/1` via the `ContextModule` registry, which routes `Article` structs here (not to `Bonfire.Posts`).
  """
  def indexing_object_format(object) do
    case Posts.indexing_object_format(object) do
      doc when is_map(doc) -> Map.put(doc, "index_type", Types.module_to_str(Article))
      other -> other
    end
  end

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

  # --- Recent-articles widget loader (cached per user + limit) ---

  @doc """
  Recent articles from followed users, for the "Recent Articles" widget. Cached per user and limit
  for 1h; the key is built once by `recent_cache_key/2` so the load and any reset always agree.
  Pass the standard `:cache` opt (`cache: :refresh` busts + recomputes — the widget's refresh button).
  """
  def list_recent(current_user, limit \\ 5, opts \\ []) do
    Cache.maybe_apply_cached(
      &do_list_recent/2,
      [current_user, limit],
      opts
      |> Keyword.put(:cache_key, recent_cache_key(current_user, limit))
      |> Keyword.put_new(:expire, :timer.minutes(60))
    )
  end

  defp do_list_recent(current_user, limit) do
    case Bonfire.Social.FeedActivities.feed(
           %{feed_name: :articles},
           current_user: current_user,
           paginate: %{limit: limit},
           preload: [:with_post_content, :with_subject, :with_media]
         ) do
      %{edges: edges} when is_list(edges) and edges != [] -> edges
      _ -> []
    end
  end

  @doc "Cache key for `list_recent/3` — used by both the loader and any reset, so they can't drift."
  def recent_cache_key(current_user, limit),
    do: "widget_recent_articles:#{id(current_user) || "guest"}:#{limit}"
end
