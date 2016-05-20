defmodule Refaktor.Persistence.Job do
  alias HexFaktor.Repo
  alias Refaktor.Builder.Model.BuildJob

  def by_id(id) do
    Repo.get(BuildJob, id)
  end

  def update_info(job_id, {:ok, _result}) do
    by_id(job_id)
  end
  def update_info(job_id, {:error, _error}) do
    by_id(job_id)
  end
  def update_info(job_id, {:timeout, _result}) do
    by_id(job_id)
  end
  def update_info(job_id, _val) do
    by_id(job_id)
  end
end
