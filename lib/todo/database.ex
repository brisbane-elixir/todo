defmodule Todo.Database do
  use GenServer
  alias Todo.DatabaseWorker

  @num_workers 10

  def start_link(db_folder) do
    IO.puts "Starting database server."
    GenServer.start_link(__MODULE__, db_folder,
      name: :database_server
    )
  end

  def store(key, data) do
    DatabaseWorker.store(get_worker(key), key, data)
  end

  def get(key) do
    DatabaseWorker.get(get_worker(key), key)
  end

  def get_worker(key) do
    GenServer.call(:database_server, {:get_worker, key})
  end

  def init(db_folder) do
    File.mkdir_p(db_folder)
    worker_pids = Enum.reduce(0..@num_workers, %{}, fn index, map ->
      {:ok, pid} = DatabaseWorker.start_link(db_folder)
      Map.put(map, index, pid)
    end)

    {:ok, worker_pids}
  end

  def handle_call({:get_worker, key}, _, worker_pids) do
    index = :erlang.phash2(key, @num_workers)
    pid = Map.get(worker_pids, index)
    {:reply, pid, worker_pids}
  end

end
