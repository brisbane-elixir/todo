defmodule DatabaseTest do
  use ExUnit.Case

  test "can store and retrieve values" do
    TodoDatabase.start("database/test")
    TodoDatabase.store("my key", %{this_is: "anything"})

    assert TodoDatabase.get("my key") == %{this_is: "anything"}
  end
end
