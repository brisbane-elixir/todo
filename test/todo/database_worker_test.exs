defmodule Todo.DatabaseWorkerTest do
  use ExUnit.Case
  alias Todo.DatabaseWorker

  test "can store and retrieve values" do
    Todo.ProcessRegistry.start_link
    DatabaseWorker.start_link("database/test", 1)
    DatabaseWorker.store(1, "my key", %{this_is: "anything"})

    assert DatabaseWorker.get(1, "my key") == %{this_is: "anything"}
  end
end
