defmodule Refaktor.Persistence.BuildTest do
  use ExUnit.Case

  @moduletag :refaktor

  alias Refaktor.Persistence.Build

  test "adds builds" do
    git_repo_id = 1
    git_branch_id = 1
    result1 = Build.add(git_repo_id, git_branch_id)
    assert result1.id
    result2 = Build.add(git_repo_id, git_branch_id)
    assert result2.id
    assert 1 == result1.nr
    assert 2 == result2.nr
  end

  test "adds build jobs" do
    build_id = 101
    result1 = Build.add_job(build_id, "elixir", "inch")
    result2 = Build.add_job(build_id, "elixir", "code_analysis")
    assert 1 == result1.nr
    assert 2 == result2.nr

    build_id = 102
    result3 = Build.add_job(build_id, "elixir", "inch")
    assert 1 == result3.nr
  end
end
