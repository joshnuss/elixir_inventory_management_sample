defmodule Inventory.Local do
  use GenServer

  def start_link(opts) do
    events = Keyword.get(opts, :events)
    {:ok, agent} = Agent.start_link fn -> HashDict.new end

    GenServer.start_link(__MODULE__, %{agent: agent, events: events}, opts)
  end

  def handle_call({:lookup, id}, _from, state) do
    history = Agent.get state.agent, &HashDict.get(&1, id, [])
    count = Enum.reduce(history, 0, fn {_reason, count}, acc -> acc + count end)

    status = if count > 0, do: :in_stock, else: :sold_out

    {:reply, {status, count}, state}
  end

  def handle_call({:history, id}, _from, state) do
    history = Agent.get state.agent, &HashDict.get(&1, id, [])
    {:reply, history, state}
  end

  def handle_call({:increase, id, reason, count}, _from, state) do
    Agent.update state.agent, fn dict ->
      history = HashDict.get(dict, id, [])
      HashDict.put(dict, id, [{reason, count} | history])
    end
    
    GenEvent.notify(state.events, {:increased, id, reason, count})

    {:reply, {:increased, count}, state}
  end

  def handle_call({:decrease, id, reason, count}, _from, state) do
    Agent.update state.agent, fn dict ->
      history = HashDict.get(dict, id, [])
      HashDict.put(dict, id, [{reason, -count} | history])
    end

    GenEvent.notify(state.events, {:decreased, id, reason, count})

    {:reply, {:decreased, -count}, state}
  end
end
