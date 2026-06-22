defmodule Bonfire.UI.Articles.CreateArticleLive do
  @moduledoc """
  Composer entry for writing an Article. Reuses the full post composer
  (`Bonfire.UI.Social.WritePostContentLive`) — it only registers `:article` as a
  distinct smart-input type (so it appears in the composer picker) and forwards
  everything through, with the title field shown by default.
  """
  use Bonfire.UI.Common.Web, :stateless_component

  # mirror the props the post composer accepts so they can be forwarded
  prop reply_to_id, :any, default: nil
  prop context_id, :string, default: nil
  prop to_boundaries, :any, default: nil
  prop boundary_preset, :any, default: nil
  prop to_circles, :list, default: []
  prop exclude_circles, :list, default: []
  prop verb_permissions, :map, default: %{}
  prop mentions, :list, default: []
  prop smart_input_opts, :map, default: %{}
  prop showing_within, :atom, default: nil
  prop insert_text, :string, default: nil
  prop preloaded_recipients, :any, default: nil
  prop uploads, :any, default: nil
  prop uploaded_files, :list, default: nil
  prop title_prompt, :string, default: nil
  prop selected_cover, :any, default: nil
  prop open_boundaries, :boolean, default: false
  prop boundaries_modal_id, :string, default: :sidebar_composer
  prop reset_smart_input, :boolean, default: false
  prop preview_boundary_for_id, :any, default: nil
  prop preview_boundary_for_username, :any, default: nil
  prop preview_boundary_verbs, :list, default: []
  prop custom_emojis, :any, default: []
  prop quoted_url, :string, default: nil
  prop textarea_container_class, :css_class
  prop textarea_container_class_alpine, :string
  prop textarea_class, :css_class
  prop replied_activity_class, :css_class
  prop event_target, :any, default: nil

  @behaviour Bonfire.UI.Common.SmartInputModule
  def smart_input_module, do: [:article, Bonfire.Articles.Article]

  def smart_input_icon(_), do: "ph:article-ny-times-duotone"
  def smart_input_label(_), do: l("Article")
end
