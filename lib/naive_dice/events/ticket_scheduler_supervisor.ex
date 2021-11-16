defmodule NaiveDice.TicketScheduler.Supervisor do
  use DynamicSupervisor

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_child(opts) do
    spec = {NaiveDice.TicketScheduler, opts}
    DynamicSupervisor.start_child(__MODULE__, spec)
  end

  def terminate_child_by_id(id) do
    [{pid, _}] = Registry.lookup(NaiveDice.TicketScheduler, id)
    DynamicSupervisor.terminate_child(__MODULE__, pid)
  end
end
