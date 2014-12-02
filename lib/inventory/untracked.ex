defmodule Inventory.Untracked do
  use GenServer

  def start_link(opts) do
    events = Keyword.get(opts, :events)
    GenServer.start_link(__MODULE__, %{events: events}, opts)
  end

  def handle_call({:lookup, _id}, _from, state) do
    {:reply, {:available, 0}, state}
  end

  def handle_call({:history, _id}, _from, state) do
    {:reply, [], state}
  end

  def handle_call({:increase, _id, _reason, count}, _from, state) do
    GenEvent.notify(state.events, {:increased, count})
    {:reply, {:increased, count}, state}
  end

  def handle_call({:decrease, _id, _reason, count}, _from, state) do
    GenEvent.notify(state.events, {:decreased, count})
    {:reply, {:decreased, -count}, state}
  end
end
