# Elixir in Action Part 2

This month we'll continue our Todo application we started in [part 1](./elixir_in_action_part_1.md)

## Managing multiple Todo lists

Let's recap what we built last time. We have:
 - a pure functional abstraction of a Todo list
 - a Todo server process that maintains the state of one Todo list
 
 In order to extend this code to work with multiple lists, we'll run one instance of our Todo server for each list. To do this,
 we'll introduce a new entity that we'll use to create new Todo lists and lookup existing ones. We'll call this our Todo Cache.
 
 Let's start with a test:
 in `test/todo_cache_test.exs`
```
defmodule TodoCacheTest do
  use ExUnit.Case

  test "can retrieve a server process from the cache" do
    {:ok, cache} = TodoCache.start
    pid = TodoCache.server_process(cache, "Bob's List")
    retrieved = TodoCache.server_process(cache, "Bob's List")

    assert pid == retrieved
  end
end
``` 
We expect that if we ask for a server process twice, we get the same pid back.

Now, the implementation. So far, nothing too new from what we have done before, basically our cache creates a new TodoServer for a given
name, or it returns the existing one. It's state is a simple `Map`.

```
defmodule TodoCache do
  use GenServer

  def init(_) do
    {:ok, Map.new}
  end

  def start do
    GenServer.start(__MODULE__, nil)
  end

  def server_process(cache_pid, todo_list_name) do
    GenServer.call(cache_pid, {:server_process, todo_list_name})
  end

  def handle_call({:server_process, todo_list_name}, _, todo_servers) do
    case Map.fetch(todo_servers, todo_list_name) do
      {:ok, todo_server} ->
        {:reply, todo_server, todo_servers}
      :error ->
        {:ok, new_server} = TodoServer.start
        {
          :reply,
          new_server,
          Map.put(todo_servers, todo_list_name, new_server)
        }
    end
  end
end
```
