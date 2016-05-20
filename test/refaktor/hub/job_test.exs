defmodule Refaktor.JobTest do
  @moduledoc """
  NOTE: The tested jobs are defined in support/test_jobs.exs
  """

  use ExUnit.Case

  @moduletag :refaktor

  # TODO: clone the repo, then use the local path as test URL
  #       to avoid unnecessary network traffic
  @test_repo_url "https://github.com/inch-ci/Hello-World-Elixir.git"

  test "runs a job" do
    job_id = Refaktor.Test.JobID.next
    result =
      Refaktor.Builder.clone_for_job(@test_repo_url, "master", job_id)
      |> Refaktor.Job.run(TestOutputJob)

    assert {:ok, {}} == result
  end

  test "errors a job for command exits with non-zero exit code" do
    job_id = Refaktor.Test.JobID.next
    result =
      Refaktor.Builder.clone_for_job(@test_repo_url, "master", job_id)
      |> Refaktor.Job.run(TestErrorJob)

    # see the `test-error` command (search project for `exit 42`)
    assert {:error, {42, ""}} == result
  end

  test "errors a job for command not found" do
    job_id = Refaktor.Test.JobID.next
    result =
      Refaktor.Builder.clone_for_job(@test_repo_url, "master", job_id)
      |> Refaktor.Job.run(TestCommandNotFoundJob)

    {:error, {1, error_message}} = result
    expected = "exec: \"test-error-this-command-does-not-exist\": executable file not found in $PATH"
    assert String.contains?(error_message, expected), ["Expected error message:", expected, "got:", error_message] |> Enum.join("\n\n")
  end

  test "errors a job for an unparsable json result" do
    job_id = Refaktor.Test.JobID.next
    result =
      Refaktor.Builder.clone_for_job(@test_repo_url, "master", job_id)
      |> Refaktor.Job.run(TestCommandProducesBadJSONJob)

    {:error, :json_parser, _} = result
  end

  test "wraps success if necessary" do
    assert {:ok, {"something"}} == {"something"} |> Refaktor.Job.wrap_success
    assert {:ok, {"something"}} == {:ok, {"something"}} |> Refaktor.Job.wrap_success
    assert {:error, "test"} == {:error, "test"} |> Refaktor.Job.wrap_success
  end

end
