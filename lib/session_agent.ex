defmodule Personal.Session do
  defstruct id: nil, nonce: nil, pub_key: nil, last_active: nil, username: nil, is_login: false

  def new(id, nonce, pub_key, username) do
    %Personal.Session{
      id: id,
      nonce: nonce,
      last_active: Time.utc_now(),
      pub_key: pub_key,
      username: username
    }
  end

  def update_time(session) do
    %Personal.Session{session | last_active: Time.utc_now()}
  end

  def update_nonce(session, nonce) do
    %Personal.Session{session | nonce: nonce}
  end

  def update_login(session, state \\ true) do
    %Personal.Session{session | is_login: state}
  end
end

defmodule Personal.SessionAgent do
  use GenServer

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: :session_agent)
  end

  def init(args) do
    pid =
      spawn_link(Personal.SessionAgent, :life_cycle, [Map.new(), Personal.Utils.RbTree.new(), 0])

    Agent.start_link(fn -> pid end, name: __MODULE__)
    {:ok, args}
  end

  def life_cycle(sessions, tree, mark) do
    import Personal.Utils.RbTree

    if !is_empty?(tree) do
      {the_mark, time, id} = min(tree)

      if Time.diff(time, Time.utc_now(), :second) >= 1800 do
        life_cycle(Map.delete(sessions, id), delete(tree, {the_mark, time, id}), mark)
      end
    end

    receive do
      {:check, uuid, client} ->
        send(client, Map.has_key?(sessions, uuid))
        life_cycle(sessions, tree, mark)

      {:check_login, uuid, client} ->
        {session, _} = sessions[uuid]
        send(client, session.is_login)
        life_cycle(sessions, tree, mark)

      {:put_new, session} ->
        stamp = {mark, Time.utc_now(), session.id}

        life_cycle(
          Map.put(sessions, session.id, {session, stamp}),
          insert(tree, stamp),
          mark + 1
        )

      {:drop, uuid} ->
        {_, stamp} = sessions[uuid]
        life_cycle(Map.delete(sessions, uuid), delete(tree, stamp), mark)

      {:update, uuid, session} ->
        stamp = {mark, Time.utc_now(), session.id}
        {_, old_stamp} = sessions[uuid]
        new_sessions = sessions |> Map.update!(uuid, fn _ -> {session, stamp} end)
        new_tree = delete(tree, old_stamp)
        life_cycle(new_sessions, new_tree, mark + 1)

      {:get, uuid, client} ->
        if Map.has_key?(sessions, uuid) do
          {session, _} = sessions[uuid]
          send(client, session)
        else
          send(client, nil)
        end

        life_cycle(sessions, tree, mark)
    after
      900_000 ->
        if is_empty?(tree) do
          life_cycle(sessions, tree, 0)
        else
          life_cycle(sessions, tree, mark)
        end
    end
  end

  def put_new(session) do
    pid = Agent.get(__MODULE__, fn x -> x end)
    send(pid, {:put_new, session})
  end

  def check(uuid) do
    pid = Agent.get(__MODULE__, fn x -> x end)
    send(pid, {:check, uuid, Kernel.self()})

    receive do
      ans -> ans
    end
  end

  def check_login(uuid) do
    pid = Agent.get(__MODULE__, fn x -> x end)
    send(pid, {:check_login, uuid, Kernel.self()})

    receive do
      ans -> ans
    end
  end

  def drop(uuid) do
    pid = Agent.get(__MODULE__, fn x -> x end)
    send(pid, {:drop, uuid})
  end

  def update(uuid, session) do
    pid = Agent.get(__MODULE__, fn x -> x end)
    send(pid, {:update, uuid, session})
  end

  def get(uuid) do
    pid = Agent.get(__MODULE__, fn x -> x end)
    send(pid, {:get, uuid, Kernel.self()})

    receive do
      ans -> ans
    end
  end
end
