defmodule TodoBench do
  use Benchfella
  alias Todo.{Cache, Server}

  bench "update a bunch of todo lists" do
    {:ok, cache} = Cache.start
    for i <- (0..1000) do
      list = Cache.server_process(cache, "list #{i}")
      Server.clear(list)
      entry = %{date: {2016, 10, 1}, title: "dentist"}
      Server.add_entry(list, entry)
      Server.entries(list, {2016, 10, 1})
    end
  end
end
