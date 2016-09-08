defmodule Todo.CacheTest do
  use ExUnit.Case
  alias Todo.{Cache, Server}

  test "can retrieve a server process from the cache" do
    {:ok, cache} = Cache.start
    pid = Cache.server_process(cache, "Bob's List")
    retrieved = Cache.server_process(cache, "Bob's List")

    assert pid == retrieved
  end

  test "can start multiple server processes" do
    {:ok, cache} = Cache.start
    pid_1 = Cache.server_process(cache, "Bob's List")
    pid_2 = Cache.server_process(cache, "Alice's List")

    assert pid_1 != pid_2
  end

  test "returned pid is a todo list" do
    {:ok, cache} = Cache.start
    bobs_list = Cache.server_process(cache, "bob's list")
    Server.clear(bobs_list)
    entry = %{date: {2016, 10, 01}, title: "dentist"}
    Server.add_entry(bobs_list, entry)

    assert Server.entries(bobs_list, {2016, 10, 01}) == [Map.put(entry, :id, 1)]
  end
end
