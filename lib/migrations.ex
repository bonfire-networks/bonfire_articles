defmodule Bonfire.Articles.Migrations do
  @moduledoc false
  use Ecto.Migration

  def ms(:up) do
    quote do
      require Bonfire.Articles.Article.Migration

      Bonfire.Articles.Article.Migration.migrate_article()
    end
  end

  def ms(:down) do
    quote do
      require Bonfire.Articles.Article.Migration

      Bonfire.Articles.Article.Migration.migrate_article()
    end
  end

  defmacro migrate_articles() do
    quote do
      if Ecto.Migration.direction() == :up,
        do: unquote(ms(:up)),
        else: unquote(ms(:down))
    end
  end

  defmacro migrate_articles(dir), do: ms(dir)
end
