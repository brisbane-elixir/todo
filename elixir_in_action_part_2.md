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

We'll also ensure we can start multiple todo server processes:
```
  test "can start multiple server processes" do
    {:ok, cache} = TodoCache.start
    pid_1 = TodoCache.server_process(cache, "Bob's List")
    pid_2 = TodoCache.server_process(cache, "Alice's List")

    assert pid_1 != pid_2
  end
```
And that pids we get back are Todo servers we can manipulate:
```
  test "returned pid is a todo list" do
    {:ok, cache} = todocache.start
    bobs_list = todocache.server_process(cache, "bob's list")
    entry = %{date: {2016, 10, 01}, title: "dentist"}
    todoserver.add_entry(bobs_list, entry)

    assert todoserver.entries(bobs_list, {2016, 10, 01}) == [map.put(entry, :id, 1)]
  end
```
And ensure everything still passes.

Just for fun, let's prove that we can create a lot todo list processes without breaking a sweat. In iex, let's do:

```elixir
{:ok, cache} = TodoCache.start
length(:erlang.processes)
1..100_000 |>
  Enum.each(fn(index) ->
    TodoCache.server_process(cache, "to-do list #{index}")
  end)
length(:erlang.processes)
```

## Analysing process dependencies 
Let's take a look at our system so far. Our goal is for this system to be used in a HTTP server - which typically use a process per client request in the erlang/elixir world. If we have many concurrent users, we can expect many processes to be accessing our Todo Cache and Todo Server processes.

![Process dependencies](./elixir_in_action_images/todo-server-processes.png)

In this image, each box represents a process. You can see:
 - multiple client processes access a single Todo Cache
 - multiple client processes use multiple Todo Server processes 
 
This first property could be the source of a bottleneck - we can only handle one `server_process` request simultaneously, no matter
how many CPUs we have. This may not be significant in practice, but is a good consideration to be aware of. Given our Cache performs a simple `Map` lookup or insert, and we need a consistent state of existing todo lists, we'll accept this trade-off for our initial attempt.

## Persisting Data

So far, our data is only in memory. If we shut down our process, or our server dies, we have lost our users Todo lists.
Let's do some persistence. To keep things simple, we're just going to write it locally to disk. Obviously, if we're running multiple
servers in production, writing locally to disk isn't going to cut it, but it serves our purpose for exploring processes right now.

So, we'll introduce a `Database` service, that has `store` and `get` functions. Here is a test:
In `test/database_test.exs`:

```elixir
defmodule DatabaseTest do
  use ExUnit.Case

  test "can store and retrieve values" do
    TodoDatabase.start("database/test")
    TodoDatabase.store("my key", %{this_is: "anything"})

    assert TodoDatabase.get("my key") == %{this_is: "anything"}
  end
end
```

Simple, but enough for now. Perhaps we could do more to ensure it is actually peristed to disk, e.g. kill the process then try
our `get`. We'll do that in the next test, which tests a Todo Server persists its data.

In `tests/todo_server_test.exs`:

```

```



