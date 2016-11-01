alias Todo.{Cache, Supervisor}

Supervisor.start_link

number_of_lists = 100
func = fn -> Cache.server_process("list #{:rand.uniform(number_of_lists)}") end

Profiler.run(func, 100000, 100)

