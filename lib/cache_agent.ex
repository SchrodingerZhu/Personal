defmodule Personal.CacheAgent.Url do
  @moduledoc """
  Agent process to Cache basic pages.
  """
  def start_link(flag) do
    urls =
      Personal.Database.all(Personal.Page)
      |> Enum.map(fn x -> {x.url, x.id} end)
      |> Map.new()

    if !flag do
      Agent.start_link(fn -> urls end, name: __MODULE__)
    end

    receive do
    after
      3_600_000 ->
        start_link(true)
    end
  end

  def put_new(url, id) do
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
    if !started do
      Agent.start_link(fn -> Map.new() end, name: __MODULE__)
    end

    now = Time.utc_now()
    case Personal.Utils.RbTree.min(tree) do
      nil -> nil
      {mark_, time, id} ->
        if Time.diff(now, time, :second) > 1800 do
          Agent.update(__MODULE__, fn x -> Map.delete(x, id) end)
          start_link(true, Personal.Utils.RbTree.delete(tree, {mark_, time, id}), mark)
        end
    end
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
        {_, old_stamp} = Agent.get_and_update(__MODULE__, fn x -> {x[id], Map.update!(x, id, fn {page, _} -> {page, new_stamp} end)} end)
        new_tree = tree |> Personal.Utils.RbTree.delete(old_stamp) |> Personal.Utils.RbTree.insert(new_stamp)
        start_link(true, new_tree, mark + 1)
    after
      900_000 ->
        start_link(true, tree, mark + 1)
    end
  end

  def put_new(id, page) do
    {_, pid} = Agent.get(:agents, fn x -> x end)
    send(pid, {:put_new, id, page})
  end

  def drop(id) do
    {_, pid} = Agent.get(:agents, fn x -> x end)
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
        {_, pid} = Agent.get(:agents, fn x -> x end)
        send(pid, {:update, id})
        page
    end
  end
end

defmodule Personal.CacheAgent do
  use GenServer
  @spec start_link(any()) :: :ignore | {:error, any()} | {:ok, pid()}
  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: :cache_agent)
  end

  def init(args) do
    x = spawn_link(Personal.CacheAgent.Url, :start_link, [false])
    y = spawn_link(Personal.CacheAgent.Page, :start_link, [false, Personal.Utils.RbTree.new, 0])
    Agent.start_link(fn -> {x, y} end, name: :agents)
    {:ok, args}
  end
end
