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
       l("Recent articles have been reset.") <> l(" You need to reload to see updates, if any.")
     )}
  end

  defp reset_limit(%{"limit" => limit}) when is_binary(limit), do: String.to_integer(limit)
  defp reset_limit(_), do: 5
end
