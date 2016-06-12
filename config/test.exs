use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :hex_faktor, HexFaktor.Endpoint,
  http: [port: 4001],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

config :hex_faktor, userid_inside_docker: 1000
config :hex_faktor, work_dir: Path.join([System.cwd!, "..", "hex_faktor-workdir"])

config :hex_faktor, git_hub_auth_module: GitHubAuthMock
config :hex_faktor, git_hub_api_module: GitHubAPIMock

# Configure your database
config :hex_faktor, HexFaktor.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "hex_faktor_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

config :hex_faktor, :hex_server, "http://test.hex.local"

config :hex_faktor, :base_url, "http://test.host"

config :hex_faktor, :salt_user_socket, "salt goes here"
config :hex_faktor, :salt_email_token, "salt goes here"

config :hex_faktor, :worker_pool_size, 2
config :hex_faktor, :worker_pool_overflow, 1

config :hex_faktor, :mailgun,
  domain: "https://api.mailgun.net/v3/YOURDOMAIN",
  key: "something",
  mode: :test,
  test_file_path: "/tmp/mailgun.json"
