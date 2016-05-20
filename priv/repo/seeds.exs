# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     HexFaktor.Repo.insert!(%HexFaktor.SomeModel{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

Code.require_file("seeds/packages.exs", __DIR__)
Code.require_file("seeds/projects.exs", __DIR__)
