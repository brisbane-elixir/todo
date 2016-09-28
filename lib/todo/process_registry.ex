defmodule Todo.ProcessRegistry do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, nil, [name: :todo_process_registry])
  end

  def init(_) do
    {:ok, %{}}
  end

  def register_name(key, pid) do
    GenServer.call(:todo_process_registry, {:register_name, key, pid})
  end

  def whereis_name(key) do
    GenServer.call(:todo_process_registry, {:whereis_name, key})
  end

  def handle_call({:register_name, key, pid}, _, process_registry) do
    case Map.get(process_registry, key) do
      nil ->
        Process.monitor(pid)
        {:reply, :yes, Map.put(process_registry, key, pid)}
      _ ->
        {:reply, :no, process_registry}
    end
  end

  def handle_call({:whereis_name, key}, _, process_registry) do
    {
      :reply,
      Map.get(process_registry, key, :undefined),
      process_registry
    }
  end
end
