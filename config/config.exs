import Config

config :bonfire_common,
  otp_app: :bonfire_articles

config :bonfire_articles,
  otp_app: :bonfire_articles

# include all used Bonfire extensions
import_config "bonfire_articles.exs"

#### Basic configuration

config :bonfire, :repo_module, Bonfire.Common.Repo

config :phoenix, :json_library, Jason

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :mime, :types, %{
  "application/activity+json" => ["activity+json"]
}
