defmodule TodoListTest do
  use ExUnit.Case

  test "should add todos to a todo list" do
    todo_list = TodoList.new
    |> TodoList.add_entry(%{date: {2013, 12, 19}, title: "Dentist"})
    |> TodoList.add_entry(%{date: {2013, 12, 20}, title: "Shopping"})
    |> TodoList.add_entry(%{date: {2013, 12, 19}, title: "Movies"})


    assert TodoList.entries(todo_list, {2013, 12, 19}) == [
      %{date: {2013, 12, 19}, title: "Dentist", id: 1},
      %{date: {2013, 12, 19}, title: "Movies", id: 3}
    ]
    assert TodoList.entries(todo_list, {2013, 12, 18}) == []
  end

  test "should update an existing todo" do
    todo_list = TodoList.new
    |> TodoList.add_entry(%{date: {2016, 07, 19}, title: "Meetup"})

    todo_list = todo_list |> TodoList.update_entry(1, &Map.put(&1, :title, "Elixir Meetup"))

    assert todo_list |> TodoList.entries({2016, 07, 19}) == [
     %{date: {2016, 07, 19}, id: 1, title: "Elixir Meetup"}
    ]
  end

end
