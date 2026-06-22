defmodule Bonfire.Articles.PostsToArticlesMigrationTest do
  use Bonfire.Articles.DataCase, async: true
  use Bonfire.Common.Utils

  alias Bonfire.Articles
  alias Bonfire.Articles.Article
  alias Bonfire.Articles.PostsToArticlesMigration
  alias Bonfire.Common.Types
  alias Bonfire.Common.Repo
  alias Bonfire.Me.Fake

  # > 888 chars
  @long_body String.duplicate("This is some long-form article content. ", 50)

  setup do
    user = Fake.fake_user!()

    long = fake_post!(user, "public", %{post_content: %{name: "A title", html_body: @long_body}})
    short = fake_post!(user, "public", %{post_content: %{html_body: "too short"}})

    titled_short =
      fake_post!(user, "public", %{post_content: %{name: "A title", html_body: "too short"}})

    reply =
      fake_post!(
        user,
        "public",
        %{post_content: %{name: "A title", html_body: @long_body}, reply_to_id: long.id}
      )

    {:ok, user: user, long: long, short: short, titled_short: titled_short, reply: reply}
  end

  test "base_query selects only qualifying long posts (title + long body, not a reply)", ctx do
    # all start out as Posts
    assert Types.object_type(ctx.long) == Bonfire.Data.Social.Post

    # base_query runs on the raw `pointers_pointer` table, so ids come back as raw
    # binary UUIDs — compare against the dumped form of each ULID.
    selected = Enum.map(Repo.all(PostsToArticlesMigration.base_query()), & &1.id)

    assert Needle.ULID.dump!(ctx.long.id) in selected
    refute Needle.ULID.dump!(ctx.short.id) in selected
    refute Needle.ULID.dump!(ctx.titled_short.id) in selected
    refute Needle.ULID.dump!(ctx.reply.id) in selected
  end

  test "running the migration flips qualifying posts to Article, leaving others as Post", ctx do
    PostsToArticlesMigration.migrate(Repo.all(PostsToArticlesMigration.base_query()))

    # the long post is now an Article (found via Articles.read, which queries the Article view)
    assert {:ok, migrated} =
             Articles.read(ctx.long.id, current_user: ctx.user, skip_boundary_check: true)

    assert Types.object_type(migrated) == Article
    assert migrated.post_content.name == "A title"

    # the short post is untouched
    assert {:ok, still_post} =
             Bonfire.Posts.read(ctx.short.id, current_user: ctx.user, skip_boundary_check: true)

    assert Types.object_type(still_post) == Bonfire.Data.Social.Post
  end
end
