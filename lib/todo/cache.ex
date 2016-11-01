defmodule Todo.Cache do
  use GenServer
  alias Todo.{Server, ServerSupervisor}

  def init(_) do
    :ets.new(:ets_todo_cache, [:set, :named_table, :protected])
    {:ok, nil}
  end

  def start_link do
    IO.puts "Starting to-do cache."
    GenServer.start_link(__MODULE__, nil, name: :todo_cache)
  end

  def server_process(todo_list_name) do
    case :ets.lookup(:ets_todo_cache, todo_list_name) do
      [{^todo_list_name, pid}] -> pid
      _ -> GenServer.call(:todo_cache, {:server_process, todo_list_name})
    end
  end

  def handle_call({:server_process, todo_list_name}, _, _) do
    pid = case :ets.lookup(:ets_todo_cache, todo_list_name) do
      [{^todo_list_name, pid}] -> pid
      _ ->
        {:ok, pid} = ServerSupervisor.start_child(todo_list_name)
        :ets.insert(:ets_todo_cache, {todo_list_name, pid})
        pid
    end

    {:reply, pid, nil}
  end
end
