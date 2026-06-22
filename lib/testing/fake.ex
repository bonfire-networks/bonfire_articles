defmodule Bonfire.Articles.Fake do
  import Bonfire.Common.Simulation
  alias Bonfire.Articles

  @doc """
  Publishes a fake Article (long-form post with a title). Mirrors
  `Bonfire.Posts.Fake.fake_post!/4` but creates a `Bonfire.Articles.Article`.
  """
  def fake_article!(user, boundary \\ nil, attrs \\ nil, opts \\ []) do
    with {:ok, article} <-
           Articles.publish(
             [
               post_id: attrs[:id],
               current_user: user,
               post_attrs:
                 attrs ||
                   %{
                     post_content: %{
                       name: title(),
                       html_body: String.duplicate(markdown() <> " ", 5)
                     }
                   },
               boundary: boundary || "public",
               debug: true,
               crash: true
             ] ++ List.wrap(opts)
           ) do
      article
    else
      err -> raise "Failed to create fake article: #{inspect(err)}"
    end
  end
end
