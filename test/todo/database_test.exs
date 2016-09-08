defmodule Todo.DatabaseTest do
  use ExUnit.Case
  alias Todo.Database

  test "can store and retrieve values" do
    Database.start("database/test")
    Database.store("my key", %{this_is: "anything"})

    assert Database.get("my key") == %{this_is: "anything"}
  end

  test "gets a database worker for a given name" do
    Database.start("database/test")
    worker1 = Database.get_worker("anything")

    assert worker1
  end
end
