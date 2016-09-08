defmodule Todo.List do
  defstruct auto_id: 1, entries: %{}
  alias Todo.List

  def new, do: %List{}

  def add_entry(
        %List{entries: entries, auto_id: auto_id} = todo_list,
        entry
      ) do
    entry = Map.put(entry, :id, auto_id)
    new_entries = Map.put(entries, auto_id, entry)
    %List{todo_list |
              entries: new_entries,
              auto_id: auto_id + 1
    }
  end

  def entries(%List{entries: entries}, date) do
    entries
    |> Map.values
    |> Enum.filter(fn entry ->
      entry.date == date
    end)
  end

  def update_entry(
        %List{entries: entries} = todo_list,
        entry_id,
        updater_fun
      ) do
    case entries[entry_id] do
      nil -> todo_list
      old_entry ->
        new_entry = updater_fun.(old_entry)
        new_entries = Map.put(entries, new_entry.id, new_entry)
        %List{todo_list | entries: new_entries}
    end
  end

  def delete_entry(
        %List{entries: entries} = todo_list,
        entry_id
      ) do
    new_entries = Map.delete(entries, entry_id)
    %List{todo_list | entries: new_entries}
  end
end
