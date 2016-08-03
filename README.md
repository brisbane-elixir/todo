# Elixir in Action Part 1

## Elixir News
 - Announcing GenStage http://elixir-lang.org/blog/2016/07/14/announcing-genstage/

## Recap - Concurrency
https://gist.github.com/colinbankier/a3f2eb7642b94c0d610a

## Elixir in Action
Elixir in Action, by Sasa Juric
https://www.manning.com/books/elixir-in-action

We'll work through the hands-on excerises from this book, would build a ToDo server application.
The concept of the application is simple enough. The basic version of the to-do list will support the following features:
 - Creating a new data abstraction
 - Adding new entries
 - Querying the abstraction
We'll continue adding features and by the end we’ll have a fully working distributed web server that can manage a large number of to-do
lists.

### Overview
 - Todo list data abstraction
 - Server Processes
    - Todo generic server process
    - GenServer powered Todo server
 - Building a concurrent system
    - Managing multiple Todo lists
    - Persisting data
    - Analysing and addressing bottlenecks
 - Fault tolerance
    - Errors in concurrent systems
    - Supervisors and Supervision trees
    - Isolating error effects
 - Sharing state
    - Single process bottlenecks
    - ETS Tables
 - Production
    - Working with components
    - Building and running the distributed system

## Abstracting with Modules
First, we'll create a basic data structure for our todo lists, and a module for functions to manipulate it.
Here is an example usage:
```
iex(1)> todo_list =
TodoList.new |>
TodoList.add_entry({2013, 12, 19}, "Dentist") |>
TodoList.add_entry({2013, 12, 20}, "Shopping") |>
TodoList.add_entry({2013, 12, 19}, "Movies")

iex(2)> TodoList.entries(todo_list, {2013, 12, 19})
["Movies", "Dentist"]

iex(3)> TodoList.entries(todo_list, {2013, 12, 18})
[]
```

First, create a new project:
```
mix new todo
```
Let's do a little bit of TDD as we go, so start a new test in `test/todo_list_test.exs`
Here is a test that does what our example snippet says, but I'm going to represent an entry as a
Map with date and title attributes:
```
defmodule TodoListTest do
  use ExUnit.Case

  test "should add todos to a todo list" do
    todo_list =
      TodoList.new |>
      TodoList.add_entry(%{date: {2013, 12, 19}, title: "Dentist"}) |>
      TodoList.add_entry(%{date: {2013, 12, 20}, title: "Shopping"}) |>
      TodoList.add_entry(%{date: {2013, 12, 19}, title: "Movies"})

    assert TodoList.entries(todo_list, {2013, 12, 19}) == [
      %{date: {2013, 12, 19}, title: "Movies"},
      %{date: {2013, 12, 19}, title: "Dentist"}
    ]
    assert TodoList.entries(todo_list, {2013, 12, 18}) == []
  end
end
```
Then create TodoList module in `lib/todo_list.ex`
Looking at our test, we can see a todo list is some of mapping from dates to entries, so we'll use a Map
as our internal represention.
```
defmodule TodoList do
  def new, do: %{}
end
```
Next, we'll implement the `add_entry/3` function. It needs to add the entry to the entry list for the specified date, and
also handle the case where no entries exist yet for that date. Turns out we can do with one call to `Map.update/4`.
```
def add_entry(todo_list, date, title) do
  Map.update(
    todo_list,
    date,
    [title],
    fn(titles) -> [title | titles] end
  )
end
```
Then, we'll add the `entries` function:
```
def entries(todo_list, date) do
  Map.get(todo_list, date, [])
end
```

## Working with heirachical data
In this section we'll basic crud support to our Todo list. In order to support updating or deleting entries,
we'll need to be able to uniquely identify each one. To do that, we'll begin by adding unique IDs to each entry.

First, we'll expand our internal structure for a TodoList to hold a sequence counter for our IDs. We'll expand our representation
to be a struct.
```
defmodule TodoList do
  defstruct auto_id: 1, entries: %{}

  def new, do: %TodoList{}
...
```
Next, we'll reimplement our `add_entry` function to use this, and add a unique id to each entry:
```
  def add_entry(
        %TodoList{entries: entries, auto_id: auto_id} = todo_list,
        entry
      ) do
    entry = Map.put(entry, :id, auto_id)
    new_entries = Map.put(entries, auto_id, entry)
    %TodoList{todo_list |
              entries: new_entries,
              auto_id: auto_id + 1
    }
  end
```
We previously kept a date -> entry mapping, yet now we keep an ID -> entry mapping, so our `entries`
function will need to change:
```
  def entries(%TodoList{entries: entries}, date) do
    entries
    |> Stream.filter(fn({_, entry}) ->
      entry.date == date
    end)
    |> Enum.map(fn({_, entry}) ->
      entry
    end)
  end
```
We'll also need to update our tests, as we are adding an ID field to entries. We'll change our `assert` to only check
the fields we care about still.
```
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
```
Run our tests to prove things still work:
```
mix test
```
