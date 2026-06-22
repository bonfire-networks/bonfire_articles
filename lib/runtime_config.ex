defmodule Bonfire.Articles.RuntimeConfig do
  use Bonfire.Common.Localise

  @behaviour Bonfire.Common.ConfigModule
  def config_module, do: true

  @doc """
  NOTE: you can override this default config in your app's `runtime.exs`, by placing similarly-named config keys below the `Bonfire.Common.Config.LoadExtensionsConfig.load_configs()` line
  """
  def config do
    import Config

    # Register the Article activity renderer, resolved dynamically by
    # `Bonfire.UI.Social.Activity.LiveHandler`/`component_for_object_type` — so
    # bonfire_ui_social renders Articles without a compile-time dep on this extension.
    config :bonfire, :ui,
      object_preview: [
        {:article, Bonfire.UI.Articles.ArticleLive}
      ]

    # Articles: title + summary shown by default (not togglable), plus the CW siren.
    config :bonfire_ui_common, Bonfire.UI.Common.InputControlsLive,
      enable_fields: [
        title: [article: [show_by_default: true]],
        summary: [article: [show_by_default: true]],
        sensitive: [article: [enable_toggle: true]]
      ]
  end
end
