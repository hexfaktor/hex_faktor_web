defmodule Refaktor.Worker.Supervisor do
  use Supervisor

  @pool_name :refaktor_pool
  @pool_size Application.get_env(:hex_faktor, :worker_pool_size)
  @pool_overflow Application.get_env(:hex_faktor, :worker_pool_overflow)
  @pool_timeout :infinity

  def start_link do
    Supervisor.start_link(__MODULE__, [])
  end

  def init([]) do
    poolboy_config = [
      {:name, {:local, @pool_name}},
      {:worker_module, Refaktor.Worker.JobRunner},
      {:size, @pool_size},
      {:max_overflow, @pool_overflow}
    ]
    children = [:poolboy.child_spec(@pool_name, poolboy_config, [])]
    options = [strategy: :one_for_one]

    supervise(children, options)
  end

  def enqueue_clone(build, git_repo, branch_name, jobs_to_schedule, meta) do
    parent = self()
    spawn(fn() ->
      {_, first_job_id} = Enum.at(jobs_to_schedule, 0)
      run_clone(build, git_repo, branch_name, jobs_to_schedule, meta, parent)
    end)
  end

  def run_clone(build, git_repo, branch_name, jobs_to_schedule, meta, parent) do
    :poolboy.transaction(
      @pool_name,
      fn(pid) ->
        {_, first_job_id} = Enum.at(jobs_to_schedule, 0)
        :gen_server.call(pid, {:run_clone, build, git_repo, branch_name, jobs_to_schedule, meta, parent})
      end,
      @pool_timeout
    )
  end
end
