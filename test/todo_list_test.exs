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

    updated_list = todo_list |> TodoList.update_entry(1, &Map.put(&1, :title, "Elixir Meetup"))

    assert updated_list |> TodoList.entries({2016, 07, 19}) == [
     %{date: {2016, 07, 19}, id: 1, title: "Elixir Meetup"}
    ]
  end

  test "should return unchanged list on update non-existing entry" do
    todo_list = TodoList.new
    |> TodoList.add_entry(%{date: {2016, 07, 19}, title: "Meetup"})

    updated_list = todo_list |> TodoList.update_entry(2, &Map.put(&1, :title, "Elixir Meetup"))

    assert updated_list == todo_list
  end

  test "should delete an entry" do
    todo_list = TodoList.new
    |> TodoList.add_entry(%{date: {2016, 07, 19}, title: "Meetup"})

    assert todo_list |> TodoList.entries({2016, 07, 19}) |> Enum.count == 1

    todo_list = todo_list |> TodoList.delete_entry(1)

    assert todo_list |> TodoList.entries({2016, 07, 19}) |> Enum.count == 0
  end
end
