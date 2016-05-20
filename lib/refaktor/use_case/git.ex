defmodule Refaktor.UseCase.Git do
  alias Refaktor.Persistence.GitRepo
  alias Refaktor.Persistence.GitBranch

  @doc """
  Returns the GitRepo with the given +url+ (creates it if it doesn't exist).
  """
  def get_repo(url) do
    case GitRepo.by_url(url) do
      nil -> GitRepo.add(url, url |> to_uid)
      val -> val
    end
  end

  def get_repo_and_branch(url, branch_name) do
    repo = get_repo(url)
    {repo, get_branch(repo.id, branch_name)}
  end

  def get_branch(repo_id, branch_name) do
    case GitBranch.by_name(repo_id, branch_name) do
      nil -> GitBranch.add(repo_id, branch_name)
      val -> val
    end
  end

  # this needs work!
  # we want to ensure that we identify two repos retrieved via different
  # mechanisms
  #
  # e.g. these should result in the same uid:
  #
  #   "https://github.com/inch-ci/Hello-World-Elixir.git"
  #   "git@github.com:inch-ci/Hello-World-Elixir.git"
  #
  def to_uid(repo_url) do
    uid =
      repo_url
      |> String.strip
      |> String.replace(~r/^([a-z]+\:\/\/)/, "")
      |> String.replace(~r/\.git$/, "")

    if String.contains?(uid, "git@") do
      uid
      |> String.replace(~r/^git@/, "")
      |> String.replace(~r/\:/, "/")
    else
      uid
    end
  end
end
