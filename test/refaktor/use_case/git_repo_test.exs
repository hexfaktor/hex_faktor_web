defmodule Refaktor.UseCase.GitRepoTest do
  use ExUnit.Case

  alias Refaktor.UseCase.Git

  @moduletag :refaktor

  @test_repo_url "https://github.com/inch-ci/Hello-World-Elixir.git"
  @test_repo_url2 "git@github.com:inch-ci/Hello-World-Elixir.git"
  @test_branch "master"

  test "gets the git repo from the db" do
    result1 = Git.get_repo(@test_repo_url)
    result2 = Git.get_repo(@test_repo_url)
    assert result1 == result2
  end

  test "gets the git repo and branch from the db" do
    {repo, branch} = Git.get_repo_and_branch(@test_repo_url, @test_branch)
    assert @test_repo_url == repo.url
    assert @test_branch == branch.name
  end

  test "generates uid" do
    expected = "github.com/inch-ci/Hello-World-Elixir"
    assert expected == @test_repo_url |> Git.to_uid
    assert expected == @test_repo_url2 |> Git.to_uid
  end
end
