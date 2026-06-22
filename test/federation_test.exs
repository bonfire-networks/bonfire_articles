defmodule Bonfire.Articles.FederationTest do
  use Bonfire.Articles.DataCase, async: true

  alias Bonfire.Articles
  alias Bonfire.Posts

  test "federation responsibility is split: Posts handles Note, Articles handles Article" do
    post_types = Posts.federation_module()
    article_types = Articles.federation_module()

    assert "Note" in post_types
    refute "Article" in post_types
    refute {"Create", "Article"} in post_types

    assert "Article" in article_types
    assert {"Create", "Article"} in article_types
    assert {"Update", "Article"} in article_types
  end

  test "to_ap_article enriches an AP Note object into an Article (type, summary, preview, url)" do
    note = %{
      "type" => "Note",
      "name" => "My title",
      "content" => "<p>Some long-form body content for the article.</p>"
    }

    article = Articles.to_ap_article(note, "https://example.com/articles/123")

    assert article["type"] == "Article"
    assert article["url"] == "https://example.com/articles/123"
    assert is_binary(article["summary"]) and article["summary"] != ""
    assert article["preview"]["type"] == "Note"
    assert article["preview"]["name"] == "My title"
  end
end
