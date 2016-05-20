defmodule Refaktor.Persistence.GitRevision do
  import Ecto.Query, only: [from: 2]

  alias HexFaktor.Repo
  alias Refaktor.Builder.Model.GitRevision

  def ensure(git_repo, git_branch, sha1) do
    case find(git_branch, sha1) do
      nil -> add(git_repo, git_branch, sha1)
      val -> val
    end
  end

  def find(git_branch, sha1) do
    query = from r in GitRevision,
            where: r.git_branch_id == ^git_branch.id and r.sha1 == ^sha1,
            select: r
    Repo.one(query)
  end

  defp add(git_repo, git_branch, sha1) do
    attributes = %{
      "git_repo_id" => git_repo.id,
      "git_branch_id" => git_branch.id,
      "sha1" => sha1,
    }
    %GitRevision{}
    |> GitRevision.changeset(attributes)
    |> Repo.insert!
  end
end
