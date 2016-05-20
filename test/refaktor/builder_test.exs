defmodule Refaktor.BuilderTest do
  @moduledoc """
  NOTE: The tested jobs are defined in support/test_jobs.exs
  """

  use ExUnit.Case

  @moduletag :refaktor

  # TODO: clone the repo, then use the local path as test URL
  #       to avoid unnecessary network traffic
  @test_repo_url "https://github.com/inch-ci/Hello-World-Elixir.git"

  test "runs a job" do
    jobs = [TestOutputJob]
    {:ok, _build, pid} = Refaktor.Builder.add_and_run_repo(@test_repo_url, "master", jobs: jobs)

    receive do
      {:job_done, _job_id, result} ->
        assert {:ok, {}} == result
    end
  end

  test "errors a job for command exits with non-zero exit code" do
    jobs = [TestErrorJob]
    {:ok, _build, pid} = Refaktor.Builder.add_and_run_repo(@test_repo_url, "master", jobs: jobs)

    receive do
      {:job_done, job_id, result} ->
        build_job = get_build_job(job_id)
        assert "failure" == build_job.status
        assert {:error, {42, ""}} == result
    end
  end



  defp get_build_job(job_id) do
    Refaktor.Builder.Model.BuildJob
    |> HexFaktor.Repo.get!(job_id)
  end
end
