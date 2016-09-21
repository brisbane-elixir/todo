defmodule Todo.DatabaseWorkerTest do
  use ExUnit.Case
  alias Todo.DatabaseWorker

  test "can store and retrieve values" do
    {:ok, pid} = DatabaseWorker.start_link("database/test")
    DatabaseWorker.store(pid, "my key", %{this_is: "anything"})

    assert DatabaseWorker.get(pid, "my key") == %{this_is: "anything"}
  end
end
