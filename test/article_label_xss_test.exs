defmodule Bonfire.Articles.ArticleLabelXSSTest do
  @moduledoc """
  The caption of an article's cover is the media label (a link's unfurled title, or the `name` of a remote attachment): text kept as received, so it must be shown escaped, never as HTML.
  """
  use Bonfire.Articles.DataCase, async: true
  use Surface.LiveViewTest

  alias Bonfire.UI.Articles.ArticleLive

  @moduletag :ui

  @payload "<img src=x onerror=alert(1)>"

  defp cover(metadata) do
    struct(
      Bonfire.Files.Media,
      id: "01HZZ0ArticleXSSMediaTEST",
      path: "https://remote.local/cover.png",
      media_type: "image/png",
      metadata: metadata
    )
  end

  defp object, do: %{post_content: %{name: "Title", html_body: "<p>Body</p>"}}

  # the reading view (a main object in a thread)
  defp render_article(cover, :reading) do
    assigns = %{object: object(), cover: cover}

    render_surface do
      ~F"""
      <ArticleLive
        object={@object}
        primary_image={@cover}
        showing_within={:thread}
        viewing_main_object
      />
      """
    end
  end

  # the feed preview card
  defp render_article(cover, :preview) do
    assigns = %{object: object(), cover: cover}

    render_surface do
      ~F"""
      <ArticleLive object={@object} primary_image={@cover} />
      """
    end
  end

  defp label_variants(label) do
    [
      {"unfurled title", %{"title" => label}},
      {"remote attachment name", %{"json_ld" => %{"attachment" => %{"name" => label}}}}
    ]
  end

  for view <- [:reading, :preview] do
    test "a hostile cover caption renders without a live onerror (#{view} view)" do
      for {source, metadata} <- label_variants(@payload) do
        refute render_article(cover(metadata), unquote(view)) =~ ~r/<img[^>]*onerror/i,
               "#{source} was rendered as HTML"
      end
    end

    test "a plain cover caption is shown (#{view} view, control)" do
      for {source, metadata} <- label_variants("A plain caption") do
        assert render_article(cover(metadata), unquote(view)) =~ "A plain caption",
               "#{source} not shown"
      end
    end
  end
end
