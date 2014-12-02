Inventory.Supervisor.start_link(Inventory.Untracked)

spawn fn ->
  for x <- GenEvent.stream(Inventory.Events), do: IO.puts("Notification: #{inspect x}")
end

IO.inspect Inventory.lookup("1234")
IO.inspect Inventory.increase("1234", "Receivable", 5)
IO.inspect Inventory.increase("1234", "Receivable", 4)
IO.inspect Inventory.decrease("1234", "Missing", 3)
IO.inspect Inventory.lookup("1234")
IO.inspect Inventory.history("1234")
IO.inspect Inventory.in_stock?("1234")
IO.inspect Inventory.adjust("1234", "Stolen", -6) # same as decrease
IO.inspect Inventory.in_stock?("1234")
