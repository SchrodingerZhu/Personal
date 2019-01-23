defmodule Personal.CacheAgent.Url do
  @moduledoc """
  Agent process to Cache basic pages.
  """
  def start_link(flag) do
    urls =
      Personal.Database.all(Personal.Page)
      |> Enum.map(fn x -> {x.url, x.id} end)
      |> Map.new
    if !flag do
      Agent.start_link(fn -> urls end, [name: __MODULE__])
    end
    receive do
      after
        3600000 ->
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
  def start_link(started, timer) do
    if !started do
      Agent.start_link(fn -> Map.new() end, [name: __MODULE__])
    end
    now = Time.utc_now()
    if Time.diff(now, timer, :second) > 1800 do
      Agent.update(__MODULE__,  fn x -> x
          |> Enum.filter(fn {_, t} -> Time.diff(now, t) < 1800 end)
          |> Map.new()
      end)
    end
    receive do
    after
      1800000 ->
        start_link(true, Time.utc_now)
    end
  end

  def put_new(id, page) do
    Agent.update(__MODULE__, fn x -> Map.put(x, id, {page, Time.utc_now}) end)
  end

  def drop(id) do
    Agent.update(__MODULE__, fn x -> Map.delete(x, id) end)
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
    spawn_link(Personal.CacheAgent.Url, :start_link, [false])
    spawn_link(Personal.CacheAgent.Page, :start_link, [false, Time.utc_now])
    {:ok, args}
  end
end
