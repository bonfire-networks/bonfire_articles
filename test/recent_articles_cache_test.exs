defmodule Bonfire.Articles.RecentArticlesCacheTest do
  @moduledoc "The recent articles widget's list is cached once for guests and once for everyone signed in (loaded as a member of the local users circle), not once per user, so a signed-in viewer's own restricted articles never reach another viewer."
  use Bonfire.Articles.DataCase, async: false
  use Bonfire.Common.Utils

  alias Bonfire.Articles
  alias Bonfire.Me.Fake

  @limit 20

  defp titles(edges), do: Enum.map(edges, &e(&1, :activity, :object, :post_content, :name, nil))

  test "everyone signed in shares one cache entry, and guests another" do
    alice = Fake.fake_user!()
    bob = Fake.fake_user!()

    assert Articles.recent_cache_key(alice, @limit) == Articles.recent_cache_key(bob, @limit)
    refute Articles.recent_cache_key(alice, @limit) == Articles.recent_cache_key(nil, @limit)
  end

  test "the signed-in list has local-only articles, the guest list doesn't, and neither has one only its author may see" do
    author = Fake.fake_user!()
    reader = Fake.fake_user!()

    fake_article!(author, "public", %{
      post_content: %{name: "Public recent article", html_body: "body"}
    })

    fake_article!(author, "local", %{
      post_content: %{name: "Local recent article", html_body: "body"}
    })

    fake_article!(author, "mentions", %{
      post_content: %{name: "Author-only recent article", html_body: "body"}
    })

    # loaded for the author first, the way a shared cache would be filled by whoever comes first
    signed_in = titles(Articles.list_recent(author, @limit, cache: :refresh))

    # the positive first
    assert "Public recent article" in signed_in
    assert "Local recent article" in signed_in
    # never in the shared list, or every other signed-in viewer would get it from the cache
    refute "Author-only recent article" in signed_in

    # another signed-in viewer gets the same list
    assert titles(Articles.list_recent(reader, @limit)) == signed_in

    guest = titles(Articles.list_recent(nil, @limit, cache: :refresh))

    assert "Public recent article" in guest
    refute "Local recent article" in guest
  end
end
