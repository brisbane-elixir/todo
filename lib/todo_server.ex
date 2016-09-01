defmodule TodoServer do
  use GenServer

  def start(name) do
    GenServer.start(__MODULE__, name)
  end

  def init(name) do
    {:ok, {name, TodoDatabase.get(name) || TodoList.new}}
  end

  def handle_cast({:add_entry, new_entry}, {name, todo_list}) do
    todo_list = TodoList.add_entry(todo_list, new_entry)
    TodoDatabase.store(name, todo_list)
    {:noreply, {name, todo_list}}
  end

  def handle_call({:entries, date}, _, {name, todo_list}) do
    {:reply, TodoList.entries(todo_list, date), todo_list}
  end

  def handle_call(:clear, _, {name, todo_list}) do
    todo_list = TodoList.new
    TodoDatabase.store(name, todo_list)
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
