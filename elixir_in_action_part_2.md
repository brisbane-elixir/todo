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

In `test/todo_server_test.exs`:

```elixir
  test "should persist entries", %{todo_server: todo_server} do
    TodoServer.add_entry(todo_server,
      %{date: {2016, 9, 22}, title: "Elixir Meetup"})

    :timer.sleep(500)
    Process.exit(todo_server, :kill)

    {:ok, todo_server2} = TodoServer.start("myserver")

    assert todo_server != todo_server2
    assert TodoServer.entries(todo_server2, {2016,9,22}) ==
      [%{id: 1, date: {2016, 9, 22}, title: "Elixir Meetup"}]
  end
```
You'll notice I now expect some context passed in to my test, I added a `setup` to remove some duplication with the
existing test:
```elixir
  setup do
    TodoDatabase.start("./database/test")
    {:ok, todo_server} = TodoServer.start("myserver")
    :ok = TodoServer.clear(todo_server)

    %{todo_server: todo_server}
  end
```
First, our server expects the database process to be started. We'll look at better ways to do this when we look at supervision,
but for now, it'll suffice to start it directly whereever convenient.

Second, we've added a parameter to `TodoServer.start`, so that it has a name it can use to persist the data under. Update the existing test use the context from the setup too.

You'll notice a `:timer.sleep` call in there. Why is it there? Because our `add_entry` call is asynchronous, if we put that
message in the mailbox of the TodoServer, and immediately kill it, it may never be processed. For the purposes of this test, we want
to ensure the entry is written to disk, to that when we start another server with the same name, we can check it has read it.

Further to this, in order to have reproducable tests, we needed a way to clear our database. Otherwise, a second test run would append to our existing entry list, and it would contain more entries than we expect.

To implement the clear functionality, this is what I added to TodoServer:
In `lib/todo_server.ex`:
```elixir
  def handle_call(:clear, _, {name, todo_list}) do
    todo_list = TodoList.new
    TodoDatabase.store(name, todo_list)
    {:reply, :ok, {name, todo_list}}
  end

  def clear(todo_server) do
    GenServer.call(todo_server, :clear)
  end
```

I also add a `TodoServer.clear` call in the `TodoCacheTest`, which otherwise will keep appending to a list every run.

If we run our tests now, we'll find there are a few things we need to fix. Here are some things to change in `TodoServer`:

Use the new parameter to persist the data on an `add_entry` call.

```elixir
  def handle_cast({:add_entry, new_entry}, {name, todo_list}) do
    todo_list = TodoList.add_entry(todo_list, new_entry)
    TodoDatabase.store(name, todo_list)
    {:noreply, {name, todo_list}}
  end
```

Notice, we now pass arount a tuple of `{name, todo_list}` to keep the name around. We'll need to update other functions in this
module to do this too.

The `init` function also reads the database to get existing state from disk. If none exists, it starts a new list:

```elixir
  def init(name) do
    {:ok, {name, TodoDatabase.get(name) || TodoList.new}}
  end
```

You'll also find that the `TodoCache` test is failing, because the `TodoServer` expects the database to already have been started.
For now, we'll add a very hacky solution of starting the database when the cache starts, in it's `init` function:

In `lib/todo_cache.ex`:

```elixir
  def init(_) do
    TodoDatabase.start("./database")
    {:ok, Map.new}
  end
```
There are obvious problems with this approach...but let's roll with it for now. We'll make it better later. All the existing tests should be able to pass from there, and we should see some data persisted to disk.

Alright! We have persistence! Our implementation so far is shaky at best...but we'll learn some ways to tighen this up next.

## Analysing the system

Let's have another think about how our processes are working together in our system. We introduced just one database process, but it 
can have a negative impact on our whole systems performance. Our database process performs term encoding/decoding, not to mention
filesystem access.

![Process dependencies](./elixir_in_action_images/todo-server-processes-2.png)

Let's look at where we call our database process:
 - In `TodoServer.init`, we do `TodoDatabase.get` to load state from disk.
 - In the `handle_cast` for `TodoServer.add_entry`, we do a `TodoDatabase.store`.
 
The `store` call might seem harmless, since it's in an asynchronous cast. A client issues the request and continues on it's merry
way without blocking. However, if requests arrive faster than they can be handled, the message queue for the Database will grow until
eventually we run out of memory and possibly crash the BEAM.

The `get` call is also problematic. It's synchronous, so the `TodoServer` waits for the response. While it's waiting, that `TodoServer`
can't handle new messages. What is worse, however, is that because this is happening inside `init`, our single `TodoCache` process
is blocked while the filesystem is read. Under a heavier load, this could render our system useless.

## Addressing the bottleneck

What can we do? Obviously we need to address the bottleneck caused by our singleton database process.

