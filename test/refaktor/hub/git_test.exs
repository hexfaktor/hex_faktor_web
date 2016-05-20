defmodule HexFaktor.RepoTest do
  use ExUnit.Case

  @moduletag :refaktor

  @test_repo_url "https://github.com/inch-ci/Hello-World-Elixir.git"
  @fail_repo_url "https://github.com/inch-ci/Hello-World-123.git"
  @tmp_dir Refaktor.Builder.work_dir

  test "clones the git repo" do
    dir = Path.join(@tmp_dir, "test-repo")
    File.rm_rf!(dir)
    result = Refaktor.Builder.Git.clone(@test_repo_url, dir)
    {ok, repo} = result
    assert :ok == ok
    assert "master" == repo.branch
    assert String.length(repo.revision[:sha1]) > 0
  end

  test "clones the git repo with the right branch" do
    dir = Path.join(@tmp_dir, "test-repo-branched")
    File.rm_rf!(dir)
    result = Refaktor.Builder.Git.clone(@test_repo_url, dir, branch: "develop")
    {ok, repo} = result
    assert :ok == ok
    assert "develop" == repo.branch
    assert String.length(repo.revision[:sha1]) > 0
  end

  test "fails the git repo clone" do
    dir = Path.join(@tmp_dir, "test-repo")
    File.rm_rf!(dir)
    result = Refaktor.Builder.Git.clone(@fail_repo_url, dir)
    {ok, _, _} = result
    assert :error == ok
  end

  test "fails the git repo clone with the right branch" do
    dir = Path.join(@tmp_dir, "test-repo-branched")
    File.rm_rf!(dir)
    result = Refaktor.Builder.Git.clone(@test_repo_url, dir, branch: "develop123")
    {ok, _, _} = result
    assert :error == ok
  end
end
