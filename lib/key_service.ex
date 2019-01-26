defmodule Personal.KeyService do
  def gen_uuid() do
    UUID.uuid4()
  end

  def gen_nonce() do
    UUID.uuid4() |> to_charlist() |> Enum.take(24) |> to_string() |> Base.encode64()
  end

  def get_selfpub_base64() do
    System.get_env("auth_public")
  end

  def get_selfpub() do
    System.get_env("auth_public") |> Base.decode64!()
  end

  def get_selfpri_base64() do
    System.get_env("auth_private")
  end

  def get_selfpri() do
    System.get_env("auth_private") |> Base.decode64!()
  end

  def open_box(box, uuid) do
    client_session = Personal.SessionAgent.get(uuid)

    if client_session != nil do
      IO.inspect(Kcl.unbox(box, client_session.nonce, get_selfpri(), client_session.pub_key))
      {res, _} = Kcl.unbox(box, client_session.nonce, get_selfpri(), client_session.pub_key)
      nonce = Personal.KeyService.gen_nonce()

      Personal.SessionAgent.update(
        uuid,
        Personal.Session.update_nonce(client_session, Base.decode64!(nonce))
      )

      {res, nonce}
    else
      :error
    end
  end

  def seal_box(msg, uuid) do
    client_session = Personal.SessionAgent.get(uuid)

    if client_session != nil do
      {res, _} = Kcl.box(msg, client_session.nonce, get_selfpri(), client_session.pub_key)
      nonce = Personal.KeyService.gen_nonce()

      Personal.SessionAgent.update(
        uuid,
        Personal.Session.update_nonce(client_session, Base.decode64!(nonce))
      )

      {res, nonce}
    else
      :error
    end
  end

  def raw_md5(content) do
    :crypto.hash(:md5, content) |> Base.encode16() |> String.downcase()
  end

  def compare_boxedkey(keybox, uuid) do
    {res, nonce} = open_box(Base.decode64!(keybox), uuid)
    client_session = Personal.SessionAgent.get(uuid)
    {Personal.User.check_hash(client_session.username, res), nonce}
  end
end
