defmodule Bonfire.UI.Articles.ArticleLive do
  @moduledoc "Renders an Article activity. Moved here from bonfire_ui_social; resolved dynamically via the `:object_preview` registry so bonfire_ui_social needs no compile-time dep on this extension."
  use Bonfire.UI.Common.Web, :stateless_component
  alias Bonfire.Common.Text

  prop object, :any
  # prop profile, :any, default: nil
  prop activity, :any, default: nil
  prop subject, :any, default: nil
  prop primary_image, :any, default: nil
  # `:widget` layout only — :side (thumbnail beside text) or :bottom (full-width below)
  prop image_position, :atom, default: :side
  prop viewing_main_object, :boolean, default: false
  prop showing_within, :atom, default: nil
  prop cw, :boolean, default: nil
  prop is_remote, :boolean, default: false
  prop thread_title, :any, default: nil
  # prop thread_mode, :atom, default: nil
  prop hide_actions, :boolean, default: false
  prop activity_inception, :boolean, default: false
  prop activity_component_id, :string, default: nil
  prop parent_id, :any, default: nil

  def preloads(),
    do: [
      :post_content,
      :language
    ]

  def post_content(object) do
    e(object, :post_content, nil) || object
    # |> debug("activity_note_object")
  end

  @doc """
  Resolves an article's byline author, preferring the creator stored on the article over contextual subjects such as a profile-feed owner or booster.

  ## Examples

      iex> author = %{id: "author"}
      iex> feed_owner = %{id: "feed-owner"}
      iex> activity = %{subject: %{id: "booster"}}
      iex> Bonfire.UI.Articles.ArticleLive.resolve_author(%{created: %{creator: author}}, feed_owner, activity)
      %{id: "author"}
  """
  def resolve_author(object, subject, activity) do
    e(object, :created, :creator, nil) || e(object, :creator, nil) || subject ||
      e(activity, :subject, nil)
  end

  @doc "Truncates preview copy at a word boundary and uses a typographic ellipsis."
  def maybe_truncate(input, skip \\ false, length \\ 800)

  def maybe_truncate(input, skip, length) when skip != true and is_binary(input) do
    Text.sentence_truncate(input, length, "…")
  end

  def maybe_truncate(input, _skip, _length), do: input
end
