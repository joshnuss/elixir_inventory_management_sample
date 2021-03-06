Example Inventory Management Subsystem with Elixir
=========

It is advantageos for LOB (line-of-business) apps to be modularized into separate subsystems. Each subsystem is responsible for just one logical function, easing complexity. For example, an e-commerce system would be made up of several subsystems: inventory management, credit card processing, order fulfilment, product catalog, cart management, membership and several others. The application then becomes just a collection of out of the box services with some modified ones.

For maximum re-usablity, each subsystem should offer several options (Provider pattern). For example an inventory service may offer these providers out of the box:

- **Untracked**: dont care about inventory, always respond that item is available
- **DB**: store inventory history in local db, use db to determine availbility
- **SAP**: store inventory in SAP
- **Shopify**: store inventory in Shopify
- ...

Each of these processes understands some simple messages: `:increase`, `:decrease`, `:lookup` and `:history`

The big win is that you can roll your own when needed. Maybe you have multiple warehouses with special rules based on the product type, or maybe you track inventory only for certain products and not others. Most scenarios could be accomplished by adding a new provider. You could even create a hybrid provider and use pattern matching, i.e. t-shirt -> untracked, watches -> use db. Here's an example of a custom hybrid provider:

```elixir
# Hybrid provider example
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

  # match anything that isnt a watch
  def handle_call(msg, _from, state) do
    response = GenServer.call(state.tracked, msg)
    {:reply, response, state}
  end

  # ...
end
```
Each service also fire events. In this inventory example the services fire events `{:increased, id, reason, count}` and `{:decreased, id, reason, count}` whenever stock changes. Any process could handle these events by registering an event handler with the Inventory.Events process. The handler could then do something useful (for example notifying people when an item on their wishlist is back in stock)

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

When calling the inventory sub-system, its important that the caller dont know what underlying provider is running. Instead the `Inventory` module contains wrapper functions which can be called like this:

``` elixir

Inventory.Supervisor.start_link(Inventory.Local)

Inventory.lookup("t-shirt") # dont care what underlying provider is used
```

The wrapper functions also provide convenience functions, for example `Inventory.adjust` is written using `Inventory.increase` and `Inventory.decrease`:

```elixir
def adjust(id, reason, count) when count > 0 do
  increase(id, reason, count)
end

def adjust(id, reason, count) when count < 0 do
  decrease(id, reason, -count)
end
```

## Example

https://github.com/joshnuss/elixir_inventory_management_sample/blob/master/example.exs

```bash
mix run example.exs
```
