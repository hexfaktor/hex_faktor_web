defmodule Refaktor.Job.Elixir.DepsTest do
  use ExUnit.Case

  @moduletag :refaktor

  import Ecto.Query, only: [from: 2]

  alias HexFaktor.Repo
  alias Refaktor.Job.Elixir.Deps.Model.DepsObject
  alias HexFaktor.Notification

  @test_job Refaktor.Job.Elixir.Deps
  @test_repo_url "https://github.com/inch-ci/Hello-World-Elixir.git"

  test "runs a job" do
    project_id = 1
    {:ok, _build, pid} =
      Refaktor.Builder.add_and_run_repo(@test_repo_url, "master",
                        jobs: [@test_job],
                        meta: [
                          project_id: project_id,
                          git_repo_id: 1,
                          git_branch_id: 1,
                          progress_callback: fn(x) -> x end
                        ]
                      )

    receive do
      {:job_done, _job_id, result} ->
        {:ok, {}} = result
        obj_count = Repo.one(from r in DepsObject,
                              select: count(r.id),
                              where: r.toplevel == true)
        assert obj_count == 3 # there should be 3 toplevel deps in Hello-World-Elixir
        obj_count = Repo.one(from r in Notification,
                              select: count(r.id),
                              where: r.project_id == ^project_id)
        assert obj_count == 3
    end
  end

  test "sorts versions" do
    input = ["0.1.10", "0.1.19", "0.1.9"]
    expected = ["0.1.9", "0.1.10", "0.1.19"]
    assert expected == input |> Refaktor.Job.Elixir.Deps.sort_versions()

    input = ["2.3.0", "2.2.1", "1.0.0", "1.0.1", "1.1.0", "1.2.0", "1.2.1", "1.3.0", "1.4.0", "2.0.0-dev", "2.0.0", "2.0.1", "2.1.0", "2.1.1", "2.1.2", "2.2.0"]
    expected = ["1.0.0", "1.0.1", "1.1.0", "1.2.0", "1.2.1", "1.3.0", "1.4.0", "2.0.0-dev", "2.0.0", "2.0.1", "2.1.0", "2.1.1", "2.1.2", "2.2.0", "2.2.1", "2.3.0"]
    assert expected == input |> Refaktor.Job.Elixir.Deps.sort_versions()
  end
end
