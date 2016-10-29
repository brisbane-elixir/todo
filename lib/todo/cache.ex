defmodule Todo.Cache do
  use GenServer
  alias Todo.{Server, ServerSupervisor}

  def init(_) do
    {:ok, nil}
  end

  def start_link do
    IO.puts "Starting to-do cache."
    GenServer.start_link(__MODULE__, nil, name: :todo_cache)
  end

  def server_process(todo_list_name) do
    case Server.whereis(todo_list_name) do
      pid when is_pid(pid) -> pid
      :undefined -> GenServer.call(:todo_cache, {:server_process, todo_list_name})
    end
  end

  def handle_call({:server_process, todo_list_name}, _, _) do
    {:ok, pid} = case Server.whereis(todo_list_name) do
      pid when is_pid(pid) -> {:ok, pid}
      :undefined -> ServerSupervisor.start_child(todo_list_name)
    end

    {:reply, pid, nil}
  end
end
