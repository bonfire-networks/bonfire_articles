defmodule Bonfire.Articles.ArticlesTest do
  use Bonfire.Articles.DataCase, async: true
  use Bonfire.Common.Utils

  alias Bonfire.Articles
  alias Bonfire.Articles.Article
  alias Bonfire.UI.Articles.ArticleLive
  alias Bonfire.Social.FeedLoader
  alias Bonfire.Common.Types
  alias Bonfire.Me.Fake

  @article_attrs %{post_content: %{name: "My article title", html_body: "Some long-form body."}}

  test "article preview truncation ends at a word boundary with a typographic ellipsis" do
    assert ArticleLive.maybe_truncate("A complete phrase with trailing words", false, 20) ==
             "A complete phrase…"
  end

  test "publishing an article creates a Bonfire.Articles.Article (not a Post)" do
    user = Fake.fake_user!()
    article = fake_article!(user, "public", @article_attrs)

    assert Types.object_type(article) == Article
    assert {:ok, read} = Articles.read(article.id, current_user: user)
    assert read.id == article.id
    assert read.post_content.name == "My article title"
  end

  test "a short post is NOT an article" do
    user = Fake.fake_user!()
    post = fake_post!(user, "public", %{post_content: %{html_body: "just a quick note"}})

    refute Types.object_type(post) == Article
  end

  test "articles feed contains articles but not plain notes" do
    user = Fake.fake_user!()
    article = fake_article!(user, "public", @article_attrs)
    note = fake_post!(user, "public", %{post_content: %{html_body: "just a quick note"}})

    articles_feed =
      FeedLoader.feed(:custom, %{object_types: ["article"]}, current_user: user)

    assert FeedLoader.feed_contains?(articles_feed, article, current_user: user)
    refute FeedLoader.feed_contains?(articles_feed, note, current_user: user)

    posts_feed =
      FeedLoader.feed(:custom, %{object_types: ["post"]}, current_user: user)

    assert FeedLoader.feed_contains?(posts_feed, note, current_user: user)
    refute FeedLoader.feed_contains?(posts_feed, article, current_user: user)
  end

  test "a published article is formatted for search indexing (with the Article index_type)" do
    user = Fake.fake_user!()

    article =
      fake_article!(user, "public", @article_attrs)
      |> repo().maybe_preload([:post_content, :activity])

    # precondition: we're exercising the Article dispatch path, not a Post
    assert Types.object_type(article) == Article

    doc = Bonfire.Search.Indexer.prepare_indexable_object(article)

    assert is_map(doc), "expected an indexable doc, got: #{inspect(doc)}"
    assert doc["index_type"] == Types.module_to_str(Article)
    assert doc["post_content"]["name"] == "My article title"
    assert doc["post_content"]["html_body"] =~ "Some long-form body."
  end
end
