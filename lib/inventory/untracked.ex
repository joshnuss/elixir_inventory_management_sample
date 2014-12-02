# An inventory server which always responds to
# lookups with {:available, 0} and ignores all other messages
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

  def handle_call({:increase, id, reason, count}, _from, state) do
    GenEvent.notify(state.events, {:increased, id, reason, count})
    {:reply, {:increased, count}, state}
  end

  def handle_call({:decrease, id, reason, count}, _from, state) do
    GenEvent.notify(state.events, {:decreased, id, reason, count})
    {:reply, {:decreased, -count}, state}
  end
end
