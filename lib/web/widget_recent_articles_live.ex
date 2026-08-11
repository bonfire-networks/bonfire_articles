defmodule Bonfire.UI.Articles.WidgetRecentArticlesLive do
  @moduledoc """
  A widget displaying recent articles from followed users.

  Shows the most recent articles (posts with title + substantial content)
  from users the current user follows, without subject or action buttons.
  Results are cached per user and limit for 1 hour to avoid reloading on
  every LiveView render.
  """
  use Bonfire.UI.Common.Web, :stateless_component

  prop limit, :integer, default: 5
  prop widget_title, :string, default: nil
  prop image_position, :atom, default: :side, values: [:side, :bottom]

  @doc "Delegates to the cached `Bonfire.Articles.list_recent/2`; wraps in the UI's `[articles: …]` shape."
  def load(current_user, limit \\ 5),
    do: [articles: Bonfire.Articles.list_recent(current_user, limit)]

  @doc "Busts the recent-articles cache for the current viewer (recomputed lazily on next read)."
  def handle_event("reset_recent_articles", params, socket) do
    Bonfire.Articles.list_recent(current_user(socket), reset_limit(params), cache: :reset)

    {:noreply,
     assign_flash(
       socket,
       :info,
       l("Recent articles have been reset.") <>
         " " <> l("You need to reload to see updates, if any.")
     )}
  end

  defp reset_limit(%{"limit" => limit}) when is_binary(limit), do: String.to_integer(limit)
  defp reset_limit(_), do: 5

  defp article_preview_id(activity, object) do
    deterministic_dom_id(
      __MODULE__,
      id(activity) || id(object) || "no-id",
      "article_preview"
    )
  end

  defp article_permalink(object) do
    case path(object, [], preload_if_needed: false) do
      permalink when is_binary(permalink) -> "#{permalink}#"
      _ -> nil
    end
  end

  defp article_title(object) do
    e(Bonfire.UI.Articles.ArticleLive.post_content(object), :name, nil) || l("Discussion")
  end

  defp article_preview_modal_assigns(activity, object, permalink) do
    object_id = id(object)
    activity_id = id(activity) || object_id
    replied = e(activity, :replied, nil) || e(object, :replied, nil)
    thread_id = e(replied, :thread_id, nil) || id(e(replied, :thread, nil))
    reply_to = e(replied, :reply_to, nil)

    Bonfire.UI.Social.ActivityLive.thread_preview_modal_assigns(
      thread_id,
      object_id,
      activity_id,
      activity,
      object,
      reply_to
    ) ++
      [
        post_id: thread_id || object_id,
        current_url: permalink,
        cw: false
      ]
  end
end
