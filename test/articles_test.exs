defmodule Bonfire.Articles.ArticlesTest do
  use Bonfire.Articles.DataCase, async: true
  use Bonfire.Common.Utils

  alias Bonfire.Articles
  alias Bonfire.Articles.Article
  alias Bonfire.Social.FeedLoader
  alias Bonfire.Common.Types
  alias Bonfire.Me.Fake

  @article_attrs %{post_content: %{name: "My article title", html_body: "Some long-form body."}}

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
end
