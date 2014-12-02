Example Inventory Management Subsystem with Elixir
=========

It is advantageos for LOB (line-of-business) apps to be modularized into separate subsystems. Each subsystem is responsible for just one logical function (think inventory management, credit card processing, order fulfilment, product catalog, cart management, membership), and the larger system is composed using these smaller piece.

For maximum re-usablity, each subsystem should offer several options (Provider pattern). For example an inventory service may offer multiple providers:

- *Untracked*: dont care about inventory, always respond that its available
- *DB*: store inventory history in local db, use db to determine availbility
- *SAP*: store inventory in SAP
- *Shopify*: store inventory in Shopify
- ...

Each of these processes understands a few simple messages, `:increase`, `:decrease`, `:lookup`, `:history`

The big win is that you can roll your own when needed - maybe you have multiple warehouses with rules about what to do based on the product type, or maybe you only track inventory for certain products and not for others. Any scenario can be accomplished by adding a new provider. You could even create a hybrid provider, i.e. t-shirt -> user untracked, watches -> user db

```elixir
defmodule MyCustomInventoryProvider do
  use GenServer.Behaviour

  def init do
    {:ok, untracked} = Inventory.Untracked.start_link
    {:ok, tracked} = Inventory.Local.start_link

    %{untracked: untracked, tracked: tracked}
  end

  # match messages with id="watch" and send to Local/tracked service
  def handle_call(msg={:increase, "watch", reason, count}, _from, state) do
    response = GenServer.call(state.tracked, msg)
    {:reply, response, state}
  end

  def handle_call(msg, _from, state) do
    response = GenServer.call(state.tracked, msg)
    {:reply, response, state}
  end
end
```

Each service also fire events. In this example the services fire events called `:increased` and `:decreased` when ever stock changes. You could handle these events by registering an event handler with the Inventory.Events process. The handler could then do something useful (for example notifying people when an item on their wishlist is back in stock)

```elixir
defmodule WishListHandler do
   use GenEvent

   # Pattern match `decreased` events when reason="Received"

   def handle_event({:decreased, id, "Received", count}, _state) do
     WishListMailer.deliver(id, count)

     {:ok, []}
   end
end

GenEvent.add_handler(Inventory.Events, WishListHandler, [])
#=> :ok
```
## Example

https://github.com/joshnuss/elixir_inventory_management_sample/blob/master/example.exs

```bash
mix run example.exs
```
