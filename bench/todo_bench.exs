defmodule TodoBench do
  use Benchfella
  alias Todo.{Cache, Server}

  @number_of_lists 100

  setup_all do
    Todo.Supervisor.start_link
  end

  teardown_all supervisor do
    Process.exit(supervisor, :normal)
  end

  bench "request todo lists from cache" do
    i = :rand.uniform(@number_of_lists)
    Cache.server_process("list #{i}")
    :ok
  end
end
