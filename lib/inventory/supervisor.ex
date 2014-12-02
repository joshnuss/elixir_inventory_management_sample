defmodule Inventory.Supervisor do
  use Supervisor

  @service_name Inventory
  @event_manager Inventory.Events

  def start_link(module) do
    Supervisor.start_link(__MODULE__, module)
  end

  def init(module) do
    {:ok, events} = GenEvent.start_link(name: @event_manager)

    children = [
      worker(module, [[name: @service_name, events: events]])
    ]

    supervise(children, strategy: :one_for_one)
  end
end
