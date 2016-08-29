defmodule TodoCacheTest do
  use ExUnit.Case

  test "can retrieve a server process from the cache" do
    {:ok, cache} = TodoCache.start
    pid = TodoCache.server_process(cache, "Bob's List")
    retrieved = TodoCache.server_process(cache, "Bob's List")

    assert pid == retrieved
  end

  test "can start multiple server processes" do
    {:ok, cache} = TodoCache.start
    pid_1 = TodoCache.server_process(cache, "Bob's List")
    pid_2 = TodoCache.server_process(cache, "Alice's List")

    assert pid_1 != pid_2
  end

  test "returned pid is a todo list" do
    {:ok, cache} = todocache.start
    bobs_list = todocache.server_process(cache, "bob's list")
    entry = %{date: {2016, 10, 01}, title: "dentist"}
    todoserver.add_entry(bobs_list, entry)

    assert todoserver.entries(bobs_list, {2016, 10, 01}) == [map.put(entry, :id, 1)]
  end
end