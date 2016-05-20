require Ecto.Query
import Ecto.Query

filename = Path.join(__DIR__, "projects.csv")
content = File.read!(filename)

query = from r in HexFaktor.Project,
          select: count(r.id),
          limit: 1
base_count = HexFaktor.Repo.one(query)

String.split(content, "\n")
#|> Enum.take(100)
|> Enum.each(fn(line) ->
    case line |> String.split(",") do
      [
        _package_name,
        github_url,
        name,
        uid,
        language,
        default_branch,
        fork
      ] ->
        %HexFaktor.Project{}
        |> HexFaktor.Project.changeset(%{
            "uid" => uid,
            "provider" => "github",
            "name" => name,
            "clone_url" => "#{github_url}.git",
            "html_url" => github_url,
            "language" => language,
            "active" => false,
            "default_branch" => default_branch,
            "fork" => fork == "true"
          })
        |> HexFaktor.Repo.insert
        |> case do
            {:ok, result} -> nil
            val -> IO.inspect val
          end
      _ ->
        nil
    end
  end)
