HexFaktor.Persistence.Project.all_active
|> Enum.filter(&(&1.language == "Elixir"))
#|> Enum.take(5)
|> Enum.each(fn(project) ->
    System.cmd("curl", ["-X", "POST", "http://localhost:4000/api/rebuild_via_hook?id=#{project.id}"])
  end)
