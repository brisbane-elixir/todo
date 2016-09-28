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
end
