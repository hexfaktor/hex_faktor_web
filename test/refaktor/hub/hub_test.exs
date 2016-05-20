defmodule Refaktor.Builder2Test do
  use ExUnit.Case

  @moduletag :refaktor

  @test_repo_url "https://github.com/inch-ci/Hello-World-Elixir.git"
  @fail_repo_url "https://github.com/inch-ci/Hello-World-123.git"

  test "clones the git repo" do
    job_id = Refaktor.Test.JobID.next
    result = Refaktor.Builder.clone_for_job(@test_repo_url, "master", job_id)
    {:ok, ^job_id, job_dir, _repo_info} = result
    assert String.length(job_dir) > 0
  end

  test "clones the git repo with the right branch" do
    job_id = Refaktor.Test.JobID.next
    result = Refaktor.Builder.clone_for_job(@test_repo_url, "develop", job_id)
    {:ok, ^job_id, job_dir, _repo_info} = result
    assert String.length(job_dir) > 0
  end

  test "fails the git repo clone" do
    job_id = Refaktor.Test.JobID.next
    result = Refaktor.Builder.clone_for_job(@fail_repo_url, "master", job_id)
    {ok, ^job_id, _job_dir, _output, _exit_code} = result
    assert :error == ok
  end

  test "fails the git repo clone with the right branch" do
    job_id = Refaktor.Test.JobID.next
    result = Refaktor.Builder.clone_for_job(@test_repo_url, "develop123", job_id)
    {ok, ^job_id, _job_dir, _output, _exit_code} = result
    assert :error == ok
  end
end
