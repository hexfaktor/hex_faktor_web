use Mix.Config

# For development, we disable any cache and enable
# debugging and code reloading.
#
# The watchers configuration can be used to run external
# watchers to your application. For example, we use it
# with brunch.io to recompile .js and .css sources.
config :hex_faktor, HexFaktor.Endpoint,
  http: [port: 4000],
  debug_errors: true,
  code_reloader: true,
  cache_static_lookup: false,
  check_origin: false,
  watchers: [node: ["node_modules/brunch/bin/brunch", "watch", "--stdin"]]

# Watch static and templates for browser reloading.
config :hex_faktor, HexFaktor.Endpoint,
  live_reload: [
    patterns: [
      ~r{priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$},
      ~r{priv/gettext/.*(po)$},
      ~r{web/views/.*(ex)$},
      ~r{web/templates/.*(eex)$}
    ]
  ]

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Set a higher stacktrace during development.
# Do not configure such in production as keeping
# and calculating stacktraces is usually expensive.
config :phoenix, :stacktrace_depth, 20

# Configure your database
config :hex_faktor, HexFaktor.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "hex_faktor_dev",
  hostname: "localhost",
  pool_size: 10

config :hex_faktor, userid_inside_docker: 1000
config :hex_faktor, work_dir: Path.join([System.cwd!, "..", "hex_faktor-workdir"])

config :hex_faktor, :base_url, "http://localhost:4000"

config :hex_faktor, :salt_user_socket, "salt goes here"
config :hex_faktor, :salt_email_token, "salt goes here"

config :hex_faktor, :worker_pool_size, 100
config :hex_faktor, :worker_pool_overflow, 100

config :hex_faktor, :mailgun,
  domain: "https://api.mailgun.net/v3/YOURDOMAIN",
  key: "something",
  mode: :test,
  test_file_path: "/tmp/mailgun.json"

config :rollbax,
  access_token: "",
  environment: "",
  enabled: :log

import_config "dev.secret.exs"
