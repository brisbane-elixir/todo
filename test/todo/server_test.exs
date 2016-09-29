defmodule Todo.ServerTest do
  use ExUnit.Case
  alias Todo.Server

  test "should add entries to a todo server" do
    {:ok, todo_server} = Server.start
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
end
