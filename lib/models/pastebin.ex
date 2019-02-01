defmodule Personal.Pastebin do
  use Memento.Table,
    attributes: [:id, :name, :expire_time, :is_open, :can_edit],
    index: [:name],
    type: :ordered_set,
    autoincrement: true
  def new(name, expire_time, is_open, can_edit) do
    %Personal.Pastebin{name: name, expire_time: expire_time, is_open: is_open, can_edit: can_edit}
  end
  def has_name?(name) do
    case Personal.Database.find(Personal.Pastebin, {:==, :name, name}) do
      [] -> false
      _ -> true
    end
  end
  def add(pastebin) do
    if has_name?(pastebin.name) do
      IO.puts(:stderr, "failed to add user, already exists")
      :error
    else
      case Personal.Database.insert(pastebin) do
        {:ok, _} ->
          :ok

        info ->
          IO.puts(:stderr, "failed to add pastebin")
          {:error, info}
      end
    end
  end
end
