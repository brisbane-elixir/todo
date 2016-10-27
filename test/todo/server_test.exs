defmodule Todo.ServerTest do
  use ExUnit.Case
  alias Todo.{Server, Database, Supervisor}

  setup do
    {:ok, supervisor} = Supervisor.start_link()
    {:ok, todo_server} = Server.start("myserver")
    :ok = Server.clear(todo_server)

    on_exit fn ->
      Process.exit(supervisor, :kill)
    end

    %{todo_server: todo_server}
  end

  test "should add entries to a todo server", %{todo_server: todo_server} do
    Server.add_entry(todo_server,
      %{date: {2013, 12, 19}, title: "Dentist"})
    Server.add_entry(todo_server,
      %{date: {2013, 12, 20}, title: "Shopping"})
    Server.add_entry(todo_server,
      %{date: {2013, 12, 19}, title: "Movies"})

    assert Server.entries(todo_server, {2013, 12, 19}) ==
      [%{date: {2013, 12, 19}, id: 1, title: "Dentist"},
        %{date: {2013, 12, 19}, id: 3, title: "Movies"}]
  end

  test "should persist entries", %{todo_server: todo_server} do
    Server.add_entry(todo_server,
      %{date: {2016, 9, 22}, title: "Elixir Meetup"})

    :timer.sleep(500)
    Process.exit(todo_server, :kill)

    {:ok, todo_server2} = Server.start("myserver")

    assert todo_server != todo_server2
    assert Server.entries(todo_server2, {2016,9,22}) ==
      [%{id: 1, date: {2016, 9, 22}, title: "Elixir Meetup"}]
  end
end
