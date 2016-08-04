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
    |> Map.values
    |> Enum.filter(fn entry ->
      entry.date == date
    end)
  end
```
We'll also need to update our tests, as we are adding an ID field to entries. We'll change our `assert` to only check
the fields we care about still.
```
  test "should add todos to a todo list" do
    todo_list = todolist.new
    |> todolist.add_entry(%{date: {2013, 12, 19}, title: "dentist"})
    |> todolist.add_entry(%{date: {2013, 12, 20}, title: "shopping"})
    |> todolist.add_entry(%{date: {2013, 12, 19}, title: "movies"})


    assert todolist.entries(todo_list, {2013, 12, 19}) == [
      %{date: {2013, 12, 19}, title: "dentist", id: 1},
      %{date: {2013, 12, 19}, title: "movies", id: 3}
    ]
    assert todolist.entries(todo_list, {2013, 12, 18}) == []
  end
```
Run our tests to prove things still work:
```
mix test
```
### Updating Entries
Now that we can uniquely identify entries, we can implement update. Let's write a test:
```
  test "should update an existing todo" do
    todo_list = TodoList.new
    |> TodoList.add_entry(%{date: {2016, 07, 19}, title: "Meetup"})

    updated_list = todo_list |> TodoList.update_entry(1, &Map.put(&1, :title, "Elixir Meetup"))

    assert updated_list |> TodoList.entries({2016, 07, 19}) == [
     %{date: {2016, 07, 19}, id: 1, title: "Elixir Meetup"}
    ]
  end
```
We also want to check that we handle a case where we try update an entry that doesn't exist. We've decided that for now
we just want to return the list unchanged rather than raise an exception.
```
  test "should return unchanged list when updating a non-existing entry" do
    todo_list = TodoList.new
    |> TodoList.add_entry(%{date: {2016, 07, 19}, title: "Meetup"})

    updated_list = todo_list |> TodoList.update_entry(2, &Map.put(&1, :title, "Elixir Meetup"))

    assert updated_list == todo_list
  end
```
To make our tests pass, here's the `update_entry` implementation:
```
  def update_entry(
        %TodoList{entries: entries} = todo_list,
        entry_id,
        updater_fun
      ) do
    case entries[entry_id] do
      nil -> todo_list
      old_entry ->
        new_entry = updater_fun.(old_entry)
        new_entries = Map.put(entries, new_entry.id, new_entry)
        %TodoList{todo_list | entries: new_entries}
    end
  end
```
### Deleting an entry
Our TodoList module is almost complete. All we're missing is a delete function.
Here is a test for it:
```
  test "should delete an entry" do
    todo_list = TodoList.new
    |> TodoList.add_entry(%{date: {2016, 07, 19}, title: "Meetup"})

    assert todo_list |> TodoList.entries({2016, 07, 19}) |> Enum.count == 1

    todo_list = todo_list |> TodoList.delete_entry(1)

    assert todo_list |> TodoList.entries({2016, 07, 19}) |> Enum.count == 0
  end
```
And an implementation:
```
  def delete_entry(
        %TodoList{entries: entries} = todo_list,
        entry_id
      ) do
    new_entries = Map.delete(entries, entry_id)
    %TodoList{todo_list | entries: new_entries}
  end
```
## Server Processes
### Todo generic server process
Our TodoList so far is a pure functional abstraction. To keep the structure alive,
we constantly must hold on to the result of the last operation performed on the
structure.
In this example, you’ll build a TodoServer module that keeps this abstraction in
the private state. Let’s see how the server is used:
```
iex(1)> todo_server = TodoServer.start
iex(2)> TodoServer.add_entry(todo_server,
%{date: {2013, 12, 19}, title: "Dentist"})
iex(3)> TodoServer.add_entry(todo_server,
%{date: {2013, 12, 20}, title: "Shopping"})
iex(4)> TodoServer.add_entry(todo_server,
%{date: {2013, 12, 19}, title: "Movies"})
iex(5)> TodoServer.entries(todo_server, {2013, 12, 19})
[%{date: {2013, 12, 19}, id: 3, title: "Movies"},
%{date: {2013, 12, 19}, id: 1, title: "Dentist"}]
```
You start the server and then use its pid to manipulate the data. In contrast to the pure
functional approach, you don’t need to take the result of a modification and feed it as
an argument to the next operation. Instead, you constantly use the same todo_server
variable to manipulate the to-do list.

Let's start a new file in our project, `lib/todo_server.ex`, and a test `test/todo_server_test.ex`.
We'll implement a server process ourselves, to get an understanding of how this works. Later, we'll reimplement
it using GenServer, which will handle some of these details for us and much more. Understanding what happens
underneath is really important though.

First, I'll transcribe the above sample into a test:
```
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
```
And we'll set up the basic structure of a server process:
```
defmodule TodoServer do
  def start do
    spawn(fn -> loop(TodoList.new) end)
  end

  defp loop(todo_list) do
    new_todo_list = receive do
      message ->
        process_message(todo_list, message)
    end
    loop(new_todo_list)
  end
end
```
And add functions for `process_message` and `add_entry`:
```
  def add_entry(todo_server, new_entry) do
    send(todo_server, {:add_entry, new_entry})
  end

  defp process_message(todo_list, {:add_entry, new_entry}) do
    TodoList.add_entry(todo_list, new_entry)
  end
```
The interface function sends the new entry data to the server. Recall that the loop
function calls `process_message/2` , and the call ends up in the `process_message/2`
clause. Here, you delegate to the TodoList function and return the modified Todo-
List instance. This returned instance is used as the new server’s state.

Similarly, we can implement the entries function.
```
  def entries(todo_server, date) do
    send(todo_server, {:entries, self, date})
    receive do
      {:todo_entries, entries} -> entries
    after 5000 ->
        {:error, :timeout}
    end
  end

  defp process_message(todo_list, {:entries, caller, date}) do
    send(caller, {:todo_entries, TodoList.entries(todo_list, date)})
    todo_list
  end
```
Notice how we have to wait for the response here to make this a synchronous call.
