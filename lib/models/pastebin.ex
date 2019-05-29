defmodule Personal.Pastebin do
  use Memento.Table,
    attributes: [:id, :name, :expire_time, :can_edit, :content, :security_level, :password, :language],
    index: [:name],
    type: :ordered_set,
    autoincrement: true
  def new(name, content, expire_time \\ :never, security_level \\ 0, can_edit \\ false, password \\ nil, language \\ "plaintext") do
    %Personal.Pastebin{
      name: name, 
      expire_time: expire_time, 
      can_edit: can_edit, 
      content: content,
      security_level: security_level,
      password: if password != nil do 
        ExSha3.sha3_512(password)
      else
        nil
      end,
      language: language

    }
  end
  def has_name?(name) do
    case Personal.Database.find(Personal.Pastebin, {:==, :name, name}) do
      [] -> false
      _ -> true
    end
  end
  def add(pastebin) do
    if has_name?(pastebin.name) do
      IO.puts(:stderr, "failed to add pastebin, already exists")
      :error
    else
      case Personal.Database.insert(pastebin) do
        {:ok, res} ->
          Personal.CacheAgent.Pastebin.put_newurl(res.name, res.id, res.security_level)
          if res.expire_time != :never do
            Personal.CacheAgent.Pastebin.put_timer(res)
          end
          :ok

        info ->
          IO.puts(:stderr, "failed to add pastebin")
          {:error, info}
      end
    end
  end

  def update(pastebin) do
    if has_name?(pastebin.name) do
      if pastebin.expire_time != nil do
        Personal.CacheAgent.Pastebin.drop_timer(pastebin)
      end
      Personal.CacheAgent.Pastebin.drop_cache(pastebin.id)
      Personal.CacheAgent.Pastebin.drop_url(pastebin.name)
      case Personal.Database.insert(pastebin) do
        {:ok, res} ->
          Personal.CacheAgent.Pastebin.put_newurl(res.name, res.id, res.is_open)
          if res.expire_time != nil do
            Personal.CacheAgent.Pastebin.put_timer(res)
          end
          :ok

        info ->
          IO.puts(:stderr, "failed to add pastebin")
          {:error, info}
      end
    else
      IO.puts(:stderr, "failed to update pastebin, not exists")
      :error
    end
  end
end
