defmodule Inventory do
  def in_stock?(id) do
    case lookup(id) do
      {:in_stock, _} -> true
      _              -> false
    end
  end

  def backordered?(id) do
    case lookup(id) do
      {:backordered, _} -> true
      _                 -> false
    end
  end

  def lookup(id) do
    GenServer.call(Inventory, {:lookup, id})
  end

  def history(id) do
    GenServer.call(Inventory, {:history, id})
  end

  def increase(id, reason, count) do
    GenServer.call(Inventory, {:increase, id, reason, count})
  end

  def decrease(id, reason, count) do
    GenServer.call(Inventory, {:decrease, id, reason, count})
  end

  def adjust(id, reason, count) when count > 0 do
    increase(id, reason, count)
  end

  def adjust(id, reason, count) when count < 0 do
    decrease(id, reason, -count)
  end
end
