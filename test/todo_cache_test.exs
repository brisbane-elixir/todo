defmodule TodoCacheTest do
  use ExUnit.Case

  test "can retrieve a server process from the cache" do
    {:ok, cache} = TodoCache.start
    pid = TodoCache.server_process(cache, "Bob's List")
    retrieved = TodoCache.server_process(cache, "Bob's List")

    assert pid == retrieved
  end
end
