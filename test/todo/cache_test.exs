defmodule Todo.CacheTest do
  use ExUnit.Case
  alias Todo.Cache

  test "can retrieve a server process from the cache" do
    {:ok, cache} = Cache.start
    pid = Cache.server_process(cache, "Bob's List")
    retrieved = Cache.server_process(cache, "Bob's List")

    assert pid == retrieved
  end
end
