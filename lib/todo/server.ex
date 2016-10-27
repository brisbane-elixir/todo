defmodule Todo.Server do
  use GenServer
  alias Todo.{Database, List}

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

  def start(name) do
    GenServer.start(__MODULE__, name)
  end

  def init(name) do
    {:ok, {name, Database.get(name) || List.new}}
  end

  def handle_cast({:add_entry, new_entry}, {name, todo_list}) do
    todo_list = List.add_entry(todo_list, new_entry)
    Database.store(name, todo_list)
    {:noreply, {name, todo_list}}
  end

  def handle_call({:entries, date}, _, {name, todo_list}) do
    {:reply, List.entries(todo_list, date), {name, todo_list}}
  end

  def handle_call(:clear, _, {name, _}) do
    todo_list = List.new
    Database.store(name, todo_list)
    {:reply, :ok, {name, todo_list}}
  end

  def add_entry(todo_server, new_entry) do
    GenServer.cast(todo_server, {:add_entry, new_entry})
  end

  def entries(todo_server, date) do
    GenServer.call(todo_server, {:entries, date})
  end

  def clear(todo_server) do
    GenServer.call(todo_server, :clear)
  end
end
