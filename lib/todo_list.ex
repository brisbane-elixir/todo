defmodule TodoList do
  defstruct auto_id: 1, entries: %{}

  def new, do: %TodoList{}

  def add_entry(todo_list, entry) do
    Map.update(
      todo_list,
      entry.date,
      [entry],
      fn(entries) -> [entry | entries] end
    )
  end

  def entries(todo_list, date) do
    Map.get(todo_list, date, [])
  end
end
