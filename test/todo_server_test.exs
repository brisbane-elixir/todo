defmodule TodoServerTest do
  use ExUnit.Case

  test "should add entries to a todo server" do
    todo_server = TodoServer.start
    TodoServer.add_entry(todo_server,
      %{date: {2013, 12, 19}, title: "Dentist"})
    TodoServer.add_entry(todo_server,
      %{date: {2013, 12, 20}, title: "Shopping"})
    TodoServer.add_entry(todo_server,
      %{date: {2013, 12, 19}, title: "Movies"})

    assert TodoServer.entries(todo_server, {2013, 12, 19}) ==
      [%{date: {2013, 12, 19}, id: 3, title: "Movies"},
       %{date: {2013, 12, 19}, id: 1, title: "Dentist"}]
  end
end
