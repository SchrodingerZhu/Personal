defmodule Personal.CacheAgent.Url do
  @moduledoc """
  Agent process to Cache basic pages.
  """
  def start_link(flag) do
    if !flag do
      urls =
        Personal.Database.all(Personal.Page)
        |> Enum.map(fn x -> {x.url, x.id} end)
        |> Map.new()

      # debug info
      IO.puts("current page urls: " <> Kernel.inspect(urls))
      Agent.start_link(fn -> urls end, name: __MODULE__)
    end

    receive do
    after
      3_600_000 ->
        start_link(true)
    end
  end

  def put_new(url, id) do
    IO.puts("new url put")
    Agent.update(__MODULE__, fn x -> Map.put(x, url, id) end)
  end

  def drop(url) do
    Agent.update(__MODULE__, fn x -> Map.delete(x, url) end)
  end

  def has?(url) do
    Agent.get(__MODULE__, fn x -> Map.has_key?(x, url) end)
  end

  def get(url) do
    Agent.get(__MODULE__, fn x -> x[url] end)
  end
end

defmodule Personal.CacheAgent.Page do
  @moduledoc """
  Agent process to Cache basic pages.
  """
  @type stamp :: {Time.t(), integer}
  def make_stamp(id, mark) do
    {mark, Time.utc_now(), id}
  end

  def start_link(started, tree, mark) do
    min = Personal.Utils.RbTree.min(tree)

    {_, time, id} =
      case min do
        nil -> {nil, nil, nil}
        {a, b, c} -> {a, b, c}
      end

    now = Time.utc_now()

    cond do
      !started ->
        Agent.start_link(fn -> Map.new() end, name: __MODULE__)
        start_link(true, tree, mark)

      !Personal.Utils.RbTree.is_empty?(tree) and Time.diff(now, time, :second) > 1800 ->
        Agent.update(__MODULE__, fn x -> Map.delete(x, id) end)
        start_link(true, Personal.Utils.RbTree.delete(tree, min), mark)

      true ->
        receive do
          {:put_new, id, page} ->
            stamp = make_stamp(id, mark)
            Agent.update(__MODULE__, fn x -> Map.put(x, id, {page, stamp}) end)
            start_link(true, Personal.Utils.RbTree.insert(tree, stamp), mark + 1)

          {:drop, id} ->
            {_, stamp} = Agent.get_and_update(__MODULE__, fn x -> {x[id], Map.delete(x, id)} end)
            start_link(true, Personal.Utils.RbTree.delete(tree, stamp), mark)

          {:update, id} ->
            new_stamp = make_stamp(id, mark)

            {_, old_stamp} =
              Agent.get_and_update(__MODULE__, fn x ->
                {x[id], Map.update!(x, id, fn {page, _} -> {page, new_stamp} end)}
              end)

            new_tree =
              tree
              |> Personal.Utils.RbTree.delete(old_stamp)
              |> Personal.Utils.RbTree.insert(new_stamp)

            start_link(true, new_tree, mark + 1)
        after
          900_000 ->
            if Personal.Utils.RbTree.is_empty?(tree) do
              start_link(true, tree, 0)
            else
              start_link(true, tree, mark + 1)
            end
        end
    end
  end

  def put_new(id, page) do
    pid = Agent.get(:agents, fn x -> x[:page_cache] end)
    send(pid, {:put_new, id, page})
  end

  def drop(id) do
    pid = Agent.get(:agents, fn x -> x[:page_cache] end)
    send(pid, {:drop, id})
  end

  def get(id) do
    case Agent.get(__MODULE__, fn x -> x[id] end) do
      nil ->
        page = Personal.Database.get(Personal.Page, id)

        if page.is_markdown do
          marked_content =
            page.content
            |> Cmark.to_html()

          new_page =
            page
            |> Map.update!(:content, fn _ -> marked_content end)
            |> Map.update!(:is_markdown, fn _ -> false end)

          put_new(id, new_page)
          new_page
        else
          put_new(id, page)
          page
        end

      {page, _} ->
        pid = Agent.get(:agents, fn x -> x[:page_cache] end)
        send(pid, {:update, id})
        page
    end
  end
end

