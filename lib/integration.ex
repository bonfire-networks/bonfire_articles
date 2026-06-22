defmodule Bonfire.Articles.Integration do
  use Arrows
  use Bonfire.Common.Config
  use Bonfire.Common.Utils

  declare_extension("Articles",
    icon: "ph:article-ny-times-duotone",
    emoji: "📰",
    description: l("Functionality for writing and reading long-form articles.")
  )

  def repo, do: Config.repo()

  def mailer, do: Config.get!(:mailer_module)
end