### Bypass the process
Does this need to be a process, or can it be a plain module? Here are some reasons for a dedicated server process. 
 - Must manage some long lived state
 - Manages a resource that must be reused, e.g. a TCP connection, database connection, file handle, pipe to an OS process.
 - Syncronise a critical section of code - only one process can run some code at a time.
 
 Our database must be synchronised on individual items - we can't simultaneously write to the same file from multiple processes.
 
### Handle requests conccurrently
Another option is to keep the Database process, but it spawn child processes for any actions, so each action is run concurrently.
This would help our Database process remain responsive, and would be valid for certain scenarios. For ours, however, it doesn't prevent
concurrent read/writes to the same file, and concurrently is unbounded. If we have 100,000 concurrent requests, we'll have 100,000 concurrent filesystem operations, which could bring down the performance of the whole system.

### Limiting concurrency with pooling
A common solution to this is to introduce pooling. Our database would start a set number of workers and delegate all requests to a worker.
This allows our Database process to remain responsive, while keeping concurrency under control. It also allows us to send actions for
the same item to the same worker, forcing those to be synchronised, yet allowing concurrent operations.

_note:_ In real life, you would need to constrain the number of simultaneous operations sent to a database, this is purpose of pooling.
There are great existing libraries in elixir/erlang (e.g. poolboy), and you don't need to write this yourself.

## Database Pooling
To introduce database pooling, here are the steps we'll take:
 - Introduce `TodoDatabaseWorker`, similar to existing `TodoDatabase` but not registered under global alias.
 - During `TodoDatabase` initialisation, start N workers, store their pids in a Map.
 - `TodoDatabase.get_worker` returns a pid for a given key. Use `:erlang.phash2(key, n)` to calculate numberical hash
 and normalise to relevant range.
 - `store` and `get` of `TodoDatabase` obtain a workers `pid` and forward to interface functions of `DatabaseWorker`
 
 First, I'll write a test for our database worker. It's similar to our existing database module, but expects a `pid` to be passed
 to it's functions, since we have more than one.

```elixir
defmodule Todo.DatabaseWorkerTest do
  use ExUnit.Case
  alias Todo.DatabaseWorker

  test "can store and retrieve values" do
    {:ok, pid} = DatabaseWorker.start("database/test")
    DatabaseWorker.store(pid, "my key", %{this_is: "anything"})

    assert DatabaseWorker.get(pid, "my key") == %{this_is: "anything"}
  end
end
```

Here is our implemention, again similar to our existing database, but the worker keeps it's `db_folder` as it's state.
We expect each worker to have a unique folder, so each worker has exclusive access to that directory.

```elixir
defmodule Todo.DatabaseWorker do
  use GenServer

  def start(db_folder) do
    GenServer.start(__MODULE__, db_folder)
  end

  def store(pid, key, data) do
    GenServer.cast(pid, {:store, key, data})
  end

  def get(pid, key) do
    GenServer.call(pid, {:get, key})
  end

  def init(db_folder) do
    File.mkdir_p(db_folder)
    {:ok, db_folder}
  end

  def handle_cast({:store, key, data}, db_folder) do
    file_name(db_folder, key)
    |> File.write!(:erlang.term_to_binary(data))
    {:noreply, db_folder}
  end

  def handle_call({:get, key}, _, db_folder) do
    data = case File.read(file_name(db_folder, key)) do
             {:ok, contents} -> :erlang.binary_to_term(contents)
             _ -> nil
           end
    {:reply, data, db_folder}
  end

  defp file_name(db_folder, key), do: "#{db_folder}/#{key}"
end
``` 

Here is our updated `Database` module, which now uses `DatabaseWorker`.

We alias our worker module, set a number of workers. Obviously a future enhancement could make this configurable,
but for now this will do.

Our init function now spawns our database workers, passing in the base directory. The state maintained
by the Database process is now a Map of database worker pids.

We'll add `get_worker` interface function and callback to return a worker pid for a given key. 

Our `get` and `store` functions now just delegate to our worker processes, using `get_worker` to look one up.

```elixir
defmodule Todo.Database do
  use GenServer
  alias Todo.DatabaseWorker

  @num_workers 10

  def start(db_folder) do
    GenServer.start(__MODULE__, db_folder,
      name: :database_server
    )
  end

  def store(key, data) do
    DatabaseWorker.store(get_worker(key), key, data)
  end

  def get(key) do
    DatabaseWorker.get(get_worker(key), key)
  end

  def get_worker(key) do
    GenServer.call(:database_server, {:get_worker, key})
  end

  def init(db_folder) do
    File.mkdir_p(db_folder)
    worker_pids = Enum.reduce(0..@num_workers, %{}, fn index, map ->
      {:ok, pid} = DatabaseWorker.start(db_folder)
      Map.put(map, index, pid)
    end)

    {:ok, worker_pids}
  end

  def handle_call({:get_worker, key}, _, worker_pids) do
    index = :erlang.phash2(key, @num_workers)
    pid = Map.get(worker_pids, index)
    {:reply, pid, worker_pids}
  end

end
```


