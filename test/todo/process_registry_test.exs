defmodule Todo.ProcessRegistryTest do
  use ExUnit.Case
  alias Todo.ProcessRegistry

  setup do
    ProcessRegistry.start_link
    :ok
  end

  test "can register a process" do
    ProcessRegistry.register_name({:database_worker, 1}, self)
    pid = Todo.ProcessRegistry.whereis_name({:database_worker, 1})

    assert pid == self()
  end

  test "should remove dead processes" do
    pid = spawn(fn -> :timer.sleep(:infinity) end)
    ProcessRegistry.register_name({:dead_man_walking}, pid)
    assert ProcessRegistry.whereis_name({:dead_man_walking}) == pid

    Process.exit(pid, :kill)
    :timer.sleep(100)

    assert ProcessRegistry.whereis_name({:dead_man_walking}) == :undefined
  end

  test "can use with via tuples" do
    via_tuple = {:via, Todo.ProcessRegistry, {:database_worker, 1}}
    GenServer.start_link(Todo.DatabaseWorker, "database/viatest", name: via_tuple)
    GenServer.cast(via_tuple, {:store, "somekey", :some_data})
    :timer.sleep(100)
    value = GenServer.call(via_tuple, {:get, "somekey"})

    assert value == :some_data
  end
end
