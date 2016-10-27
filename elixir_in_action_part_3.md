# Elixir in Action - Part 3
Over the last couple of months, we've been building up our Todo application. If you missed those sessions, don't worry! There are interesting things to pick at each stage of the journey.

Let's recap what we did last time.
 - We introduced a `Todo.Cache` to look up existing ToDo servers, so we can work with multiple Todo lists.
 - We added simple persistence - just writing the list to a file on disk. We split this into multiple workers, so separate files could be written to concurrently.
 - We changed our Database module to be a supervisor for our pool of database workers. To do this we needed to use some non-standard process registration, so we implemented our own `Todo.ProcessRegistry`. (Note: there are good libraries available, you don't really need to implement your own.) 
 - We updated our database workers to register themselves, and deregister when they die - so the registry always has an up to date view of the workers.
 
 Wow. That was a lot :). These changes, though, made our system a lot more fault-tolerant. If some part crashes, it is restarted, and we take steps to ensure a clean state - no dangling processes, no stale pid references, etc.
 
 Next, we're going to do a similar thing to our Todo Cache - make sure any processes started by it are properly supervised. There is an important different though - in our database example, we could know all our workers at the time we started the supervisor. For Todo Lists, we start a Todo Server the first time it is requested, after the system is up and running. This requires a special type of supervisor. Introducing:
 
 ## Dynamic Supervisors
 A dynamic supervisor is one that can start a child on demand, in OTP, they have a slightly misleading name: `simple_one_for_one` supervisors. This is a special case of the `one_for_one` strategy with these properties:
  - All children are started by the same function.
  - No child is started up front. You start a child by calling `Supervisor.start_child/2`.
  
Note: It is also possible to start dynamic children with other strategies, but if all children are of the same type, it is more idiomatic to use `simple_one_for_one`.

Here is our supervisor:

`lib/todo/server_supervisor.ex`
```elixir
defmodule Todo.ServerSupervisor do
  use Supervisor
  def start_link do
    Supervisor.start_link(__MODULE__, nil,
      name: :todo_server_supervisor
    )
  end
  def start_child(todo_list_name) do
    Supervisor.start_child(
      :todo_server_supervisor,
      [todo_list_name]
    )
  end
  def init(_) do
    supervise(
      [worker(Todo.Server, [])],
      strategy: :simple_one_for_one
    )
  end
end
```

A couple of differences to our previous one.
 - We make the supervisor register locally under an alias, so we an easily use it to start children
 - In init, we still provide a child specification, and a list predefined args. When we start a child we can specify additional args that are appended to this list.
 
With this in place, we need to make our Todo Server register itself on start with our Process Registry. 

```elixir
defmodule Todo.Server do
  use GenServer

  def start_link(name) do
    IO.puts "Starting to-do server for #{name}"
    GenServer.start_link(__MODULE__, name, name: via_tuple(name))
  end

  defp via_tuple(name) do
  {:via, Todo.ProcessRegistry, {:todo_server, name}}
  end

  def whereis(name) do
    Todo.ProcessRegistry.whereis_name({:todo_server, name})
  end
...
end
```

Now that our server processes add themselves to the process registry, we don't actually need to store them in the cache. Let's update our cache to:
 # In the client process check whether a server process exists, and return it if so.
 # Other wise, call in to the Todo Cache process.
 # In the cache process, recheck if the process exists, and return it if so.
