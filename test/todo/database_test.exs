defmodule Todo.DatabaseTest do
  use ExUnit.Case
  alias Todo.Database

  setup do
    Todo.ProcessRegistry.start_link
    :ok
  end

  test "can store and retrieve values" do
    Database.start_link("database/test")
    Database.store("my key", %{this_is: "anything"})

    assert Database.get("my key") == %{this_is: "anything"}
  end
end