defmodule Personal.CacheAgent.Pastebin do
  def urls_start_link(flag) do
    if !flag do
      pastes =
        Personal.Database.all(Personal.Pastebin)
        |> Enum.map(fn x -> {x.name, x.id} end)
        |> Map.new()

      Agent.start_link(fn -> pastes end, name: :pastebin_urls)
    end

    receive do
    after
      3_600_000 ->
        urls_start_link(true)
    end
  end

  def put_newurl(url, id) do
    Agent.update(:pastebin_urls, fn x -> Map.put(x, url, id) end)
  end

  def drop_url(url) do
    Agent.update(:pastebin_urls, fn x -> Map.delete(x, url) end)
  end

  def has_url?(url) do
    Agent.get(:pastebin_urls, fn x -> Map.has_key?(x, url) end)
  end

  def get_url(url) do
    Agent.get(:pastebin_urls, fn x -> x[url] end)
  end

  def make_stamp(id, mark) do
    {mark, Time.utc_now(), id}
  end

  def cache_start_link(started, tree, mark) do
    min = Personal.Utils.RbTree.min(tree)

    {_, time, id} =
      case min do
        nil -> {nil, nil, nil}
        {a, b, c} -> {a, b, c}
      end

    now = Time.utc_now()

    cond do
      !started ->
        Agent.start_link(fn -> Map.new() end, name: :pastebin_cache)
        cache_start_link(true, tree, mark)

      !Personal.Utils.RbTree.is_empty?(tree) and Time.diff(now, time, :second) > 1800 ->
        Agent.update(:pastebin_cache, fn x -> Map.delete(x, id) end)
        cache_start_link(true, Personal.Utils.RbTree.delete(tree, min), mark)

      true ->
        receive do
          {:put_new, id, page} ->
            stamp = make_stamp(id, mark)
            Agent.update(:pastebin_cache, fn x -> Map.put(x, id, {page, stamp}) end)
            cache_start_link(true, Personal.Utils.RbTree.insert(tree, stamp), mark + 1)

          {:drop, id} ->
            case Agent.get_and_update(:pastebin_cache, fn x -> {x[id], Map.delete(x, id)} end) do
              {_, stamp} ->
                cache_start_link(true, Personal.Utils.RbTree.delete(tree, stamp), mark)

              _ ->
                cache_start_link(true, tree, mark)
            end

          {:update, id} ->
            new_stamp = make_stamp(id, mark)

            {_, old_stamp} =
              Agent.get_and_update(:pastebin_cache, fn x ->
                {x[id], Map.update!(x, id, fn {page, _} -> {page, new_stamp} end)}
              end)

            new_tree =
              tree
              |> Personal.Utils.RbTree.delete(old_stamp)
              |> Personal.Utils.RbTree.insert(new_stamp)

            cache_start_link(true, new_tree, mark + 1)
        after
          900_000 ->
            if Personal.Utils.RbTree.is_empty?(tree) do
              cache_start_link(true, tree, 0)
            else
              cache_start_link(true, tree, mark + 1)
            end
        end
    end
  end

  def timer_start_link(started, expire_tree, base_time) do
    min = Personal.Utils.RbTree.min(expire_tree)

    {min_time_diff, min_id, min_name} =
      case min do
        nil -> {nil, nil, nil}
        {a, b, c} -> {a, b, c}
      end

    cond do
      !started ->
        tree =
          Personal.Database.find(Personal.Pastebin, {:!=, :expire_time, nil})
          |> Enum.map(fn x -> {Time.diff(x.expire_time, base_time), x.id, x.name} end)
          |> Personal.Utils.RbTree.from_list()

        timer_start_link(true, tree, base_time)

      min_time_diff != nil and Time.diff(Time.utc_now(), Time.add(base_time, min_time_diff)) >= 0 ->
        IO.puts(min_id)
        drop_cache(min_id)
        drop_url(min_name)
        Personal.Database.remove_id(Personal.Pastebin, min_id)
        timer_start_link(true, Personal.Utils.RbTree.delete(expire_tree, min), base_time)

      true ->
        receive do
          {:drop, x} ->
            timer_start_link(
              true,
              Personal.Utils.RbTree.delete(
                expire_tree,
                {Time.diff(x.expire_time, base_time), x.id, x.name}
              ),
              base_time
            )

          {:put, x} ->
            timer_start_link(
              true,
              Personal.Utils.RbTree.insert(
                expire_tree,
                {Time.diff(x.expire_time, base_time), x.id, x.name}
              ),
              base_time
            )
        after
          100_000 ->
            timer_start_link(true, expire_tree, base_time)
        end
    end
  end

  def put_newcache(id, paste) do
    pid = Agent.get(:agents, fn x -> x[:pastebin_cache] end)
    send(pid, {:put_new, id, paste})
  end

  def drop_cache(id) do
    pid = Agent.get(:agents, fn x -> x[:pastebin_cache] end)
    send(pid, {:drop, id})
  end

  def get_cache(id) do
    case Agent.get(:pastebin_cache, fn x -> x[id] end) do
      nil ->
        paste = Personal.Database.get(Personal.Pastebin, id)
        put_newcache(id, paste)
        paste

      {paste, _} ->
        pid = Agent.get(:agents, fn x -> x[:pastebin_cache] end)
        send(pid, {:update, id})
        paste
    end
  end

  def put_timer(paste) do
    pid = Agent.get(:agents, fn x -> x[:pastebin_timer] end)
    send(pid, {:put, paste})
  end

  def drop_timer(paste) do
    pid = Agent.get(:agents, fn x -> x[:pastebin_timer] end)
    send(pid, {:drop, paste})
  end
end

defmodule Personal.CacheAgent do
  use GenServer
  @spec start_link(any()) :: :ignore | {:error, any()} | {:ok, pid()}
  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: :cache_agent)
  end

  def init(args) do
    page_url = spawn_link(Personal.CacheAgent.Url, :start_link, [false])

    page_cache =
      spawn_link(Personal.CacheAgent.Page, :start_link, [false, Personal.Utils.RbTree.new(), 0])

    pastebin_cache =
      spawn_link(Personal.CacheAgent.Pastebin, :cache_start_link, [
        false,
        Personal.Utils.RbTree.new(),
        0
      ])

    pastebin_url = spawn_link(Personal.CacheAgent.Pastebin, :urls_start_link, [false])

    pastebin_timer =
      spawn_link(Personal.CacheAgent.Pastebin, :timer_start_link, [
        false,
        Personal.Utils.RbTree.new(),
        Time.utc_now()
      ])

    Agent.start_link(
      fn ->
        %{
          page_url: page_url,
          page_cache: page_cache,
          pastebin_cache: pastebin_cache,
          pastebin_url: pastebin_url,
          pastebin_timer: pastebin_timer
        }
      end,
      name: :agents
    )

    {:ok, args}
  end
end
