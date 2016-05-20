Code.require_file("support/test_application.exs", __DIR__)
Code.require_file("support/test_jobs.exs", __DIR__)

Refaktor.Test.Application.start([], [])

ExUnit.start()

# Exclude all external tests from running
ExUnit.configure(exclude: [refaktor: true])

# Create the database, run migrations, and start the test transaction.
Mix.Task.run "ecto.drop", ["--quiet"]
Mix.Task.run "ecto.create", ["--quiet"]
Mix.Task.run "ecto.migrate", ["--quiet"]

HexFaktor.Fixtures.insert_basic

Ecto.Adapters.SQL.begin_test_transaction(HexFaktor.Repo)

# Remove the temp dir (we use to store avatars etc. during tests) so we can
# check if certain files are created during testing
File.rm_rf Refaktor.Builder.work_dir
