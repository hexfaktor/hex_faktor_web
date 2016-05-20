defmodule Refaktor.Test.JobID do
  use GenServer

  @table_name __MODULE__

  def start_link(opts \\ []) do
    {:ok, _pid} = GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def next do
    GenServer.call(__MODULE__, {:next})
  end

  # callbacks

  def init(_) do
    {:ok, 1000}
  end

  def handle_call({:next}, _from, current_state) do
    {:reply, current_state+1, current_state+1}
  end
end

defmodule Refaktor.Test.Application do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      worker(Refaktor.Test.JobID, []),
    ]

    opts = [strategy: :one_for_one, name: Refaktor.Test.Application.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
