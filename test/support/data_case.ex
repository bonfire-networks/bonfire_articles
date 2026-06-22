defmodule Bonfire.Articles.DataCase do
  @moduledoc "Test setup for tests requiring access to the application's data layer."

  use ExUnit.CaseTemplate

  using do
    quote do
      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      use Bonfire.Common.Utils
      import Bonfire.UI.Common.Testing.Helpers
      import Bonfire.Social
      import Bonfire.Social.Fake
      import Bonfire.Posts.Fake
      import Bonfire.Articles.Fake

      @moduletag :backend
    end
  end

  setup tags do
    Bonfire.Common.Test.Interactive.setup_test_repo(tags)

    :ok
  end

  def errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Regex.replace(~r"%{(\w+)}", message, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
