# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

config :hex_faktor, tool_dir: Path.join([System.cwd!, "dockertools"])

config :hex_faktor, code_dirname: "code"
config :hex_faktor, eval_dirname: "eval"

config :hex_faktor, git_hub_auth_module: GitHubAuth
config :hex_faktor, git_hub_api_module: GitHubAPI

# Configures the endpoint
config :hex_faktor, HexFaktor.Endpoint,
  url: [host: "localhost"],
  root: Path.dirname(__DIR__),
  secret_key_base: "k9cPX7yvi0NGHhGiAqcjGeg6hkZaxuzhU/bMFsVspW/GiPI8kkz5tfdZJOzGpILw",
  render_errors: [accepts: ~w(html json)],
  pubsub: [name: HexFaktor.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"

# Configure phoenix generators
config :phoenix, :generators,
  migration: true,
  binary_id: false

config :hex_faktor, mailgun_domain: "https://api.mailgun.net/v3/mydomain.com",
                    mailgun_key: "key-##############"

config :hex_faktor, :hex_faktor_repo_url, "https://github.com/hexfaktor/hex_faktor_web"
