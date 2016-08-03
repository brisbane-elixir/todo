defmodule TodoListTest do
  use ExUnit.Case

  test "should add todos to a todo list" do
    todo_list =
      TodoList.new |>
      TodoList.add_entry(%{date: {2013, 12, 19}, title: "Dentist"}) |>
      TodoList.add_entry(%{date: {2013, 12, 20}, title: "Shopping"}) |>
      TodoList.add_entry(%{date: {2013, 12, 19}, title: "Movies"})

    entries = TodoList.entries(todo_list, {2013, 12, 19})
    assert entries |> Enum.at(0) |> Map.take([:date, :title]) == %{date: {2013, 12, 19}, title: "Dentist"}
    assert entries |> Enum.at(1) |> Map.take([:date, :title]) == %{date: {2013, 12, 19}, title: "Movies"}
    assert TodoList.entries(todo_list, {2013, 12, 18}) == []
  end
end
